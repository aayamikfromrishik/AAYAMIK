import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/repository.dart';
import '../../ui/layout.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';
import '../browse/listing_card.dart';
import '../listing/listing_detail_screen.dart';
import '../sell/post_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key, required this.onSell});

  final VoidCallback onSell;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<Listing>> _future = Repository.instance.myListings();

  Future<void> _refresh() async {
    final future = Repository.instance.myListings();
    setState(() => _future = future);
    await future;
  }

  Future<void> _edit(Listing listing) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PostListingScreen(existing: listing)),
    );
    if (saved == true) _refresh();
  }

  Future<void> _setStatus(Listing listing, String status, String message) async {
    try {
      if (status == 'active' && listing.status == 'draft') {
        final live = await Repository.instance.publishIfReady(listing.id);
        if (!live) {
          if (mounted) showMessage(context, 'Add at least one accepted photo first.');
          return;
        }
      } else {
        await Repository.instance.setListingStatus(listing.id, status);
      }
      if (mounted) showMessage(context, message);
      _refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: pageAppBar(context, 'My listings'),
      body: FutureBuilder<List<Listing>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _refresh);
          final listings = snap.data!;
          if (listings.isEmpty) {
            return EmptyView(
              icon: Icons.inventory_2_rounded,
              title: 'Nothing listed yet',
              message: 'Turn leftover material into cash. Listing is free and takes 2 minutes.',
              action: FilledButton(onPressed: widget.onSell, child: const Text('Sell material')),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  sidePadding(MediaQuery.sizeOf(context).width, maxWidth: 900), 4,
                  sidePadding(MediaQuery.sizeOf(context).width, maxWidth: 900), 96),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _item(listings[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _item(Listing l) {
    final pending = l.images.where((i) => i.status == 'pending').length;
    final rejected = l.images.where((i) => i.status == 'rejected').length;
    final theme = Theme.of(context);
    return ListingCard(
      listing: l,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: l.id)),
        );
        _refresh();
      },
      footer: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        StatusChip(l.status),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_open_rounded, size: 14, color: Brand.muted),
          const SizedBox(width: 3),
          Text('${l.unlockCount} unlocked',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ]),
        if (pending > 0) Text('$pending photo(s) checking', style: theme.textTheme.bodySmall),
        if (rejected > 0)
          Text('$rejected photo(s) rejected',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
      ]),
      trailing: l.status == 'removed'
          ? null
          : PopupMenuButton<String>(
              onSelected: (action) => switch (action) {
                'edit' => _edit(l),
                'sold' => _setStatus(l, 'sold', 'Marked as sold'),
                'active' => _setStatus(l, 'active', 'Listing is live again'),
                'draft' => _setStatus(l, 'draft', 'Listing hidden'),
                _ => null,
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (l.status == 'active') const PopupMenuItem(value: 'sold', child: Text('Mark as sold')),
                if (l.status != 'active') const PopupMenuItem(value: 'active', child: Text('Make live')),
                if (l.status == 'active') const PopupMenuItem(value: 'draft', child: Text('Hide listing')),
              ],
            ),
    );
  }
}
