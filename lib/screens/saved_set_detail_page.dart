import 'package:flutter/material.dart';

import '../models/dominion_card.dart';
import '../models/saved_set.dart';
import '../data/saved_sets_repository.dart';
import '../models/card_sort.dart';
import 'card_browser_page.dart';
import '../widgets/card_info_dialog.dart';
import '../data/extra_sync.dart';
import '../data/card_dependencies.dart';
import '../widgets/kingdom_pile_dialog.dart';
import '../data/kingdom_piles.dart';
import '../widgets/publish_set_dialog.dart';
import '../data/community_sets_repository.dart';

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

  Future<void> publishSet() async {
    if (widget.savedSet.kingdomCardIds.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A set must contain exactly 10 Kingdom cards before publishing.',
          ),
        ),
      );
      return;
    }

    final alreadyPublished =
        await CommunitySetsRepository()
            .hasAlreadyPublished(
              widget.savedSet,
            );

    if (!mounted) return;

    if (alreadyPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have already published this set.',
          ),
        ),
      );
      return;
    }

    final published = await showPublishSetDialog(
      context,
      savedSet: widget.savedSet,
      allCards: widget.allCards,
    );

    if (!mounted || !published) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Set published successfully.'),
      ),
    );
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

  Future<void> chooseKingdomCard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardBrowserPage(
          cards: widget.allCards,
          targetSet: widget.savedSet,
          returnAfterSelection: true,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> removeCard(DominionCard card) async {
    setState(() {
      widget.savedSet.kingdomCardIds.remove(card.id);
      syncRequiredExtras(
        widget.savedSet,
        widget.allCards,
      );
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

  Future<void> removeExtra(DominionCard card) async {
    setState(() {
      widget.savedSet.extras.removeWhere(
        (extra) => extra.cardId == card.id,
      );

      syncRequiredExtras(
        widget.savedSet,
        widget.allCards,
      );
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

  List<Widget> buildRequiredSetupItems(
    Set<String> requiredSetupItems, {
    bool groupSpiritCards = false,
  }) {
    final widgets = <Widget>[];
    final handledItems = <String>{};

    if (requiredSetupItems.contains('Boons')) {
      final children = <String>[];

      if (requiredSetupItems.contains('Will-o\'-Wisp pile')) {
        if (!groupSpiritCards) {
          children.add('Will-o\'-Wisp');
        }

        handledItems.add('Will-o\'-Wisp pile');
      }

      if (children.isEmpty) {
        // No children to show, so Boons is just a normal required item.
        widgets.add(
          const Card(
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Boons'),
              subtitle: Text('Required for this setup'),
              trailing: Text('Required'),
            ),
          ),
        );
      } else {
        // There are children, so Boons can be expanded.
        widgets.add(
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Boons'),
              subtitle: const Text('Required for this setup'),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Required'),
                  SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                ],
              ),
              children: [
                for (final child in children)
                  Builder(
                    builder: (context) {
                      DominionCard? childCard;

                      for (final card in widget.allCards) {
                        if (card.name == child) {
                          childCard = card;
                          break;
                        }
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 56,
                          right: 16,
                        ),
                        leading: const Icon(
                          Icons.subdirectory_arrow_right,
                          size: 18,
                        ),
                        title: Text(child),
                        trailing: childCard != null
                            ? const Icon(
                                Icons.info_outline,
                                size: 18,
                              )
                            : null,
                        onTap: childCard == null
                            ? null
                            : () {
                                showCardInfoDialog(
                                  context,
                                  childCard!,
                                );
                              },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }

      handledItems.add('Boons');
    }

    // Doom setup
    if (requiredSetupItems.contains('Hexes')) {
      final children = <String>[];

      if (requiredSetupItems.contains('Deluded / Envious')) {
        children.add('Deluded');
        children.add('Envious');
        handledItems.add('Deluded / Envious');
      }

      if (requiredSetupItems.contains(
        'Miserable / Twice Miserable',
      )) {
        children.add('Miserable');
        children.add('Twice Miserable');
        handledItems.add('Miserable / Twice Miserable');
      }

      widgets.add(
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Hexes'),
            subtitle: const Text('Required for this setup'),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Required'),
                SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                ),
              ],
            ),
            children: [
              for (final child in children)
                Builder(
                  builder: (context) {
                    DominionCard? childCard;

                    for (final card in widget.allCards) {
                      if (card.name == child) {
                        childCard = card;
                        break;
                      }
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 56,
                        right: 16,
                      ),
                      leading: const Icon(
                        Icons.subdirectory_arrow_right,
                        size: 18,
                      ),
                      title: Text(child),
                      trailing: childCard != null
                          ? const Icon(
                              Icons.info_outline,
                              size: 18,
                            )
                          : null,
                      onTap: childCard == null
                          ? null
                          : () {
                              showCardInfoDialog(
                                context,
                                childCard!,
                              );
                            },
                    );
                  },
                ),
            ],
          ),
        ),
      );

      handledItems.add('Hexes');
    }

    // Everything that isn't part of a group,
    // e.g. Ruins pile.
    for (final setupItem in requiredSetupItems) {
      if (handledItems.contains(setupItem)) {
        continue;
      }

      widgets.add(
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(setupItem),
            subtitle: const Text('Required for this setup'),
            trailing: const Text('Required'),
          ),
        ),
      );
    }

    return widgets;
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

    final automaticSpiritCards = extraCards.where((card) {
      final savedExtra = widget.savedSet.extras.firstWhere(
        (extra) => extra.cardId == card.id,
      );

      return savedExtra.isAutomatic &&
          card.types.contains('Spirit');
    }).toList();

    final groupSpiritCards = automaticSpiritCards.length > 1;

    final automaticZombieCards = extraCards.where((card) {
      final savedExtra = widget.savedSet.extras.firstWhere(
        (extra) => extra.cardId == card.id,
      );

      return savedExtra.isAutomatic &&
          card.types.contains('Zombie');
    }).toList();

    final groupZombieCards = automaticZombieCards.length > 1;

    sortCards(
      kingdomCards,
      selectedSort,
    );

    final missingRequiredTypes = getMissingRequiredTypes(
      widget.savedSet,
      widget.allCards,
    );

    final dependencySourceIds = <String>{
      ...widget.savedSet.kingdomCardIds,
      ...widget.savedSet.extras.map((extra) => extra.cardId),
    };

    final dependencyRequirements = getDependencyRequirements(
      dependencySourceIds,
      widget.allCards,
    );

    final requiredSetupItems =
        dependencyRequirements.setupItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.savedSet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'Publish set',
            onPressed: publishSet,
          ),
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
                            onTap: chooseKingdomCard,
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
                            final pile = getKingdomPileForCard(card.id);

                            if (pile != null &&
                                card.id == pile.representativeCardId) {
                              showKingdomPileDialog(
                                context,
                                pileCard: card,
                                allCards: widget.allCards,
                              );
                              return;
                            }

                            showCardInfoDialog(
                              context,
                              card,
                            );
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

                if (extraCards.isNotEmpty ||
                  missingRequiredTypes.isNotEmpty ||
                  requiredSetupItems.isNotEmpty) ...[
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

                  ...buildRequiredSetupItems(
                    requiredSetupItems,
                    groupSpiritCards: groupSpiritCards,
                  ),

                  if (groupSpiritCards)
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Spirits pile'),
                        subtitle: const Text('Required for this setup'),
                        trailing: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Required'),
                            SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                          ],
                        ),
                        children: [
                          for (final spiritCard in automaticSpiritCards)
                            ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 56,
                                right: 16,
                              ),
                              leading: const Icon(
                                Icons.subdirectory_arrow_right,
                                size: 18,
                              ),
                              title: Text(spiritCard.name),
                              trailing: const Icon(
                                Icons.info_outline,
                                size: 18,
                              ),
                              onTap: () {
                                showCardInfoDialog(
                                  context,
                                  spiritCard,
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                  if (groupZombieCards)
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Zombies'),
                        subtitle: const Text('Required for this setup'),
                        trailing: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Required'),
                            SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                          ],
                        ),
                        children: [
                          for (final zombieCard in automaticZombieCards)
                            ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 56,
                                right: 16,
                              ),
                              leading: const Icon(
                                Icons.subdirectory_arrow_right,
                                size: 18,
                              ),
                              title: Text(zombieCard.name),
                              trailing: const Icon(
                                Icons.info_outline,
                                size: 18,
                              ),
                              onTap: () {
                                showCardInfoDialog(
                                  context,
                                  zombieCard,
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                  ...missingRequiredTypes.map(
                    (requiredType) => Card(
                      elevation: 0,
                      child: ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text('Choose $requiredType card'),
                        subtitle: const Text('Required for this setup'),
                        onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardBrowserPage(
                              cards: widget.allCards,
                              targetSet: widget.savedSet,
                              requiredTypeFilter: requiredType,
                              returnAfterSelection: true,
                            ),
                          ),
                        );

                        if (!mounted) return;

                        setState(() {});
                        },
                      ),
                    ),
                  ),

                  ...extraCards
                      .where(
                        (card) =>
                            (!groupSpiritCards ||
                                !automaticSpiritCards.contains(card)) &&
                            (!groupZombieCards ||
                                !automaticZombieCards.contains(card)),
                      )
                      .map(
                    (card) {
                      final savedExtra = widget.savedSet.extras.firstWhere(
                        (extra) => extra.cardId == card.id,
                      );

                      return Card(
                        child: ListTile(
                          onTap: () {
                            showCardInfoDialog(context, card);
                          },
                          title: Text(card.name),
                          subtitle: Text(
                            '${card.types.join(' • ')}\n${card.set}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (savedExtra.isAutomatic)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Text('Required'),
                                ),

                              Text(card.cost.toString()),

                              if (!savedExtra.isAutomatic) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Remove extra',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    removeExtra(card);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
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