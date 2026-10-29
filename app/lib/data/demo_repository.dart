import 'dart:typed_data';

import '../core/fees.dart';
import 'models.dart';
import 'repository.dart';

/// True when built with --dart-define=DEMO=true: sample data, no backend,
/// no login, payments simulated. Used to review the design.
const demoMode = bool.fromEnvironment('DEMO');

const _me = 'demo-me';

/// In-memory stand-in for [Repository] with realistic sample listings.
class DemoRepository extends Repository {
  DemoRepository() : super.live();

  final _unlocked = <String>{'d-tiles'};
  final _listings = _sampleListings();
  var _profile = Profile(id: _me, displayName: 'Shree Ganesh Constructions', city: 'Pune');

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  String? get currentUserId => _me;

  @override
  String imageUrl(String publicPath) => publicPath;

  @override
  Future<void> sendOtp(String phone) => _wait();

  @override
  Future<void> verifyOtp(String phone, String code) => _wait();

  @override
  Future<void> signOut() => _wait();

  @override
  Future<Profile?> myProfile() async => _profile;

  @override
  Future<void> saveProfile({required String displayName, String? city}) async {
    _profile = Profile(id: _me, displayName: displayName, city: city);
  }

  @override
  Future<String?> myPhone() async => '+919800000001';

