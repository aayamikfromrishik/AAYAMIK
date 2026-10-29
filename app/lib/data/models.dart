class ListingImage {
  ListingImage({
    required this.id,
    required this.status,
    this.publicPath,
    this.rejectionReason,
    this.sortOrder = 0,
  });

  factory ListingImage.fromJson(Map<String, dynamic> j) => ListingImage(
        id: j['id'] as String,
        status: j['status'] as String,
        publicPath: j['public_path'] as String?,
        rejectionReason: j['rejection_reason'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );

  final String id;

  /// pending | approved | rejected
  final String status;
  final String? publicPath;
  final String? rejectionReason;
  final int sortOrder;

  bool get isApproved => status == 'approved' && publicPath != null;
}

class Listing {
  Listing({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.priceRupees,
    required this.unlockFeeRupees,
    required this.condition,
    required this.city,
    required this.area,
    required this.status,
    required this.createdAt,
    this.approxLat,
    this.approxLng,
    this.sellerName,
    this.images = const [],
    this.unlockCount = 0,
  });

  factory Listing.fromJson(Map<String, dynamic> j) {
    final images = ((j['listing_images'] as List?) ?? [])
        .map((e) => ListingImage.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final unlocks = j['unlocks'] as List?;
    return Listing(
      id: j['id'] as String,
      sellerId: j['seller_id'] as String,
      categoryId: j['category_id'] as String,
      title: j['title'] as String,
      description: (j['description'] as String?) ?? '',
      quantity: (j['quantity'] as num).toDouble(),
      unit: j['unit'] as String,
      priceRupees: (j['price_rupees'] as num).toInt(),
      unlockFeeRupees: (j['unlock_fee_rupees'] as num).toInt(),
      condition: j['condition'] as String,
      city: j['city'] as String,
      area: j['area'] as String,
      status: j['status'] as String,
      createdAt: DateTime.parse(j['created_at'] as String),
      approxLat: (j['approx_lat'] as num?)?.toDouble(),
      approxLng: (j['approx_lng'] as num?)?.toDouble(),
      sellerName: (j['profiles'] as Map?)?['display_name'] as String?,
      images: images,
      unlockCount: unlocks != null && unlocks.isNotEmpty
          ? ((unlocks.first as Map)['count'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  final String id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String description;
  final double quantity;
  final String unit;
  final int priceRupees;
  final int unlockFeeRupees;
  final String condition;
  final String city;
  final String area;

  /// draft | active | sold | removed
  final String status;
  final DateTime createdAt;
  final double? approxLat;
  final double? approxLng;
  final String? sellerName;
  final List<ListingImage> images;

  /// Number of buyers who paid to unlock. Only filled for the seller's own listings.
  final int unlockCount;

  List<ListingImage> get approvedImages => images.where((i) => i.isApproved).toList();
}

class ListingLocation {
  ListingLocation({required this.address, this.lat, this.lng});

  factory ListingLocation.fromJson(Map<String, dynamic> j) => ListingLocation(
        address: j['address'] as String,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  final String address;
  final double? lat;
  final double? lng;
}

/// What a buyer sees after paying the unlock fee.
class ListingContact {
  ListingContact({required this.sellerName, this.sellerPhone, this.address, this.lat, this.lng});

  factory ListingContact.fromJson(Map<String, dynamic> j) => ListingContact(
        sellerName: j['seller_name'] as String,
        sellerPhone: j['seller_phone'] as String?,
        address: j['address'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  final String sellerName;
  final String? sellerPhone;
  final String? address;
  final double? lat;
  final double? lng;
}

class Profile {
  Profile({required this.id, required this.displayName, this.city});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        displayName: j['display_name'] as String,
        city: j['city'] as String?,
      );

  final String id;
  final String displayName;
  final String? city;
}

class Unlock {
  Unlock({
    required this.id,
    required this.listingId,
    required this.status,
    required this.feeRupees,
    required this.createdAt,
    this.paidAt,
    this.listingTitle,
    this.listingStatus,
    this.listingCity,
    this.refundStatus,
  });

  factory Unlock.fromJson(Map<String, dynamic> j) {
    final listing = j['listings'] as Map<String, dynamic>?;
    final refunds = j['refund_requests'];
    final refund = refunds is List
        ? (refunds.isEmpty ? null : refunds.first as Map<String, dynamic>)
        : refunds as Map<String, dynamic>?;
    return Unlock(
      id: j['id'] as String,
      listingId: j['listing_id'] as String,
      status: j['status'] as String,
      feeRupees: (j['fee_rupees'] as num).toInt(),
      createdAt: DateTime.parse(j['created_at'] as String),
      paidAt: j['paid_at'] == null ? null : DateTime.parse(j['paid_at'] as String),
      listingTitle: listing?['title'] as String?,
      listingStatus: listing?['status'] as String?,
      listingCity: listing == null ? null : '${listing['area']}, ${listing['city']}',
      refundStatus: refund?['status'] as String?,
    );
  }

  final String id;
  final String listingId;

  /// paid | refunded | duplicate_paid
  final String status;
  final int feeRupees;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? listingTitle;
  final String? listingStatus;
  final String? listingCity;

  /// pending | approved | rejected, or null if no refund was requested.
  final String? refundStatus;
}

/// A buyer who unlocked one of the seller's listings.
class InterestedBuyer {
  InterestedBuyer({required this.name, required this.paidAt, this.phone});

  final String name;
  final String? phone;
  final DateTime paidAt;
}
