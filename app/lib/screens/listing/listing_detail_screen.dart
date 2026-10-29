import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/categories.dart';
import '../../core/format.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../services/unlock_payment.dart';
import '../../widgets/common.dart';
import 'report_sheet.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _repo = Repository.instance;
  final _payment = UnlockPayment();
  Listing? _listing;
  ListingContact? _contact;
  List<InterestedBuyer> _buyers = [];
  bool _loading = true;
  bool _unlocking = false;
  Object? _error;

  bool get _isOwn => _listing?.sellerId == _repo.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _payment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await _repo.listing(widget.listingId);
      ListingContact? contact;
      var buyers = <InterestedBuyer>[];
      if (listing != null) {
        final own = listing.sellerId == _repo.currentUserId;
        if (own) {
          buyers = await _repo.interestedBuyers(listing.id);
        } else if (await _repo.hasUnlocked(listing.id)) {
          contact = await _repo.contact(listing.id);
        }
      }
      setState(() {
        _listing = listing;
        _contact = contact;
        _buyers = buyers;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unlock() async {
    final listing = _listing!;
    setState(() => _unlocking = true);
    try {
      await _payment.unlock(listing, buyerPhone: await _repo.myPhone());
      final contact = await _repo.contact(listing.id);
      if (!mounted) return;
      setState(() => _contact = contact);
      showMessage(context, 'Unlocked! You can now call the seller.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (listing != null && !_isOwn)
            IconButton(
              tooltip: 'Report',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => showReportSheet(context, listing.id),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(error: _error!, onRetry: _load)
              : listing == null
                  ? const EmptyView(icon: Icons.inventory_2_outlined, message: 'This listing is no longer available.')
                  : RefreshIndicator(onRefresh: _load, child: _details(listing)),
      bottomNavigationBar: listing == null || _isOwn || _contact != null || listing.status != 'active'
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: _unlocking ? null : _unlock,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      icon: _unlocking
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.lock_open),
                      label: Text('Unlock contact & location · ${rupees(listing.unlockFeeRupees)}'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pay once to see the seller\'s phone number and exact address. '
                      'Refund if already sold, or no reply within 48 hours.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _details(Listing listing) {
    final theme = Theme.of(context);
    final category = categoryById(listing.categoryId);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _PhotoGallery(images: listing.approvedImages),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (listing.status != 'active') ...[StatusChip(listing.status), const SizedBox(height: 8)],
              Text(listing.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(rupees(listing.priceRupees),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
              Text('for ${quantityWithUnit(listing.quantity, listing.unit)}', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(avatar: Icon(category.icon, size: 18), label: Text(category.name)),
                Chip(label: Text(conditionLabels[listing.condition] ?? listing.condition)),
              ]),
              if (listing.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Details', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(listing.description, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text('${listing.area}, ${listing.city}'),
                subtitle: Text(_contact != null || _isOwn
                    ? 'Exact address below'
                    : 'Approximate area. Exact address after unlock.'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront_outlined),
                title: Text(listing.sellerName ?? 'Seller'),
                subtitle: Text('Posted ${shortDate(listing.createdAt)}'),
              ),
              if (_contact != null) _ContactCard(contact: _contact!),
              if (_isOwn) _BuyersSection(buyers: _buyers),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.images});

  final List<ListingImage> images;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const AspectRatio(aspectRatio: 4 / 3, child: ListingPhoto());
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => ListingPhoto(publicPath: widget.images[i].publicPath),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.images.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index ? Colors.white : Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final ListingContact contact;

  Uri get _mapsUri {
    final query = contact.lat != null && contact.lng != null
        ? '${contact.lat},${contact.lng}'
        : contact.address ?? '';
    return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.lock_open, color: Colors.green.shade800),
              const SizedBox(width: 8),
              Text('Seller contact', style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            Text(contact.sellerName, style: theme.textTheme.titleMedium),
            if (contact.sellerPhone != null) ...[
              const SizedBox(height: 4),
              SelectableText(contact.sellerPhone!, style: theme.textTheme.headlineSmall),
            ],
            if (contact.address != null) ...[
              const SizedBox(height: 8),
              SelectableText(contact.address!, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (contact.sellerPhone != null)
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: contact.sellerPhone)),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              if (contact.address != null || contact.lat != null)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(_mapsUri, mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _BuyersSection extends StatelessWidget {
  const _BuyersSection({required this.buyers});

  final List<InterestedBuyer> buyers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text('Buyers who unlocked (${buyers.length})', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (buyers.isEmpty)
          Text('No one yet. Buyers who pay to unlock will appear here with their phone number.',
              style: theme.textTheme.bodyMedium)
        else
          for (final b in buyers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(b.name),
              subtitle: Text('${b.phone ?? ''}  ·  ${shortDate(b.paidAt)}'),
              trailing: b.phone == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () => launchUrl(Uri(scheme: 'tel', path: b.phone)),
                    ),
            ),
      ],
    );
  }
}
