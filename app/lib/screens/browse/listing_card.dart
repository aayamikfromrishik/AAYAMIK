import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

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
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 96,
                  child: ListingPhoto(publicPath: photos.isEmpty ? null : photos.first.publicPath),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(quantityWithUnit(listing.quantity, listing.unit), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(rupees(listing.priceRupees),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text('${listing.area}, ${listing.city}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                      ),
                    ]),
                    if (footer != null) ...[const SizedBox(height: 6), footer!],
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
