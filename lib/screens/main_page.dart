import 'package:flutter/material.dart';

import '../data/card_repository.dart';
import '../models/dominion_card.dart';
import 'randomizer_page.dart';
import 'saved_sets_page.dart';
import 'favorites_page.dart';
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

  final GlobalKey<NavigatorState> randomizerNavigatorKey =
      GlobalKey<NavigatorState>();

  final GlobalKey<SavedSetsPageState> savedSetsKey =
      GlobalKey<SavedSetsPageState>();

  final GlobalKey<NavigatorState> savedSetsNavigatorKey =
      GlobalKey<NavigatorState>();

  final GlobalKey<FavoritesPageState> favoritesKey =
      GlobalKey<FavoritesPageState>();

  final GlobalKey<NavigatorState> favoritesNavigatorKey =
      GlobalKey<NavigatorState>();

  final GlobalKey<NavigatorState> communityNavigatorKey =
      GlobalKey<NavigatorState>();

  final GlobalKey<CommunityPageState> communityKey =
    GlobalKey<CommunityPageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          Navigator(
            key: randomizerNavigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => RandomizerPage(
                  repository: widget.repository,
                  cards: widget.cards,
                ),
              );
            },
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

          Navigator(
            key: favoritesNavigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => FavoritesPage(
                  key: favoritesKey,
                  cards: widget.cards,
                ),
              );
            },
          ),

          Navigator(
            key: communityNavigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => CommunityPage(
                  key: communityKey,
                  cards: widget.cards,
                ),
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) {
            switch (index) {
              case 0:
                randomizerNavigatorKey.currentState?.popUntil(
                  (route) => route.isFirst,
                );
                break;

              case 1:
                savedSetsNavigatorKey.currentState?.popUntil(
                  (route) => route.isFirst,
                );
                savedSetsKey.currentState?.refreshSets();
                break;

              case 2:
                favoritesNavigatorKey.currentState?.popUntil(
                  (route) => route.isFirst,
                );
                favoritesKey.currentState?.refresh();
                break;

              case 3:
                communityNavigatorKey.currentState?.popUntil(
                  (route) => route.isFirst,
                );
                communityKey.currentState?.refresh();
                break;
            }

            return;
          }

          setState(() {
            selectedIndex = index;
          });

          if (index == 1) {
            savedSetsKey.currentState?.refreshSets();
          }

          if (index == 2) {
            favoritesKey.currentState?.refresh();
          }

          if (index == 3) {
            communityKey.currentState?.refresh();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Randomizer',
          ),
          NavigationDestination(
            icon: Icon(Icons.construction_outlined),
            selectedIcon: Icon(Icons.construction),
            label: 'Set Creator',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
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