import 'package:flutter/material.dart';

import '../ui/brand_mark.dart';
import '../ui/layout.dart';
import 'account/account_screen.dart';
import 'browse/browse_screen.dart';
import 'my_listings/my_listings_screen.dart';
import 'sell/post_listing_screen.dart';
import 'unlocks/my_unlocks_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  // Bumped to rebuild "My listings" after posting.
  int _myListingsVersion = 0;

  static const _destinations = [
    (Icons.search_rounded, Icons.search_rounded, 'Browse'),
    (Icons.lock_open_outlined, Icons.lock_open_rounded, 'Unlocked'),
    (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'My listings'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
  ];

  Future<void> _sell() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PostListingScreen()),
    );
    if (posted == true) {
      setState(() {
        _myListingsVersion++;
        _tab = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = IndexedStack(
      index: _tab,
      children: [
        const BrowseScreen(),
        const MyUnlocksScreen(),
        MyListingsScreen(key: ValueKey(_myListingsVersion), onSell: _sell),
        const AccountScreen(),
      ],
    );

    if (isCompact(context)) {
      return Scaffold(
        body: pages,
        floatingActionButton: _tab == 0 || _tab == 2
            ? FloatingActionButton.extended(
                onPressed: _sell,
                icon: const Icon(Icons.add_a_photo_rounded),
                label: const Text('Sell material'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            for (final (icon, selected, label) in _destinations)
              NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
          ],
        ),
      );
    }

    final extended = isExpanded(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 232,
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
              child: Column(children: [
                extended ? const BrandMark(size: 38) : const BrandMark(size: 40, showTagline: false),
                const SizedBox(height: 24),
                extended
                    ? FloatingActionButton.extended(
                        elevation: 0,
                        onPressed: _sell,
                        icon: const Icon(Icons.add_a_photo_rounded),
                        label: const Text('Sell material'),
                      )
                    : FloatingActionButton(
                        elevation: 0,
                        tooltip: 'Sell material',
                        onPressed: _sell,
                        child: const Icon(Icons.add_a_photo_rounded),
                      ),
              ]),
            ),
            destinations: [
              for (final (icon, selected, label) in _destinations)
                NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
            ],
          ),
          const VerticalDivider(width: 1),
          // Pages size themselves to the space beside the rail, not the whole window.
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => MediaQuery(
                data: MediaQuery.of(context).copyWith(size: Size(c.maxWidth, c.maxHeight)),
                child: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
