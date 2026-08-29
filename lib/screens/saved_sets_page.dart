import 'package:flutter/material.dart';

import '../data/saved_sets_repository.dart';
import '../models/saved_set.dart';
import '../models/dominion_card.dart';
import 'saved_set_detail_page.dart';

class SavedSetsPage extends StatefulWidget {
  final List<DominionCard> cards;

  const SavedSetsPage({
    super.key,
    required this.cards,
  });

  @override
  State<SavedSetsPage> createState() => _SavedSetsPageState();
}

class _SavedSetsPageState extends State<SavedSetsPage> {
  final SavedSetRepository repository = SavedSetRepository();

  List<SavedSet> savedSets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSets();
  }

  Future<void> loadSets() async {
    final sets = await repository.loadSets();

    setState(() {
      savedSets = sets;
      loading = false;
    });
  }

  Future<void> deleteSet(SavedSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Set'),
          content: Text(
            'Delete "${set.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
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

    savedSets.remove(set);

    await repository.saveSets(savedSets);

    setState(() {});
  }

  Future<void> renameSet(SavedSet set) async {
    final controller = TextEditingController(
      text: set.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Set'),
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
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName == null) return;

    set.name = newName;

    await repository.saveSets(savedSets);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Sets'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : savedSets.isEmpty
              ? const Center(
                  child: Text('No saved sets yet'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: savedSets.length,
                  itemBuilder: (context, index) {
                    final set = savedSets[index];

                    return Card(
                      child: ListTile(
                        title: Text(set.name),
                        subtitle: Text(
                          '${set.kingdomCardIds.length} cards'
                          ' • ${set.extras.length} extras',
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SavedSetDetailPage(
                                savedSet: set,
                                allCards: widget.cards,
                              ),
                            ),
                          ).then((_) {
                            loadSets();
                          });
                        },

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Rename',
                              onPressed: () {
                                renameSet(set);
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                              onPressed: () {
                                deleteSet(set);
                              },
                            ),

                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}