import 'package:flutter/material.dart';

import '../models/dominion_card.dart';
import '../data/saved_sets_repository.dart';
import '../models/saved_set.dart';
import '../models/card_sort.dart';

class CardBrowserPage extends StatefulWidget {
  final List<DominionCard> cards;

  const CardBrowserPage({
    super.key,
    required this.cards,
  });

  @override
  State<CardBrowserPage> createState() => _CardBrowserPageState();
}

class _CardBrowserPageState extends State<CardBrowserPage> {
  String searchText = '';
  CardSort selectedSort = CardSort.alphabetical;
  

  Future<void> addCardToSavedSet(DominionCard card) async {
    final repository = SavedSetRepository();
    final savedSets = await repository.loadSets();

    if (!mounted) return;

    if (savedSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have no saved sets yet.'),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.name} is already in ${set.name}.'),
          ),
        );

        return;
      }

      set.extras.add(
        SavedExtra(
          cardId: card.id,
        ),
      );

      await repository.saveSets(allSets);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${card.name} is already in ${set.name}.'),
        ),
      );

      return;
    }

    if (set.kingdomCardIds.length < 10) {
      set.kingdomCardIds.add(card.id);

      await repository.saveSets(allSets);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

    await repository.saveSets(allSets);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${newCard.name} to ${set.name}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCards = widget.cards.where((card) {
      final search = searchText.toLowerCase();

      return card.name.toLowerCase().contains(search) ||
          card.set.toLowerCase().contains(search) ||
          card.types.any(
            (type) => type.toLowerCase().contains(search),
          );
    }).toList();

    sortCards(
      filteredCards,
      selectedSort,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Browser'),
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

            const SizedBox(height: 16),

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

                  return Tooltip(
                    message: card.instructions,
                    waitDuration: const Duration(milliseconds: 500),
                    constraints: const BoxConstraints(
                      maxWidth: 350,
                    ),

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),

                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),

                    child: Card(
                      child: ListTile(
                        title: Text(card.name),
                        subtitle: Text(
                          '${card.set} • ${card.types.join(", ")}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(card.cost.toString()),

                            const SizedBox(width: 8),

                            IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Add to saved set',
                              onPressed: () {
                                addCardToSavedSet(card);
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
          ],
        ),
      ),
    );
  }
}