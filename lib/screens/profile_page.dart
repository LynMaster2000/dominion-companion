import 'package:flutter/material.dart';

import '../data/community_sets_repository.dart';
import '../models/community_set.dart';
import '../models/dominion_card.dart';
import 'community_set_detail_page.dart';

class ProfilePage extends StatefulWidget {
  final List<DominionCard> cards;

  const ProfilePage({
    super.key,
    required this.cards,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final CommunitySetsRepository _repository =
      CommunitySetsRepository();

  late Future<List<CommunitySet>> _setsFuture;

  @override
  void initState() {
    super.initState();
    _setsFuture = _repository.getMyPublishedSets();
  }

  Future<void> refresh() async {
    setState(() {
      _setsFuture = _repository.getMyPublishedSets();
    });

    await _setsFuture;
  }

  Future<void> deleteSet(CommunitySet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Published Set?'),
          content: Text(
            'Delete "${set.name}" from Community?\n\n'
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.deletePublishedSet(set.id);

      if (!mounted) return;

      await refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${set.name}" was deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete the published set.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
                  'Could not load your published sets.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sets = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Published Sets',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 12),

                if (sets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 32,
                    ),
                    child: Center(
                      child: Text(
                        'You have not published any sets yet.',
                      ),
                    ),
                  ),

                for (final set in sets)
                  Card(
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

                          const SizedBox(height: 6),

                          Row(
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
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete published set',
                        onPressed: () {
                          deleteSet(set);
                        },
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
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}