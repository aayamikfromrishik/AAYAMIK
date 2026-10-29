import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
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
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
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
        title: const Text('Filter by city'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Pune'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BAAKI BUILD'),
        actions: [
          IconButton(
            tooltip: 'City',
            onPressed: _pickCity,
            icon: Badge(isLabelVisible: _city != null, child: const Icon(Icons.location_city)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchBar(
                  controller: _search,
                  hintText: 'Search cement, tiles, steel…',
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  onSubmitted: (_) => _refresh(),
                  trailing: [
                    if (_search.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _refresh();
                        },
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip(null, 'All'),
                    for (final c in categories) _chip(c.id, c.name),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(onRefresh: _refresh, child: _body()),
    );
  }

  Widget _chip(String? id, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _categoryId == id,
        onSelected: (_) {
          setState(() => _categoryId = id);
          _refresh();
        },
      ),
    );
  }

  Widget _body() {
    if (_error != null && _listings.isEmpty) return ErrorView(error: _error!, onRetry: _refresh);
    if (_listings.isEmpty && _loading) return const Center(child: CircularProgressIndicator());
    if (_listings.isEmpty) {
      return ListView(children: [
        EmptyView(
          icon: Icons.search_off,
          message: _city == null ? 'No listings found.' : 'No listings found in $_city.',
        ),
      ]);
    }
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: _listings.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == _listings.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final listing = _listings[i];
        return ListingCard(
          listing: listing,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: listing.id)),
          ),
        );
      },
    );
  }
}
