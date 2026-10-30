import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../ui/brand_mark.dart';
import '../../ui/layout.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';
import '../listing/listing_detail_screen.dart';
import 'listing_card.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _listings = <Listing>[];
  String? _categoryId;
  String? _city;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _loadMore();
    });
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _page = 0;
    _hasMore = true;
    _listings.clear();
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await Repository.instance
          .browse(search: _search.text, categoryId: _categoryId, city: _city, page: _page);
      setState(() {
        _listings.addAll(page);
        _page++;
        _hasMore = page.length == Repository.pageSize;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCity() async {
    final controller = TextEditingController(text: _city);
    final city = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose city'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Pune', prefixIcon: Icon(Icons.location_city_rounded)),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('All cities')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Apply')),
        ],
      ),
    );
    if (city == null) return;
    setState(() => _city = city.trim().isEmpty ? null : city.trim());
    _refresh();
  }

  void _open(Listing listing) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: listing.id)),
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pad = sidePadding(width, maxWidth: 1240);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _hero(pad)),
            SliverToBoxAdapter(child: _categories(pad)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 12),
              sliver: SliverToBoxAdapter(child: _resultsHeader()),
            ),
            ..._results(pad, width),
          ],
        ),
      ),
    );
  }

  Widget _hero(double pad) {
    final compact = isCompact(context);
    final theme = Theme.of(context);
    return Container(
      color: Brand.header,
      padding: EdgeInsets.fromLTRB(pad, MediaQuery.paddingOf(context).top + (compact ? 16 : 32), pad, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Row(children: [
              const BrandMark(onDark: true, size: 34),
              const Spacer(),
              _cityButton(),
            ]),
            const SizedBox(height: 22),
          ],
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Leftover material.\nFair price.',
                  style: (compact ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge)
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cement, steel, tiles and more from builders near you.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ]),
            ),
            if (!compact) _cityButton(),
          ]),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SearchBar(
              controller: _search,
              hintText: 'Search cement, tiles, TMT bars…',
              leading: Icon(Icons.search_rounded, color: Brand.muted),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              constraints: const BoxConstraints(minHeight: 54),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
              textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: Brand.font, fontSize: 16)),
              onSubmitted: (_) => _refresh(),
              trailing: [
                if (_search.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      _refresh();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityButton() {
    return TextButton.icon(
      onPressed: _pickCity,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Brand.headerSoft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(Icons.place_rounded, size: 18, color: Brand.highlight),
      label: Text(_city ?? 'All cities'),
    );
  }

  Widget _categories(double pad) {
    return SizedBox(
      height: 68,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(pad, 14, pad, 10),
        children: [
          _chip(null, 'All', Icons.apps_rounded),
          for (final c in categories) _chip(c.id, c.name, c.icon),
        ],
      ),
    );
  }

  Widget _chip(String? id, String label, IconData icon) {
    final selected = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, color: selected ? Colors.white : Brand.accent),
        label: Text(label),
        labelStyle: TextStyle(
          fontFamily: Brand.font,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Brand.ink,
        ),
        selected: selected,
        onSelected: (_) {
          setState(() => _categoryId = id);
          _refresh();
        },
      ),
    );
  }

  Widget _resultsHeader() {
    final theme = Theme.of(context);
    final category = _categoryId == null ? null : categoryById(_categoryId!).name;
    final where = _city == null ? '' : ' in $_city';
    return Text(
      category == null ? 'Latest listings$where' : '$category$where',
      style: theme.textTheme.titleLarge,
    );
  }

  List<Widget> _results(double pad, double width) {
    if (_error != null && _listings.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: ErrorView(error: _error!, onRetry: _refresh))];
    }
    if (_listings.isEmpty && _loading) {
      return [const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))];
    }
    if (_listings.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Nothing here yet',
            message: _city == null
                ? 'Try another category or search word.'
                : 'No listings in $_city yet. Try another city.',
          ),
        ),
      ];
    }
    final compact = width < compactMax;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: compact ? 240 : 300,
            mainAxisExtent: compact ? 300 : 340,
            mainAxisSpacing: compact ? 12 : 18,
            crossAxisSpacing: compact ? 12 : 18,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => ListingTile(listing: _listings[i], onTap: () => _open(_listings[i])),
            childCount: _listings.length,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: _hasMore ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
        ),
      ),
    ];
  }
}
