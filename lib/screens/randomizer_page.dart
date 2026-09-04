import 'package:flutter/material.dart';

import '../data/card_repository.dart';
import '../data/saved_sets_repository.dart';
import '../models/dominion_card.dart';
import '../models/saved_set.dart';
import '../widgets/card_info_dialog.dart';
import '../data/kingdom_piles.dart';
import '../widgets/kingdom_pile_dialog.dart';
import 'recommended_sets_page.dart';
import 'profile_page.dart';

class RandomizerPage extends StatefulWidget {
  final CardRepository repository;
  final List<DominionCard> cards;

  const RandomizerPage({
    super.key,
    required this.repository,
    required this.cards,
  });

  @override
  State<RandomizerPage> createState() => _RandomizerPageState();
}

class _RandomizerPageState extends State<RandomizerPage> {
  final Set<String> selectedExpansions = {};
  List<DominionCard> kingdom = [];
  Set<String> lockedCardIds = {};

  void generateKingdom() {
    final selectedCards = widget.cards
        .where((card) => selectedExpansions.contains(card.set))
        .where((card) => card.purpose == 'Kingdom Pile')
        .where((card) {
          final pile = getKingdomPileForCard(card.id);

          return pile == null ||
              card.id == pile.representativeCardId;
        })
        .toList();

    final lockedCards = kingdom
        .where((card) => lockedCardIds.contains(card.id))
        .toList();

    final lockedIds = lockedCards
        .map((card) => card.id)
        .toSet();

    final availableCards = selectedCards
        .where((card) => !lockedIds.contains(card.id))
        .toList();

    availableCards.shuffle();

    final cardsNeeded = 10 - lockedCards.length;

    final newCards = availableCards
        .take(cardsNeeded)
        .toList();

    setState(() {
      kingdom = [
        ...lockedCards,
        ...newCards,
      ];

      lockedCardIds.removeWhere(
        (id) => !kingdom.any((card) => card.id == id),
      );
    });
  }

  void rerollCard(int index) {
    final oldCard = kingdom[index];

    final usedCardIds = kingdom
        .map((card) => card.id)
        .toSet();

    final availableCards = widget.cards
        .where((card) {
          if (!selectedExpansions.contains(card.set)) {
            return false;
          }

          if (card.purpose != 'Kingdom Pile') {
            return false;
          }

          if (usedCardIds.contains(card.id)) {
            return false;
          }

          final pile = getKingdomPileForCard(card.id);

          if (pile != null &&
              card.id != pile.representativeCardId) {
            return false;
          }

          return true;
        })
        .toList();

    if (availableCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other cards available to reroll.'),
        ),
      );
      return;
    }

    availableCards.shuffle();

    final newCard = availableCards.first;

    setState(() {
      kingdom[index] = newCard;

      // The old card should no longer remain locked.
      lockedCardIds.remove(oldCard.id);
    });
  }

  Future<void> saveKingdom(BuildContext context) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Kingdom'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Set name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (name == null) {
      return;
    }

    final newSet = SavedSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      kingdomCardIds: kingdom
          .map((card) => card.id)
          .toList(),
      extras: [],
    );

    final repository = SavedSetRepository();

    final savedSets = await repository.loadSets();

    savedSets.add(newSet);

    await repository.saveSets(savedSets);

    print('Saved set: ${newSet.name}');
  }

  void openOfficialSets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendedSetsPage(
          cards: widget.cards,
        ),
      ),
    );
  }

  void openExpansionSelector() {
    final expansions = widget.cards
        .map((card) => card.set)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Select Expansions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        children: expansions.map((expansion) {
                          return CheckboxListTile(
                            title: Text(expansion),
                            value: selectedExpansions.contains(
                              expansion,
                            ),
                            onChanged: (selected) {
                              setModalState(() {
                                if (selected == true) {
                                  selectedExpansions.add(
                                    expansion,
                                  );
                                } else {
                                  selectedExpansions.remove(
                                    expansion,
                                  );
                                }
                              });

                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expansions = widget.cards
        .map((card) => card.set)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Randomizer'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_add_outlined,
            ),
            tooltip: 'Save Kingdom',
            onPressed: kingdom.length == 10
                ? () => saveKingdom(context)
                : null,
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: openExpansionSelector,
                icon: const Icon(Icons.tune),
                label: Text(
                  selectedExpansions.isEmpty
                      ? 'Select Expansions'
                      : '${selectedExpansions.length} expansions selected',
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: openOfficialSets,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Official Sets'),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: kingdom.length,
                itemBuilder: (context, index) {
                  final card = kingdom[index];

                  final isLocked = lockedCardIds.contains(card.id);

                  return Card(
                    color: isLocked
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                        : null,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        final pile = getKingdomPileForCard(card.id);

                        if (pile != null &&
                            card.id == pile.representativeCardId) {
                          showKingdomPileDialog(
                            context,
                            pileCard: card,
                            allCards: widget.cards,
                          );
                          return;
                        }

                        showCardInfoDialog(
                          context,
                          card,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    card.types.join(' • '),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    card.set,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              card.cost.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 8),

                            IconButton(
                              tooltip: 'Reroll card',
                              icon: const Icon(Icons.refresh),
                              onPressed: lockedCardIds.contains(card.id)
                                  ? null
                                  : () => rerollCard(index),
                            ),

                            IconButton(
                              tooltip: lockedCardIds.contains(card.id)
                                  ? 'Unlock'
                                  : 'Lock',
                              icon: Icon(
                                lockedCardIds.contains(card.id)
                                    ? Icons.lock
                                    : Icons.lock_open,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (lockedCardIds.contains(card.id)) {
                                    lockedCardIds.remove(card.id);
                                  } else {
                                    lockedCardIds.add(card.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedExpansions.isEmpty
                    ? null
                    : generateKingdom,
                icon: const Icon(Icons.casino),
                label: const Text('Generate Kingdom'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}