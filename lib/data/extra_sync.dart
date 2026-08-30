import '../models/saved_set.dart';
import 'card_dependencies.dart';
import '../models/dominion_card.dart';

void syncRequiredExtras(
  SavedSet savedSet,
  List<DominionCard> allCards,
) {
  final dependencySourceIds = <String>{
    ...savedSet.kingdomCardIds,
    ...savedSet.extras.map((extra) => extra.cardId),
  };

  final requirements = getDependencyRequirements(
    dependencySourceIds,
    allCards,
  );

final requiredExtraIds = requirements.cardIds;

  final manualExtraIds = savedSet.extras
      .where((extra) => !extra.isAutomatic)
      .map((extra) => extra.cardId)
      .toSet();

  final automaticExtras = requiredExtraIds
      .where((cardId) => !manualExtraIds.contains(cardId))
      .map(
        (cardId) => SavedExtra(
          cardId: cardId,
          isAutomatic: true,
        ),
      )
      .toList();

  final manualExtras = savedSet.extras
      .where((extra) => !extra.isAutomatic)
      .toList();

  savedSet.extras = [
    ...manualExtras,
    ...automaticExtras,
  ];
}

Set<String> getMissingRequiredTypes(
  SavedSet savedSet,
  List<DominionCard> allCards,
) {
  final dependencySourceIds = <String>{
    ...savedSet.kingdomCardIds,
    ...savedSet.extras.map((extra) => extra.cardId),
  };

  final requirements = getDependencyRequirements(
    dependencySourceIds,
    allCards,
  );

  final extraCards = savedSet.extras
      .map(
        (extra) => allCards.firstWhere(
          (card) => card.id == extra.cardId,
        ),
      )
      .toList();

  return requirements.types.where((requiredType) {
    return !extraCards.any(
      (card) => card.types.contains(requiredType),
    );
  }).toSet();
}