  @override
  Future<List<Listing>> browse({String? search, String? categoryId, String? city, int page = 0}) async {
    await _wait();
    if (page > 0) return [];
    final q = (search ?? '').toLowerCase().trim();
    final c = (city ?? '').toLowerCase().trim();
    return _listings
        .where((l) => l.status == 'active')
        .where((l) => categoryId == null || l.categoryId == categoryId)
        .where((l) => c.isEmpty || l.city.toLowerCase().contains(c))
        .where((l) => q.isEmpty || '${l.title} ${l.description} ${l.area}'.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Listing?> listing(String id) async {
    await _wait();
    return _listings.where((l) => l.id == id).firstOrNull;
  }

  @override
  Future<List<Listing>> myListings() async {
    await _wait();
    return _listings.where((l) => l.sellerId == _me).toList();
  }

  @override
  Future<ListingLocation?> myListingLocation(String listingId) async =>
      ListingLocation(address: 'Survey No. 41, Hinjewadi Phase 2, Pune 411057', lat: 18.59, lng: 73.73);

  @override
  Future<String> createListing(Map<String, dynamic> fields, ListingLocation location) async {
    await _wait();
    final id = 'd-new-${_listings.length}';
    final price = fields['price_rupees'] as int;
    _listings.insert(
      0,
      Listing(
        id: id,
        sellerId: _me,
        categoryId: fields['category_id'] as String,
        title: fields['title'] as String,
        description: fields['description'] as String,
        quantity: fields['quantity'] as double,
        unit: fields['unit'] as String,
        priceRupees: price,
        unlockFeeRupees: unlockFeeRupees(price),
        condition: fields['condition'] as String,
        city: fields['city'] as String,
        area: fields['area'] as String,
        status: 'active',
        createdAt: DateTime.now(),
        sellerName: _profile.displayName,
      ),
    );
    return id;
  }

  @override
  Future<void> updateListing(String id, Map<String, dynamic> fields, ListingLocation location) => _wait();

  @override
  Future<void> saveLocation(String listingId, ListingLocation location) => _wait();

  @override
  Future<void> setListingStatus(String id, String status) async {
    await _wait();
    final i = _listings.indexWhere((l) => l.id == id);
    if (i >= 0) _listings[i] = _copyWithStatus(_listings[i], status);
  }

  @override
  Future<bool> publishIfReady(String id) async => true;

  @override
  Future<PhotoCheckResult> uploadPhoto(String listingId, Uint8List jpegBytes, int sortOrder) async {
    await _wait();
    return PhotoCheckResult('approved', null);
  }

  @override
  Future<void> deletePhoto(String imageId) => _wait();

  @override
  Future<bool> hasUnlocked(String listingId) async => _unlocked.contains(listingId);

  @override
  Future<ListingContact?> contact(String listingId) async {
    final l = _listings.firstWhere((l) => l.id == listingId);
    return ListingContact(
      sellerName: l.sellerName ?? 'Seller',
      sellerPhone: '+919822012345',
      address: 'Plot 7, near Shivaji Chowk, ${l.area}, ${l.city}',
      lat: l.approxLat,
      lng: l.approxLng,
    );
  }

  /// Simulates a successful Razorpay payment.
  Future<void> fakeUnlock(String listingId) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    _unlocked.add(listingId);
  }

  @override
  Future<List<Unlock>> myUnlocks() async {
    await _wait();
    return [
      for (final l in _listings.where((l) => _unlocked.contains(l.id)))
        Unlock(
          id: 'u-${l.id}',
          listingId: l.id,
          status: 'paid',
          feeRupees: l.unlockFeeRupees,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          paidAt: DateTime.now().subtract(const Duration(days: 1)),
          listingTitle: l.title,
          listingStatus: l.status,
          listingCity: '${l.area}, ${l.city}',
        ),
    ];
  }

  @override
  Future<List<InterestedBuyer>> interestedBuyers(String listingId) async => [
        InterestedBuyer(
          name: 'Patil Infra',
          phone: '+919890011223',
          paidAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        InterestedBuyer(
          name: 'Ramesh Kulkarni',
          phone: '+919767755443',
          paidAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

  @override
  Future<void> requestRefund(String unlockId, String reason) => _wait();

  @override
  Future<void> report(String listingId, String reason, String? details) => _wait();
}

Listing _copyWithStatus(Listing l, String status) => Listing(
      id: l.id,
      sellerId: l.sellerId,
      categoryId: l.categoryId,
      title: l.title,
      description: l.description,
      quantity: l.quantity,
      unit: l.unit,
      priceRupees: l.priceRupees,
      unlockFeeRupees: l.unlockFeeRupees,
      condition: l.condition,
      city: l.city,
      area: l.area,
      status: status,
      createdAt: l.createdAt,
      approxLat: l.approxLat,
      approxLng: l.approxLng,
      sellerName: l.sellerName,
      images: l.images,
      unlockCount: l.unlockCount,
    );

List<Listing> _sampleListings() {
  final now = DateTime.now();
  Listing make(
    String id,
    String category,
    String title,
    String description,
    double quantity,
    String unit,
    int price,
    String condition,
    String city,
    String area,
    int hoursAgo, {
    String seller = 'Mehta Builders',
    String sellerId = 'other',
    int unlockCount = 0,
  }) =>
      Listing(
        id: id,
        sellerId: sellerId,
        categoryId: category,
        title: title,
        description: description,
        quantity: quantity,
        unit: unit,
        priceRupees: price,
        unlockFeeRupees: unlockFeeRupees(price),
        condition: condition,
        city: city,
        area: area,
        status: 'active',
        createdAt: now.subtract(Duration(hours: hoursAgo)),
        approxLat: 18.52,
        approxLng: 73.86,
        sellerName: seller,
        unlockCount: unlockCount,
      );

  return [
    make('d-cement', 'cement', 'UltraTech PPC cement, 50 kg bags',
        'Left over after slab casting. Stored indoors on pallets, bags sealed. Manufactured last month.',
        85, 'bags', 29750, 'unused_surplus', 'Pune', 'Hinjewadi', 2,
        seller: 'Shree Ganesh Constructions', sellerId: _me, unlockCount: 3),
    make('d-tmt', 'steel', 'TMT bars Fe 550D, 12 mm and 16 mm',
        'Tata Tiscon. Mixed lengths, no rust. Pickup by truck from site.', 1.8, 'tonnes', 102000,
        'unused_surplus', 'Mumbai', 'Thane West', 5),
    make('d-tiles', 'tiles_flooring', 'Kajaria vitrified tiles 600 × 600, Ivory',
        '42 boxes (4 tiles per box). Extra from a flat project, same batch.', 42, 'boxes', 21000,
        'new', 'Bengaluru', 'Whitefield', 9, seller: 'Prestige Interiors'),
    make('d-bricks', 'bricks_blocks', 'AAC blocks 600 × 200 × 150',
        'Approx. 900 blocks, a few chipped corners.', 900, 'pieces', 36000, 'used_good', 'Hyderabad',
        'Gachibowli', 20),
    make('d-ply', 'wood_plywood', 'Greenply BWP plywood 18 mm, 8 × 4',
        '25 sheets, unused. Kept covered.', 25, 'pieces', 47500, 'new', 'Ahmedabad', 'SG Highway', 26,
        seller: 'Shah Furniture Works'),
    make('d-pipes', 'plumbing', 'Astral CPVC pipes ¾ inch',
        '60 lengths of 3 m plus elbows and tees in a box.', 60, 'pieces', 7800, 'unused_surplus', 'Delhi',
        'Dwarka Sector 12', 30),
    make('d-sand', 'sand_aggregates', 'River sand, washed',
        'About one truck load left at site. Buyer arranges transport.', 4, 'cu_m', 9500, 'new', 'Chennai',
        'OMR, Thoraipakkam', 40, seller: 'KR Builders'),
    make('d-wire', 'electrical', 'Polycab FR wire 2.5 sq mm, red and black', '9 coils of 90 m, sealed.', 9,
        'boxes', 16200, 'new', 'Pune', 'Kharadi', 50, seller: 'Shree Ganesh Constructions', sellerId: _me),
    make('d-paint', 'paint', 'Asian Paints Apex exterior emulsion, white', '6 buckets of 20 L.', 120, 'litres',
        24000, 'new', 'Jaipur', 'Mansarovar', 60),
    make('d-granite', 'stone_marble', 'Black galaxy granite slabs', '14 slabs, 18 mm, polished.', 14,
        'pieces', 168000, 'unused_surplus', 'Bengaluru', 'Electronic City', 70),
    make('d-door', 'doors_windows', 'Flush doors 7 × 3 ft, primed', '5 doors, never fitted.', 5, 'pieces',
        900, 'used_fair', 'Nashik', 'Gangapur Road', 80),
  ];
}
