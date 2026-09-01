import 'package:flutter/material.dart';

import '../data/community_sets_repository.dart';
import '../models/community_set.dart';
import '../models/dominion_card.dart';
import 'community_set_detail_page.dart';
import '../models/community_filter.dart';
import '../widgets/community_filter_dialog.dart';
import '../data/community_tags.dart';

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

  late Future<List<CommunitySet>> _setsFuture;
  CommunityFilter _filter = const CommunityFilter();

  Future<void> _openFilterDialog() async {
    final availableExpansions = widget.cards
        .map((card) => card.set)
        .toSet()
        .toList()
      ..sort();

    final result =
        await showDialog<CommunityFilter>(
      context: context,
      builder: (context) {
        return CommunityFilterDialog(
          filter: _filter,
          availableExpansions: availableExpansions,
          availableTags: communityTags,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _filter = result;
      _setsFuture = _repository.getCommunitySets(_filter);
    });
  }

  @override
  void initState() {
    super.initState();
    _setsFuture = _repository.getCommunitySets(_filter);
  }

  Future<void> refresh() async {
    setState(() {
      _setsFuture = _repository.getCommunitySets(_filter);
    });

    await _setsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            tooltip: 'Filter and sort',
            onPressed: _openFilterDialog,
            icon: Badge(
              isLabelVisible: _filter.hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
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
                  child: ListTile(
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
                                    visualDensity:
                                        VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ),

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
                                set.ratingCount == 0
                                    ? 'No ratings yet'
                                    : '${set.averageRating.toStringAsFixed(1)} '
                                      '(${set.ratingCount})',
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