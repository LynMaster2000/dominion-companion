import 'package:flutter/material.dart';

import '../data/kingdom_piles.dart';
import '../models/dominion_card.dart';
import 'card_info_dialog.dart';

Future<void> showKingdomPileDialog(
  BuildContext context, {
  required DominionCard pileCard,
  required List<DominionCard> allCards,
}) {
  final pile = getKingdomPileForCard(pileCard.id);

  if (pile == null) {
    return showCardInfoDialog(
      context,
      pileCard,
    );
  }

  final pileCards = <DominionCard>[];

  for (final cardId in pile.cardIds) {
    for (final card in allCards) {
      if (card.id == cardId) {
        pileCards.add(card);
        break;
      }
    }
  }

  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(pileCard.name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pileCard.instructions,
                ),

                const SizedBox(height: 16),

                Text(
                  'Cards in this pile',
                  style: Theme.of(context).textTheme.titleSmall,
                ),

                const SizedBox(height: 8),

                for (final card in pileCards)
                  Card(
                    child: ListTile(
                      title: Text(card.name),
                      subtitle: Text(
                        '${card.types.join(' • ')}\n${card.cost}',
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
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}