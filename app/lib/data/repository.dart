import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

SupabaseClient get _db => Supabase.instance.client;

const _listingSelect = '*, listing_images(id, public_path, status, rejection_reason, sort_order), '
    'profiles!listings_seller_id_fkey(display_name)';

/// Result of the server-side photo check for one uploaded photo.
class PhotoCheckResult {
  PhotoCheckResult(this.status, this.reason);
  final String status;
  final String? reason;
  bool get approved => status == 'approved';
}

/// Every call the app makes to the backend. Access rules are enforced by the
/// database; this class just shapes the requests.
class Repository {
  Repository._();
  static final instance = Repository._();

  String? get currentUserId => _db.auth.currentUser?.id;

  String imageUrl(String publicPath) => _db.storage.from('listing-images').getPublicUrl(publicPath);

  // ---------------------------------------------------------------- auth

  Future<void> sendOtp(String phone) => _db.auth.signInWithOtp(phone: phone);

  Future<void> verifyOtp(String phone, String code) =>
      _db.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);

  Future<void> signOut() => _db.auth.signOut();

  // ------------------------------------------------------------- profile

  Future<Profile?> myProfile() async {
    final id = currentUserId;
    if (id == null) return null;
    final row = await _db.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<void> saveProfile({required String displayName, String? city}) => _db.from('profiles').upsert({
        'id': currentUserId,
        'display_name': displayName.trim(),
        'city': (city?.trim().isEmpty ?? true) ? null : city!.trim(),
      });

  Future<String?> myPhone() async {
    final id = currentUserId;
    if (id == null) return null;
    final row = await _db.from('profile_contacts').select('phone').eq('user_id', id).maybeSingle();
    return row?['phone'] as String?;
  }

  // ------------------------------------------------------------ listings

  static const pageSize = 20;

  Future<List<Listing>> browse({String? search, String? categoryId, String? city, int page = 0}) async {
    var q = _db.from('listings').select(_listingSelect).eq('status', 'active');
    if (categoryId != null) q = q.eq('category_id', categoryId);
    final cityText = _safeFilterText(city);
    if (cityText.isNotEmpty) q = q.ilike('city', '%$cityText%');
    final searchText = _safeFilterText(search);
    if (searchText.isNotEmpty) {
      q = q.or('title.ilike.%$searchText%,description.ilike.%$searchText%,area.ilike.%$searchText%');
    }
    final rows = await q
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return rows.map(Listing.fromJson).toList();
  }

  Future<Listing?> listing(String id) async {
    final row = await _db.from('listings').select(_listingSelect).eq('id', id).maybeSingle();
    return row == null ? null : Listing.fromJson(row);
  }

  Future<List<Listing>> myListings() async {
    final rows = await _db
        .from('listings')
        .select('$_listingSelect, unlocks(count)')
        .eq('seller_id', currentUserId!)
        .order('created_at', ascending: false);
    return rows.map(Listing.fromJson).toList();
  }

  Future<ListingLocation?> myListingLocation(String listingId) async {
    final row = await _db.from('listing_locations').select().eq('listing_id', listingId).maybeSingle();
    return row == null ? null : ListingLocation.fromJson(row);
  }

  /// Creates a listing as a draft. It goes live with [publishIfReady] once a photo passes the check.
  Future<String> createListing(Map<String, dynamic> fields, ListingLocation location) async {
    final row = await _db
        .from('listings')
        .insert({...fields, 'seller_id': currentUserId, 'status': 'draft'})
        .select('id')
        .single();
    final id = row['id'] as String;
    await saveLocation(id, location);
    return id;
  }

  Future<void> updateListing(String id, Map<String, dynamic> fields, ListingLocation location) async {
    await _db.from('listings').update(fields).eq('id', id);
    await saveLocation(id, location);
  }

  Future<void> saveLocation(String listingId, ListingLocation location) =>
      _db.from('listing_locations').upsert({
        'listing_id': listingId,
        'address': location.address.trim(),
        'lat': location.lat,
        'lng': location.lng,
      });

  Future<void> setListingStatus(String id, String status) =>
      _db.from('listings').update({'status': status}).eq('id', id);

  /// Moves a draft live if it has at least one approved photo. Returns true if live.
  Future<bool> publishIfReady(String id) async {
    final approved = await _db
        .from('listing_images')
        .select('id')
        .eq('listing_id', id)
        .eq('status', 'approved')
        .limit(1);
    if (approved.isEmpty) return false;
    await _db.from('listings').update({'status': 'active'}).eq('id', id).eq('status', 'draft');
    return true;
  }

  // -------------------------------------------------------------- photos

  /// Uploads a photo privately, then asks the server to check it.
  /// Approved photos are copied to public storage by the server.
  Future<PhotoCheckResult> uploadPhoto(String listingId, Uint8List jpegBytes, int sortOrder) async {
    final path = '$currentUserId/$listingId/${const Uuid().v4()}.jpg';
    await _db.storage
        .from('listing-uploads')
        .uploadBinary(path, jpegBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    final row = await _db
        .from('listing_images')
        .insert({'listing_id': listingId, 'upload_path': path, 'sort_order': sortOrder})
        .select('id')
        .single();
    final res = await _db.functions.invoke('moderate-image', body: {'image_id': row['id']});
    final data = res.data as Map<String, dynamic>;
    return PhotoCheckResult(data['status'] as String, data['reason'] as String?);
  }

  Future<void> deletePhoto(String imageId) => _db.from('listing_images').delete().eq('id', imageId);

  // ------------------------------------------------------------- unlocks

  Future<bool> hasUnlocked(String listingId) async {
    final result = await _db.rpc('has_unlocked', params: {'p_listing_id': listingId});
    return result == true;
  }

  Future<ListingContact?> contact(String listingId) async {
    final rows = await _db.rpc('get_listing_contact', params: {'p_listing_id': listingId}) as List;
    return rows.isEmpty ? null : ListingContact.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<List<Unlock>> myUnlocks() async {
    final rows = await _db
        .from('unlocks')
        .select('id, listing_id, status, fee_rupees, created_at, paid_at, '
            'listings(title, status, city, area), refund_requests(status)')
        .eq('buyer_id', currentUserId!)
        .inFilter('status', ['paid', 'refunded', 'duplicate_paid'])
        .order('created_at', ascending: false);
    return rows.map(Unlock.fromJson).toList();
  }

  /// Buyers who paid to unlock one of my listings, with their phone numbers.
  Future<List<InterestedBuyer>> interestedBuyers(String listingId) async {
    final unlocks = await _db
        .from('unlocks')
        .select('buyer_id, paid_at')
        .eq('listing_id', listingId)
        .eq('status', 'paid')
        .order('paid_at', ascending: false);
    if (unlocks.isEmpty) return [];
    final ids = unlocks.map((u) => u['buyer_id'] as String).toList();
    final profiles = await _db.from('profiles').select('id, display_name').inFilter('id', ids);
    final phones = await _db.from('profile_contacts').select('user_id, phone').inFilter('user_id', ids);
    final names = {for (final p in profiles) p['id']: p['display_name'] as String};
    final numbers = {for (final p in phones) p['user_id']: p['phone'] as String};
    return [
      for (final u in unlocks)
        InterestedBuyer(
          name: names[u['buyer_id']] ?? 'Buyer',
          phone: numbers[u['buyer_id']],
          paidAt: DateTime.parse(u['paid_at'] as String),
        ),
    ];
  }

  /// reason: already_sold | seller_no_response
  Future<void> requestRefund(String unlockId, String reason) =>
      _db.rpc('request_refund', params: {'p_unlock_id': unlockId, 'p_reason': reason});

  // ------------------------------------------------------------- reports

  /// reason: one of the `report_reason` enum values.
  Future<void> report(String listingId, String reason, String? details) => _db.from('reports').insert({
        'listing_id': listingId,
        'reporter_id': currentUserId,
        'reason': reason,
        'details': (details?.trim().isEmpty ?? true) ? null : details!.trim(),
      });

  /// PostgREST filter strings treat , ( ) and % specially; drop them from user input.
  String _safeFilterText(String? input) => (input ?? '').replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();
}
