import 'package:flutter/material.dart';

import '../data/extra_sync.dart';
import '../models/community_set.dart';
import '../models/dominion_card.dart';
import '../models/saved_set.dart';
import '../widgets/card_info_dialog.dart';
import '../widgets/kingdom_pile_dialog.dart';
import '../data/kingdom_piles.dart';
import '../data/card_dependencies.dart';
import '../data/saved_sets_repository.dart';
import '../data/set_ratings_repository.dart';

class CommunitySetDetailPage extends StatefulWidget {
  final CommunitySet communitySet;
  final List<DominionCard> allCards;

  const CommunitySetDetailPage({
    super.key,
    required this.communitySet,
    required this.allCards,
  });

  @override
  State<CommunitySetDetailPage> createState() =>
      _CommunitySetDetailPageState();
}


class _CommunitySetDetailPageState
    extends State<CommunitySetDetailPage> {
  final SetRatingsRepository _ratingsRepository =
      SetRatingsRepository();

  late Future<SetRatingSummary> _ratingFuture;

  @override
  void initState() {
    super.initState();

    _ratingFuture = _ratingsRepository.getRatingSummary(
      widget.communitySet.id,
    );
  }

  void refreshRating() {
    setState(() {
      _ratingFuture = _ratingsRepository.getRatingSummary(
        widget.communitySet.id,
      );
    });
  }

  SavedSet buildDisplaySet() {
    final displaySet = SavedSet(
      id: widget.communitySet.id,
      name: widget.communitySet.name,
      kingdomCardIds: List<String>.from(
        widget.communitySet.kingdomCardIds,
      ),
      extras: widget.communitySet.extras
          .map(
            (extra) => SavedExtra(
              cardId: extra.cardId,
              targetCardId: extra.targetCardId,
              isAutomatic: false,
            ),
          )
          .toList(),
    );

    syncRequiredExtras(
      displaySet,
      widget.allCards,
    );

    return displaySet;
  }

  bool _sameStringLists(
    List<String> a,
    List<String> b,
  ) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  Future<void> saveToMySets(BuildContext context) async {
    final repository = SavedSetRepository();

    final savedSets = await repository.loadSets();

    final communityKingdomIds =
        List<String>.from(widget.communitySet.kingdomCardIds)..sort();

    final communityManualExtraIds = widget.communitySet.extras
        .map(
          (extra) =>
              '${extra.cardId}|${extra.targetCardId ?? ''}',
        )
        .toList()
      ..sort();

    final alreadySaved = savedSets.any((savedSet) {
      final savedKingdomIds =
          List<String>.from(savedSet.kingdomCardIds)..sort();

      final savedManualExtraIds = savedSet.extras
          .where((extra) => !extra.isAutomatic)
          .map(
            (extra) =>
                '${extra.cardId}|${extra.targetCardId ?? ''}',
          )
          .toList()
        ..sort();

      return _sameStringLists(
            communityKingdomIds,
            savedKingdomIds,
          ) &&
          _sameStringLists(
            communityManualExtraIds,
            savedManualExtraIds,
          );
    });

    if (alreadySaved) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This set is already saved.',
          ),
        ),
      );

      return;
    }

    final newSet = SavedSet(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      name: widget.communitySet.name,
      kingdomCardIds: List<String>.from(
        widget.communitySet.kingdomCardIds,
      ),
      extras: widget.communitySet.extras
          .map(
            (extra) => SavedExtra(
              cardId: extra.cardId,
              targetCardId: extra.targetCardId,
              isAutomatic: false,
            ),
          )
          .toList(),
    );

    syncRequiredExtras(
      newSet,
      widget.allCards,
    );

    savedSets.add(newSet);

    await repository.saveSets(savedSets);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${widget.communitySet.name}" saved to My Sets.',
        ),
      ),
    );
  }

  DominionCard? findCard(String cardId) {
    for (final card in widget.allCards) {
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

  Future<void> setRating(int rating) async {
    await _ratingsRepository.setRating(
      widget.communitySet.id,
      rating,
    );

    refreshRating();
  }

  @override
  Widget build(BuildContext context) {
    final displaySet = buildDisplaySet();

    final kingdomCards = displaySet.kingdomCardIds
        .map(findCard)
        .whereType<DominionCard>()
        .toList();

    final extraCards = displaySet.extras
        .map((extra) => findCard(extra.cardId))
        .whereType<DominionCard>()
        .toList();

    final automaticSpiritCards = extraCards.where((card) {
      final savedExtra = displaySet.extras.firstWhere(
        (extra) => extra.cardId == card.id,
      );

      return savedExtra.isAutomatic &&
          card.types.contains('Spirit');
    }).toList();

    final groupSpiritCards =
        automaticSpiritCards.length > 1;

    final automaticZombieCards = extraCards.where((card) {
      final savedExtra = displaySet.extras.firstWhere(
        (extra) => extra.cardId == card.id,
      );

      return savedExtra.isAutomatic &&
          card.types.contains('Zombie');
    }).toList();

    final groupZombieCards =
        automaticZombieCards.length > 1;

    final missingRequiredTypes = getMissingRequiredTypes(
      displaySet,
      widget.allCards,
    );

    final dependencySourceIds = <String>{
      ...displaySet.kingdomCardIds,
      ...displaySet.extras.map(
        (extra) => extra.cardId,
      ),
    };

    final dependencyRequirements =
        getDependencyRequirements(
      dependencySourceIds,
      widget.allCards,
    );

    final requiredSetupItems =
        dependencyRequirements.setupItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communitySet.name),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_add_outlined,
            ),
            tooltip: 'Save to My Sets',
            onPressed: () {
              saveToMySets(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.communitySet.expansions.isNotEmpty) ...[
            Text(
              widget.communitySet.expansions.join(' • '),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 8),
          ],

          if (widget.communitySet.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag
                    in widget.communitySet.tags)
                  Chip(
                    label: Text(tag),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (widget.communitySet.description != null &&
              widget.communitySet.description!
                  .trim()
                  .isNotEmpty) ...[
            Text(
              widget.communitySet.description!,
              style:
                  Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],

          FutureBuilder<SetRatingSummary>(
            future: _ratingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final summary = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              i <= (summary.userRating ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                            ),
                            tooltip: '$i star${i == 1 ? '' : 's'}',
                            onPressed: () {
                              setRating(i);
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      summary.count == 0
                          ? 'No ratings yet'
                          : '${summary.average.toStringAsFixed(1)} / 5 '
                            '(${summary.count} rating${summary.count == 1 ? '' : 's'})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),

          Text(
            'Kingdom',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          for (final card in kingdomCards)
            Card(
              child: ListTile(
                title: Text(card.name),
                subtitle: Text(
                  '${card.types.join(' • ')}\n'
                  '${card.set} • ${card.cost}',
                ),
                trailing: const Icon(
                  Icons.info_outline,
                ),
                onTap: () {
                  final pile = getKingdomPileForCard(
                    card.id,
                  );

                  if (pile != null &&
                      card.id ==
                          pile.representativeCardId) {
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
              ),
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
              context,
              requiredSetupItems,
              groupSpiritCards: groupSpiritCards,
            ),

            if (groupSpiritCards)
              Card(
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                  ),
                  title: const Text('Spirits pile'),
                  subtitle: const Text(
                    'Required for this setup',
                  ),
                  children: [
                    for (final spiritCard
                        in automaticSpiritCards)
                      ListTile(
                        contentPadding:
                            const EdgeInsets.only(
                          left: 56,
                          right: 16,
                        ),
                        title: Text(
                          spiritCard.name,
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
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                  ),
                  title: const Text('Zombies'),
                  subtitle: const Text(
                    'Required for this setup',
                  ),
                  children: [
                    for (final zombieCard
                        in automaticZombieCards)
                      ListTile(
                        contentPadding:
                            const EdgeInsets.only(
                          left: 56,
                          right: 16,
                        ),
                        title: Text(
                          zombieCard.name,
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

            for (final card in extraCards.where(
              (card) =>
                  (!groupSpiritCards ||
                      !automaticSpiritCards
                          .contains(card)) &&
                  (!groupZombieCards ||
                      !automaticZombieCards
                          .contains(card)),
            ))
              Card(
                child: ListTile(
                  title: Text(card.name),
                  subtitle: Text(
                    '${card.types.join(' • ')}\n'
                    '${card.set} • ${card.cost}',
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
        ],
      ),
    );
  }
}
    