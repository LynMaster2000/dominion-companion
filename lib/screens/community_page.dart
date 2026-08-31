import 'package:flutter/material.dart';

import '../data/community_sets_repository.dart';
import '../models/community_set.dart';
import '../models/dominion_card.dart';
import 'community_set_detail_page.dart';
import '../data/set_ratings_repository.dart';

class CommunityPage extends StatefulWidget {
  final List<DominionCard> cards;

  const CommunityPage({
    super.key,
    required this.cards,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunitySetsRepository _repository =
      CommunitySetsRepository();
  final SetRatingsRepository _ratingsRepository =
    SetRatingsRepository();

  late Future<List<CommunitySet>> _setsFuture;

  @override
  void initState() {
    super.initState();
    _setsFuture = _repository.getCommunitySets();
  }

  Future<void> refresh() async {
    setState(() {
      _setsFuture = _repository.getCommunitySets();
    });

    await _setsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
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
                  'Could not load community sets.\n\n'
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
                'No community sets yet.',
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
                  child: FutureBuilder<SetRatingSummary>(
                    future: _ratingsRepository.getRatingSummary(
                      set.id,
                    ),
                    builder: (context, ratingSnapshot) {
                      final summary = ratingSnapshot.data;

                      return ListTile(
                        title: Text(set.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (set.expansions.isNotEmpty)
                              Text(
                                set.expansions.join(' • '),
                              ),

                            if (set.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    for (final tag in set.tags)
                                      Chip(
                                        label: Text(tag),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                              ),

                            if (summary != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      summary.count == 0
                                          ? 'No ratings yet'
                                          : '${summary.average.toStringAsFixed(1)} '
                                            '(${summary.count})',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CommunitySetDetailPage(
                                communitySet: set,
                                allCards: widget.cards,
                              ),
                            ),
                          );
                        },
                      );
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