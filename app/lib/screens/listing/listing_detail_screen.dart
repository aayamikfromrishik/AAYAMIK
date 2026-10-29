import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/categories.dart';
import '../../core/format.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../services/unlock_payment.dart';
import '../../ui/layout.dart';
import '../../ui/theme.dart';
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
  bool get _canUnlock => _listing != null && !_isOwn && _contact == null && _listing!.status == 'active';

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
        if (listing.sellerId == _repo.currentUserId) {
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
    final compact = isCompact(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (listing != null && !_isOwn)
            IconButton(
              tooltip: 'Report listing',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => showReportSheet(context, listing.id),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(error: _error!, onRetry: _load)
              : listing == null
                  ? const EmptyView(
                      icon: Icons.inventory_2_outlined,
                      title: 'Not available',
                      message: 'This listing has been removed or sold.',
                    )
                  : RefreshIndicator(onRefresh: _load, child: compact ? _compact(listing) : _wide(listing)),
      bottomNavigationBar: compact && _canUnlock
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Brand.line)),
                ),
                child: _UnlockButton(fee: listing!.unlockFeeRupees, busy: _unlocking, onPressed: _unlock),
              ),
            )
          : null,
    );
  }

  Widget _compact(Listing listing) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _PhotoGallery(images: listing.approvedImages, categoryId: listing.categoryId),
        ),
        const SizedBox(height: 16),
        _summary(listing),
        const SizedBox(height: 12),
        ..._sidePanels(listing),
        const SizedBox(height: 12),
        _details(listing),
      ],
    );
  }

  Widget _wide(Listing listing) {
    final pad = sidePadding(MediaQuery.sizeOf(context).width, maxWidth: 1180, min: 24);
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 40),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _PhotoGallery(images: listing.approvedImages, categoryId: listing.categoryId),
                ),
                const SizedBox(height: 16),
                _details(listing),
              ]),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 380,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _summary(listing),
                const SizedBox(height: 12),
                if (_canUnlock)
                  SectionCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _UnlockButton(fee: listing.unlockFeeRupees, busy: _unlocking, onPressed: _unlock),
                    ]),
                  ),
                ..._sidePanels(listing),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summary(Listing listing) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (listing.status != 'active') ...[StatusChip(listing.status), const SizedBox(height: 10)],
          Text(rupees(listing.priceRupees), style: theme.textTheme.headlineMedium),
          Text('for ${quantityWithUnit(listing.quantity, listing.unit)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Brand.muted)),
          const SizedBox(height: 12),
          Text(listing.title, style: theme.textTheme.titleLarge?.copyWith(height: 1.25)),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.place_rounded,
            title: '${listing.area}, ${listing.city}',
            subtitle: _isOwn
                ? 'Exact address shown only to buyers who unlock'
                : _contact != null
                    ? 'Exact address shown below'
                    : 'Exact address after unlock',
          ),
          _InfoRow(
            icon: Icons.storefront_rounded,
            title: listing.sellerName ?? 'Seller',
            subtitle: 'Posted ${shortDate(listing.createdAt)}',
          ),
        ],
      ),
    );
  }

  List<Widget> _sidePanels(Listing listing) => [
        if (_contact != null) _ContactCard(contact: _contact!),
        if (_isOwn) _BuyersCard(buyers: _buyers),
        if (_canUnlock) const _HowUnlockWorks(),
      ];

  Widget _details(Listing listing) {
    final theme = Theme.of(context);
    final category = categoryById(listing.categoryId);
    return SectionCard(
      title: 'Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(avatar: Icon(category.icon, color: Brand.orange), label: Text(category.name)),
            Chip(label: Text(conditionLabels[listing.condition] ?? listing.condition)),
            Chip(label: Text(quantityWithUnit(listing.quantity, listing.unit))),
          ]),
          if (listing.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(listing.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Brand.sand, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: Brand.charcoal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleSmall),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Brand.muted)),
          ]),
        ),
      ]),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.fee, required this.busy, required this.onPressed});

  final int fee;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      icon: busy
          ? const SizedBox.square(
              dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.lock_open_rounded),
      label: Text('Unlock contact · ${rupees(fee)}'),
    );
  }
}

