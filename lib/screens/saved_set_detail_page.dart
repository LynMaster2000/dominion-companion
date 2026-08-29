import 'package:flutter/material.dart';

import '../models/dominion_card.dart';
import '../models/saved_set.dart';
import '../data/saved_sets_repository.dart';
import '../models/card_sort.dart';

class SavedSetDetailPage extends StatefulWidget {
  final SavedSet savedSet;
  final List<DominionCard> allCards;

  const SavedSetDetailPage({
    super.key,
    required this.savedSet,
    required this.allCards,
  });

  @override
  State<SavedSetDetailPage> createState() =>
      _SavedSetDetailPageState();
}

class _SavedSetDetailPageState
    extends State<SavedSetDetailPage> {

  CardSort selectedSort = CardSort.alphabetical;

  Future<void> removeCard(DominionCard card) async {
    setState(() {
      widget.savedSet.kingdomCardIds.remove(card.id);
    });

    final repository = SavedSetRepository();
    final sets = await repository.loadSets();

    final index = sets.indexWhere(
      (set) => set.id == widget.savedSet.id,
    );

    if (index != -1) {
      sets[index] = widget.savedSet;
      await repository.saveSets(sets);
    }
  }

  Future<void> renameSet() async {
    final controller = TextEditingController(
      text: widget.savedSet.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Set'),
          content: TextField(
            controller: controller,
            autofocus: true,
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
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName == null) return;

    setState(() {
      widget.savedSet.name = newName;
    });

    final repository = SavedSetRepository();
    final sets = await repository.loadSets();

    final index = sets.indexWhere(
      (set) => set.id == widget.savedSet.id,
    );

    if (index != -1) {
      sets[index] = widget.savedSet;
      await repository.saveSets(sets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kingdomCards = widget.savedSet.kingdomCardIds
        .map(
          (id) => widget.allCards.firstWhere(
            (card) => card.id == id,
          ),
        )
        .toList();

    sortCards(
      kingdomCards,
      selectedSort,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.savedSet.name),

            const SizedBox(width: 8),

            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Rename',
              onPressed: renameSet,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Sort by:'),

                const SizedBox(width: 12),

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
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount: kingdomCards.length,
              itemBuilder: (context, index) {
                final card = kingdomCards[index];

                // your existing card widget
                return Card(
                  child: ListTile(
                    title: Text(card.name),
                    subtitle: Text(
                      '${card.set} • ${card.types.join(", ")}',
                    ),
                    trailing: Text(
                      card.cost.toString(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}