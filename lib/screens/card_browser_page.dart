import 'package:flutter/material.dart';

import '../models/dominion_card.dart';
import '../data/saved_sets_repository.dart';
import '../models/saved_set.dart';
import '../models/card_sort.dart';
import '../widgets/card_info_dialog.dart';
import '../data/extra_sync.dart';
import '../data/kingdom_piles.dart';
import '../widgets/kingdom_pile_dialog.dart';

class CardBrowserPage extends StatefulWidget {
  final List<DominionCard> cards;
  final SavedSet? targetSet;
  final String? replaceCardId;
  final String? requiredTypeFilter;
  final bool returnAfterSelection;

  const CardBrowserPage({
    super.key,
    required this.cards,
    this.targetSet,
    this.replaceCardId,
    this.requiredTypeFilter,
    this.returnAfterSelection = false,
  });

  @override
  State<CardBrowserPage> createState() => _CardBrowserPageState();
}

class _CardBrowserPageState extends State<CardBrowserPage> {
  String searchText = '';
  CardSort selectedSort = CardSort.alphabetical;
  String? selectedExpansion;
  String? selectedType;
  int? selectedCost;

  @override
  void initState() {
    super.initState();

    if (widget.requiredTypeFilter != null) {
      selectedType = widget.requiredTypeFilter;
    }
  }
  
  Future<void> addCardToSavedSet(DominionCard card) async {
    final repository = SavedSetRepository();
    final savedSets = await repository.loadSets();

    if (!mounted) return;

    if (widget.targetSet != null) {
      final targetSet = widget.targetSet!;

      final index = savedSets.indexWhere(
        (set) => set.id == targetSet.id,
      );

      if (index != -1) {
        savedSets[index] = targetSet;
      }

      if (widget.replaceCardId != null) {
        final replaceIndex = targetSet.kingdomCardIds.indexOf(
          widget.replaceCardId!,
        );

        if (replaceIndex == -1) {
          return;
        }

        if (targetSet.kingdomCardIds.contains(card.id)) {
          final messenger = ScaffoldMessenger.of(context);

          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  '${card.name} is already in ${targetSet.name}.',
                ),
              ),
            );

          return;
        }

        targetSet.kingdomCardIds[replaceIndex] = card.id;
        syncRequiredExtras(
          targetSet,
          widget.cards,
        );

        await repository.saveSets(savedSets);

        if (widget.returnAfterSelection && mounted) {
          Navigator.pop(context, true);
          return;
        }

        if (!mounted) return;

