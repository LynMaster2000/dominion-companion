import 'package:flutter/material.dart';

import '../data/card_repository.dart';
import '../models/dominion_card.dart';
import 'randomizer_page.dart';
import 'card_browser_page.dart';
import 'saved_sets_page.dart';
import 'recommended_sets_page.dart';
import 'community_page.dart';

class MainPage extends StatefulWidget {
  final CardRepository repository;
  final List<DominionCard> cards;

  const MainPage({
    super.key,
    required this.repository,
    required this.cards,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  final GlobalKey<SavedSetsPageState> savedSetsKey =
    GlobalKey<SavedSetsPageState>();
  final GlobalKey<NavigatorState> savedSetsNavigatorKey =
    GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          RandomizerPage(
            repository: widget.repository,
            cards: widget.cards,
          ),

          CardBrowserPage(
            cards: widget.cards,
          ),

          Navigator(
            key: savedSetsNavigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => SavedSetsPage(
                  key: savedSetsKey,
                  cards: widget.cards,
                ),
              );
            },
          ),

          RecommendedSetsPage(
            cards: widget.cards,
          ),

          CommunityPage(
            cards: widget.cards,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2 && selectedIndex == 2) {
            savedSetsNavigatorKey.currentState?.popUntil(
              (route) => route.isFirst,
            );

            savedSetsKey.currentState?.refreshSets();
            return;
          }

          setState(() {
            selectedIndex = index;
          });

          if (index == 2) {
            savedSetsKey.currentState?.refreshSets();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Randomizer',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks),
            label: 'Saved Sets',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Official',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}