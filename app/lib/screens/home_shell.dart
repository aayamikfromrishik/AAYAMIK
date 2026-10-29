import 'package:flutter/material.dart';

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
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const BrowseScreen(),
          const MyUnlocksScreen(),
          MyListingsScreen(key: ValueKey(_myListingsVersion), onSell: _sell),
          const AccountScreen(),
        ],
      ),
      floatingActionButton: _tab == 0 || _tab == 2
          ? FloatingActionButton.extended(
              onPressed: _sell,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Sell material'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.lock_open_outlined), label: 'Unlocked'),
          NavigationDestination(icon: Icon(Icons.inventory_outlined), label: 'My listings'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}