        Navigator.pop(context, true);
        return;
      }

      await addCardToSet(
        card,
        targetSet,
        savedSets,
        repository,
      );

      return;
    }

    if (savedSets.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'You have no saved sets yet.',
            ),
          ),
        );
      return;
    }

    final selectedSet = await showDialog<SavedSet>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Add ${card.name} to...'),
          children: savedSets.map((set) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, set);
              },
              child: Text(
                '${set.name} (${set.kingdomCardIds.length}/10)',
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedSet == null) return;

    await addCardToSet(
      card,
      selectedSet,
      savedSets,
      repository,
    );
  }

  Future<void> addCardToSet(
    DominionCard card,
    SavedSet set,
    List<SavedSet> allSets,
    SavedSetRepository repository,
  ) async {
    if (card.purpose != 'Kingdom Pile') {
      final alreadyAdded = set.extras.any(
        (extra) => extra.cardId == card.id,
      );

      if (alreadyAdded) {
        if (!mounted) return;

        final messenger = ScaffoldMessenger.of(context);

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${card.name} is already in ${set.name}.',
              ),
            ),
          );

        return;
      }

      set.extras.add(
        SavedExtra(
          cardId: card.id,
        ),
      );

      syncRequiredExtras(
        set,
        widget.cards,
      );

      await repository.saveSets(allSets);

      if (widget.returnAfterSelection && mounted) {
        Navigator.pop(context, true);
        return;
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Added ${card.name} to ${set.name} as an extra.',
            ),
          ),
        );

      return;
    }

    // Kingdom card logic starts here

    if (set.kingdomCardIds.contains(card.id)) {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${card.name} is already in ${set.name}.',
            ),
          ),
        );

      return;
    }

    if (set.kingdomCardIds.length < 10) {
      set.kingdomCardIds.add(card.id);
      syncRequiredExtras(
        set,
        widget.cards,
      );

      await repository.saveSets(allSets);

      if (widget.returnAfterSelection && mounted) {
        Navigator.pop(context, true);
        return;
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Added ${card.name} to ${set.name}.',
            ),
          ),
        );

      return;
    }

    await chooseCardToReplace(
      newCard: card,
      set: set,
      allSets: allSets,
      repository: repository,
    );
}

  Future<void> chooseCardToReplace({
    required DominionCard newCard,
    required SavedSet set,
    required List<SavedSet> allSets,
    required SavedSetRepository repository,
  }) async {
    final cardToReplace = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            '${set.name} already has 10 cards.\n'
            'Replace which card?',
          ),
          children: set.kingdomCardIds.map((cardId) {
            final card = widget.cards.firstWhere(
              (card) => card.id == cardId,
            );

            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, cardId);
              },
              child: Text(card.name),
            );
          }).toList(),
        );
      },
    );

    if (cardToReplace == null) return;

    final index = set.kingdomCardIds.indexOf(cardToReplace);

    if (index == -1) return;

    set.kingdomCardIds[index] = newCard.id;

      syncRequiredExtras(
        set,
        widget.cards,
      );

    await repository.saveSets(allSets);

    if (widget.returnAfterSelection && mounted) {
      Navigator.pop(context, true);
      return;
    }

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Added ${newCard.name} to ${set.name}.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final expansions = widget.cards
        .map((card) => card.set)
        .toSet()
        .toList()
      ..sort();

    final types = widget.cards
        .expand((card) => card.types)
        .toSet()
        .toList()
      ..sort();

    final costs = widget.cards
        .map((card) => card.cost.coins)
        .toSet()
        .toList()
      ..sort();
      
    final filteredCards = widget.cards.where((card) {
      final pile = getKingdomPileForCard(card.id);

      // For rotating piles, only show the actual aggregate pile card
      // such as Augurs, Clashes, Forts, etc.
      if (pile != null &&
          card.id != pile.representativeCardId) {
        return false;
      }
      final search = searchText.toLowerCase();

      final matchesSearch =
          card.name.toLowerCase().contains(search) ||
          card.set.toLowerCase().contains(search) ||
          card.types.any(
            (type) => type.toLowerCase().contains(search),
          );

      final matchesExpansion =
          selectedExpansion == null ||
          card.set == selectedExpansion;

      final effectiveType =
          widget.requiredTypeFilter ?? selectedType;

      final matchesType =
          effectiveType == null ||
          card.types.contains(effectiveType);

      final matchesCost =
          selectedCost == null ||
          card.cost.coins == selectedCost;

      return matchesSearch &&
          matchesExpansion &&
          matchesType &&
          matchesCost;
    }).toList();

    sortCards(
      filteredCards,
      selectedSort,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.targetSet == null
              ? 'Card Browser'
              : 'Add Cards',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search cards',
                hintText: 'Village, Attack, Seaside...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),

            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String?>(
                    value: selectedExpansion,
                    hint: const Text('Expansion'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All expansions'),
                      ),
                      ...expansions.map(
                        (expansion) => DropdownMenuItem<String?>(
                          value: expansion,
                          child: Text(expansion),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedExpansion = value;
                      });
                    },
                  ),

                  const SizedBox(width: 16),

                  DropdownButton<String?>(
                    value: selectedType,
                    hint: const Text('Type'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All types'),
                      ),
                      ...types.map(
                        (type) => DropdownMenuItem<String?>(
                          value: type,
                          child: Text(type),
                        ),
                      ),
                    ],
                    onChanged: widget.requiredTypeFilter != null
                      ? null
                      : (value) {
                          setState(() {
                            selectedType = value;
                          });
                        },
                  ),

                  const SizedBox(width: 16),

                  DropdownButton<int?>(
                    value: selectedCost,
                    hint: const Text('Cost'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All costs'),
                      ),
                      ...costs.map(
                        (cost) => DropdownMenuItem<int?>(
                          value: cost,
                          child: Text('\$$cost'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCost = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            DropdownButton<CardSort>(
              value: selectedSort,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedSort = value;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: CardSort.alphabetical,
                  child: Text('Alphabetical A-Z'),
                ),
                DropdownMenuItem(
                  value: CardSort.alphabeticalReverse,
                  child: Text('Alphabetical Z-A'),
                ),
                DropdownMenuItem(
                  value: CardSort.costLowHigh,
                  child: Text('Cost: Low to High'),
                ),
                DropdownMenuItem(
                  value: CardSort.costHighLow,
                  child: Text('Cost: High to Low'),
                ),
                DropdownMenuItem(
                  value: CardSort.expansion,
                  child: Text('Expansion'),
                ),
                DropdownMenuItem(
                  value: CardSort.type,
                  child: Text('Type'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: filteredCards.length,
                itemBuilder: (context, index) {
                  final card = filteredCards[index];

                  return Card(
                    child: ListTile(
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
                      title: Text(card.name),
                      subtitle: Text(
                        '${card.types.join(' • ')}\n${card.set}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(card.cost.toString()),
                          IconButton(
                            tooltip: 'Add to saved set',
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              addCardToSavedSet(card);
                            },
                          ),
                        ],
                      ),
                    )
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}