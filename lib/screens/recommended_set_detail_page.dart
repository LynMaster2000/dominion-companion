import 'package:flutter/material.dart';

import '../models/dominion_card.dart';
import '../models/recommended_set.dart';
import '../widgets/card_info_dialog.dart';
import '../widgets/kingdom_pile_dialog.dart';
import '../data/kingdom_piles.dart';
import '../data/card_dependencies.dart';

class RecommendedSetDetailPage extends StatelessWidget {
  final RecommendedSet recommendedSet;
  final List<DominionCard> allCards;

  const RecommendedSetDetailPage({
    super.key,
    required this.recommendedSet,
    required this.allCards,
  });

  DominionCard? findCard(String cardId) {
    for (final card in allCards) {
      if (card.id == cardId) {
        return card;
      }
    }

    return null;
  }

  List<Widget> buildRequiredSetupItems(
    BuildContext context,
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
                      final childCard = allCards
                          .where((card) => card.name == child)
                          .firstOrNull;

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
                                  childCard,
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
                    final childCard = allCards
                        .where((card) => card.name == child)
                        .firstOrNull;

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
                                childCard,
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
    final kingdomCards = recommendedSet.kingdomCardIds
        .map(findCard)
        .whereType<DominionCard>()
        .toList();

    final extraCards = recommendedSet.extraCardIds
        .map(findCard)
        .whereType<DominionCard>()
        .toList();

    final druidBoons = extraCards
        .where((card) => card.types.contains('Boon'))
        .toList();

    final hasDruidBoons = druidBoons.isNotEmpty;

    final dependencySourceIds = <String>{
      ...recommendedSet.kingdomCardIds,
      ...recommendedSet.extraCardIds,
      ...recommendedSet.traits.map((trait) => trait.traitCardId),
    };

    final dependencyRequirements = getDependencyRequirements(
      dependencySourceIds,
      allCards,
    );

    final existingCardIds = <String>{
      ...recommendedSet.kingdomCardIds,
      ...recommendedSet.extraCardIds,
    };

    final requiredCards = dependencyRequirements.cardIds
        .where((id) => !existingCardIds.contains(id))
        .map(findCard)
        .whereType<DominionCard>()
        .toList();

    final requiredSpiritCards = requiredCards
        .where((card) => card.types.contains('Spirit'))
        .toList();

    final groupSpiritCards = requiredSpiritCards.length > 1;

    final requiredZombieCards = requiredCards
        .where((card) => card.types.contains('Zombie'))
        .toList();

    final groupZombieCards = requiredZombieCards.length > 1;

    final existingCards = [
      ...kingdomCards,
      ...extraCards,
    ];

    final missingRequiredTypes =
        dependencyRequirements.types.where((requiredType) {
      return !existingCards.any(
        (card) => card.types.contains(requiredType),
      );
    }).toSet();

    final requiredSetupItems =
        dependencyRequirements.setupItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(recommendedSet.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            recommendedSet.expansions.join(' • '),
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          Text(
            'Kingdom',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          for (final card in kingdomCards)
            Card(
              child: ListTile(
                title: Text(card.name),
                subtitle: Text(
                  '${card.types.join(' • ')}\n${card.set} • ${card.cost}',
                ),
                trailing: const Icon(
                  Icons.info_outline,
                ),
                onTap: () {
                  final pile = getKingdomPileForCard(card.id);

                  if (pile != null &&
                      card.id == pile.representativeCardId) {
                    showKingdomPileDialog(
                      context,
                      pileCard: card,
                      allCards: allCards,
                    );
                    return;
                  }

                  showCardInfoDialog(
                    context,
                    card,
                  );
                },
              ),
            ),

          if (extraCards.isNotEmpty ||
            requiredCards.isNotEmpty ||
            requiredSetupItems.isNotEmpty ||
            missingRequiredTypes.isNotEmpty) ...[
            const SizedBox(height: 24),

            Text(
              'Extras',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            if (hasDruidBoons)
              Card(
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                  ),
                  title: const Text('Druid — Set-aside Boons'),
                  subtitle: const Text(
                    'Required for this setup',
                  ),
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
                    for (final boon in druidBoons)
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 56,
                          right: 16,
                        ),
                        leading: const Icon(
                          Icons.subdirectory_arrow_right,
                          size: 18,
                        ),
                        title: Text(boon.name),
                        trailing: const Icon(
                          Icons.info_outline,
                          size: 18,
                        ),
                        onTap: () {
                          showCardInfoDialog(
                            context,
                            boon,
                          );
                        },
                      ),
                  ],
                ),
              ),

            ...buildRequiredSetupItems(
              context,
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
                    for (final spiritCard in requiredSpiritCards)
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
                    for (final zombieCard in requiredZombieCards)
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

            for (final card in requiredCards.where(
              (card) =>
                  (!groupSpiritCards ||
                      !requiredSpiritCards.contains(card)) &&
                  (!groupZombieCards ||
                      !requiredZombieCards.contains(card)),
            ))
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                  ),
                  title: Text(card.name),
                  subtitle: Text(
                    '${card.types.join(' • ')}\n${card.set}',
                  ),
                  trailing: const Text('Required'),
                  onTap: () {
                    showCardInfoDialog(
                      context,
                      card,
                    );
                  },
                ),
              ),

            for (final requiredType in missingRequiredTypes)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_outlined,
                  ),
                  title: Text(
                    'Requires a $requiredType card',
                  ),
                  subtitle: const Text(
                    'Required for this setup',
                  ),
                  trailing: const Text('Required'),
                ),
              ),

            for (final card in extraCards.where(
              (card) => !druidBoons.contains(card),
            ))
              Card(
                child: ListTile(
                  title: Text(card.name),
                  subtitle: Text(
                    '${card.types.join(' • ')}\n${card.set} • ${card.cost}',
                  ),
                  trailing: const Icon(
                    Icons.info_outline,
                  ),
                  onTap: () {
                    showCardInfoDialog(
                      context,
                      card,
                    );
                  },
                ),
              ),
          ],

          if (recommendedSet.note != null) ...[
            const SizedBox(height: 24),

            Text(
              recommendedSet.note!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}