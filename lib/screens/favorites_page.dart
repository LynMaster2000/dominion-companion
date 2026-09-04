import 'package:flutter/material.dart';

import '../data/set_favorites_repository.dart';
import '../models/community_set.dart';
import '../models/dominion_card.dart';
import 'community_set_detail_page.dart';
import 'profile_page.dart';

class FavoritesPage extends StatefulWidget {
  final List<DominionCard> cards;

  const FavoritesPage({
    super.key,
    required this.cards,
  });

  @override
  State<FavoritesPage> createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  final SetFavoritesRepository _repository =
      SetFavoritesRepository();

  late Future<List<CommunitySet>> _setsFuture;

  @override
  void initState() {
    super.initState();
    _setsFuture = _repository.getFavoriteSets();
  }

  Future<void> refresh() async {
    setState(() {
      _setsFuture = _repository.getFavoriteSets();
    });

    await _setsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    cards: widget.cards,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<CommunitySet>>(
        future: _setsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load favorites.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sets = snapshot.data ?? [];

          if (sets.isEmpty) {
            return const Center(
              child: Text(
                'No favorites yet.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];

                return Card(
                  child: ListTile(
                    title: Text(set.name),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (set.expansions.isNotEmpty)
                          Text(
                            set.expansions.join(' • '),
                          ),

                        if (set.tags.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final tag in set.tags)
                                  Chip(
                                    label: Text(tag),
                                    visualDensity:
                                        VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize
                                            .shrinkWrap,
                                  ),
                              ],
                            ),
                          ),

                        Padding(
                          padding:
                              const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                set.ratingCount == 0
                                    ? 'No ratings'
                                    : '${set.averageRating.toStringAsFixed(1)} '
                                      '(${set.ratingCount})',
                              ),

                              const SizedBox(width: 16),

                              const Icon(
                                Icons.favorite,
                                size: 16,
                              ),
                              const SizedBox(width: 4),

                              Text(
                                '${set.favoriteCount}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CommunitySetDetailPage(
                            communitySet: set,
                            allCards: widget.cards,
                          ),
                        ),
                      );

                      if (!mounted) return;

                      await refresh();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}