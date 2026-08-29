import 'package:flutter/material.dart';

import '../models/dominion_card.dart';
import '../models/saved_set.dart';
import '../data/saved_sets_repository.dart';
import '../models/card_sort.dart';
import 'card_browser_page.dart';
import '../widgets/card_info_dialog.dart';

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

  Future<void> replaceCard(DominionCard card) async {
    final replaced = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CardBrowserPage(
          cards: widget.allCards,
          targetSet: widget.savedSet,
          replaceCardId: card.id,
        ),
      ),
    );

    if (!mounted) return;

    if (replaced == true) {
      setState(() {});
    }
  }

  Future<void> openCardBrowser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardBrowserPage(
          cards: widget.allCards,
          targetSet: widget.savedSet,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

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

    final extraCards = widget.savedSet.extras
      .map(
        (extra) => widget.allCards.firstWhere(
          (card) => card.id == extra.cardId,
        ),
      )
      .toList();

    sortCards(
      kingdomCards,
      selectedSort,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.savedSet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Rename set',
            onPressed: renameSet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kingdom',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      '${kingdomCards.length}/10',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Text('Sort:'),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButton<CardSort>(
                        value: selectedSort,
                        isExpanded: true,
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
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 170,
                  ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      if (index >= kingdomCards.length) {
                        return Card(
                          elevation: 0,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: openCardBrowser,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add card',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final card = kingdomCards[index];

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            showCardInfoDialog(context, card);
                          },
                            child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  card.types.join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),

                                const Spacer(),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        card.set,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    Text(
                                      card.cost.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Replace card',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        icon: const Icon(
                                          Icons.swap_horiz,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          replaceCard(card);
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Remove card',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        icon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          removeCard(card);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      );
                    },
                  ),

                if (extraCards.isNotEmpty) ...[
                  const SizedBox(height: 24),

                  Text(
                    'Extras',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  ...extraCards.map(
                    (card) => Card(
                      child: ListTile(
                        onTap: () {
                          showCardInfoDialog(context, card);
                        },
                        title: Text(card.name),
                        subtitle: Text(
                          '${card.types.join(' • ')}\n${card.set}',
                        ),
                        trailing: Text(card.cost.toString()),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openCardBrowser,
                  icon: const Icon(Icons.add),
                  label: Text(
                    kingdomCards.length >= 10
                        ? 'Add New Cards'
                        : 'Add Cards',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}