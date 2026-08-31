import 'package:flutter/material.dart';

import '../data/recommended_sets_repository.dart';
import '../models/dominion_card.dart';
import '../models/recommended_set.dart';
import 'recommended_set_detail_page.dart';

class RecommendedSetsPage extends StatefulWidget {
  final List<DominionCard> cards;

  const RecommendedSetsPage({
    super.key,
    required this.cards,
  });

  @override
  State<RecommendedSetsPage> createState() =>
      _RecommendedSetsPageState();
}

class _RecommendedSetsPageState
    extends State<RecommendedSetsPage> {
  final RecommendedSetsRepository repository =
      RecommendedSetsRepository();

  List<RecommendedSet> sets = [];
  bool isLoading = true;
  String? firstExpansion;
  String? secondExpansion;

  @override
  void initState() {
    super.initState();
    loadSets();
  }

  Future<void> loadSets() async {
    final loadedSets = await repository.loadSets();

    if (!mounted) {
      return;
    }

    setState(() {
      sets = loadedSets;
      isLoading = false;
    });
  }

  List<String> get availableExpansions {
    final expansions = sets
        .expand((set) => set.expansions)
        .toSet()
        .toList();

    expansions.sort();
    return expansions;
  }

  List<String> get availableSecondExpansions {
    if (firstExpansion == null) {
      return [];
    }

    final expansions = sets
        .where(
          (set) => set.expansions.contains(firstExpansion),
        )
        .expand((set) => set.expansions)
        .where((expansion) => expansion != firstExpansion)
        .toSet()
        .toList();

    expansions.sort();
    return expansions;
  }

  List<RecommendedSet> get filteredSets {
    if (firstExpansion == null) {
      return [];
    }

    final result = sets.where((set) {
      if (!set.expansions.contains(firstExpansion)) {
        return false;
      }

      if (secondExpansion != null &&
          !set.expansions.contains(secondExpansion)) {
        return false;
      }

      return true;
    }).toList();

    result.sort((a, b) {
      // If only one expansion is selected, single-expansion sets go first.
      if (secondExpansion == null) {
        final aIsSingleExpansion =
            a.expansions.length == 1 &&
            a.expansions.contains(firstExpansion);

        final bIsSingleExpansion =
            b.expansions.length == 1 &&
            b.expansions.contains(firstExpansion);

        if (aIsSingleExpansion && !bIsSingleExpansion) {
          return -1;
        }

        if (!aIsSingleExpansion && bIsSingleExpansion) {
          return 1;
        }
      }

      final aOtherExpansions = a.expansions
          .where((expansion) => expansion != firstExpansion)
          .toList()
        ..sort();

      final bOtherExpansions = b.expansions
          .where((expansion) => expansion != firstExpansion)
          .toList()
        ..sort();

      final aGroup = aOtherExpansions.join(' + ');
      final bGroup = bOtherExpansions.join(' + ');

      final groupComparison = aGroup.compareTo(bGroup);

      if (groupComparison != 0) {
        return groupComparison;
      }

      return a.name.compareTo(b.name);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Sets'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sets.isEmpty
              ? const Center(
                  child: Text(
                    'No official sets loaded yet.',
                  ),
                )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: firstExpansion,
                          decoration: const InputDecoration(
                            labelText: 'Expansion',
                            border: OutlineInputBorder(),
                          ),
                          items: availableExpansions
                              .map(
                                (expansion) => DropdownMenuItem(
                                  value: expansion,
                                  child: Text(expansion),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              firstExpansion = value;
                              secondExpansion = null;
                            });
                          },
                        ),

                        if (firstExpansion != null) ...[
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            initialValue: secondExpansion,
                            decoration: const InputDecoration(
                              labelText: 'Second expansion (optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Any'),
                              ),
                              ...availableSecondExpansions.map(
                                (expansion) => DropdownMenuItem(
                                  value: expansion,
                                  child: Text(expansion),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                secondExpansion = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  Expanded(
                    child: firstExpansion == null
                        ? const Center(
                            child: Text(
                              'Choose an expansion to see official sets.',
                            ),
                          )
                        : filteredSets.isEmpty
                            ? const Center(
                                child: Text(
                                  'No official sets found for this combination.',
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredSets.length,
                                itemBuilder: (context, index) {
                                  final set = filteredSets[index];

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      title: Text(set.name),
                                      subtitle: Text(
                                        [
                                          firstExpansion!,
                                          ...set.expansions
                                              .where((expansion) => expansion != firstExpansion),
                                        ].join(' + '),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RecommendedSetDetailPage(
                                              recommendedSet: set,
                                              allCards: widget.cards,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              )
    );
  }
}