import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';

/// Grid tile used on Browse: photo on top, price and details below.
class ListingTile extends StatelessWidget {
  const ListingTile({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = listing.approvedImages;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ListingPhoto(
                  publicPath: photos.isEmpty ? null : photos.first.publicPath,
                  categoryId: listing.categoryId,
                ),
                Positioned(left: 8, bottom: 8, child: UnlockFeePill(feeRupees: listing.unlockFeeRupees, compact: true)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rupees(listing.priceRupees),
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 19, height: 1.1)),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quantityWithUnit(listing.quantity, listing.unit),
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(color: Brand.muted),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.place_rounded, size: 13, color: Brand.muted),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '${listing.area}, ${listing.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: Brand.muted),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row card used in management lists (My listings).
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap, this.trailing, this.footer});

  final Listing listing;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = listing.approvedImages;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 92,
                  child: ListingPhoto(
                    publicPath: photos.isEmpty ? null : photos.first.publicPath,
                    categoryId: listing.categoryId,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(rupees(listing.priceRupees), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${quantityWithUnit(listing.quantity, listing.unit)} · ${listing.area}, ${listing.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: Brand.muted),
                    ),
                    if (footer != null) ...[const SizedBox(height: 8), footer!],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