class _HowUnlockWorks extends StatelessWidget {
  const _HowUnlockWorks();

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: Brand.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        title: 'What you get',
        child: Column(children: [
          point(Icons.call_rounded, "Seller's phone number"),
          point(Icons.map_rounded, 'Exact pickup address and map'),
          point(Icons.replay_rounded, 'Refund if already sold, or no reply in 48 hours'),
        ]),
      ),
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.images, required this.categoryId});

  final List<ListingImage> images;
  final String categoryId;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return AspectRatio(aspectRatio: 4 / 3, child: ListingPhoto(categoryId: widget.categoryId));
    }
    final many = widget.images.length > 1;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) =>
                ListingPhoto(publicPath: widget.images[i].publicPath, categoryId: widget.categoryId),
          ),
          if (many) ...[
            _arrow(Alignment.centerLeft, Icons.chevron_left_rounded, -1),
            _arrow(Alignment.centerRight, Icons.chevron_right_rounded, 1),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _index ? 18 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _index ? Colors.white : Colors.white60,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _arrow(Alignment alignment, IconData icon, int delta) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(backgroundColor: Colors.white70),
          onPressed: () => _controller.animateToPage(
            (_index + delta).clamp(0, widget.images.length - 1),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
          icon: Icon(icon),
        ),
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
      color: Brand.greenSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Brand.green.withAlpha(70)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.verified_rounded, color: Brand.green),
              const SizedBox(width: 8),
              Text('Contact unlocked', style: theme.textTheme.titleMedium?.copyWith(color: Brand.green)),
            ]),
            const SizedBox(height: 14),
            Text(contact.sellerName, style: theme.textTheme.titleMedium),
            if (contact.sellerPhone != null)
              SelectableText(formatPhone(contact.sellerPhone!),
                  style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 0.5)),
            if (contact.address != null) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.place_rounded, size: 18, color: Brand.charcoal),
                const SizedBox(width: 6),
                Expanded(child: SelectableText(contact.address!, style: theme.textTheme.bodyLarge)),
              ]),
            ],
            const SizedBox(height: 16),
            Row(children: [
              if (contact.sellerPhone != null)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Brand.green),
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: contact.sellerPhone)),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call'),
                  ),
                ),
              if (contact.sellerPhone != null && (contact.address != null || contact.lat != null))
                const SizedBox(width: 10),
              if (contact.address != null || contact.lat != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), backgroundColor: Colors.white),
                    onPressed: () => launchUrl(_mapsUri, mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Directions'),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _BuyersCard extends StatelessWidget {
  const _BuyersCard({required this.buyers});

  final List<InterestedBuyer> buyers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Buyers who unlocked (${buyers.length})',
      subtitle: buyers.isEmpty ? null : 'They have your number and may call. You can call them too.',
      child: buyers.isEmpty
          ? Text('No one yet. Buyers who pay to unlock will appear here with their phone number.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Brand.muted))
          : Column(children: [
              for (final b in buyers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Brand.orangeSoft,
                    child: Text(b.name.characters.first.toUpperCase(),
                        style: const TextStyle(color: Brand.orange, fontWeight: FontWeight.w800)),
                  ),
                  title: Text(b.name, style: theme.textTheme.titleSmall),
                  subtitle: Text('${b.phone == null ? '' : formatPhone(b.phone!)} · ${shortDate(b.paidAt)}'),
                  trailing: b.phone == null
                      ? null
                      : IconButton.filledTonal(
                          icon: const Icon(Icons.call_rounded),
                          onPressed: () => launchUrl(Uri(scheme: 'tel', path: b.phone)),
                        ),
                ),
            ]),
    );
  }
}
