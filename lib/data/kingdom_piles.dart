class KingdomPileDefinition {
  final String name;
  final String representativeCardId;
  final List<String> cardIds;

  const KingdomPileDefinition({
    required this.name,
    required this.representativeCardId,
    required this.cardIds,
  });

  bool containsCard(String cardId) =>
      cardId == representativeCardId ||
      cardIds.contains(cardId);
}

const List<KingdomPileDefinition> kingdomPileDefinitions = [
  KingdomPileDefinition(
    name: 'Augurs',
    representativeCardId: 'Allies::Augurs',
    cardIds: [
      'Allies::Herb Gatherer',
      'Allies::Acolyte',
      'Allies::Sorceress',
      'Allies::Sibyl',
    ],
  ),

  KingdomPileDefinition(
    name: 'Clashes',
    representativeCardId: 'Allies::Clashes',
    cardIds: [
      'Allies::Battle Plan',
      'Allies::Archer',
      'Allies::Warlord',
      'Allies::Territory',
    ],
  ),

  KingdomPileDefinition(
    name: 'Forts',
    representativeCardId: 'Allies::Forts',
    cardIds: [
      'Allies::Tent',
      'Allies::Garrison',
      'Allies::Hill Fort',
      'Allies::Stronghold',
    ],
  ),

  KingdomPileDefinition(
    name: 'Odysseys',
    representativeCardId: 'Allies::Odysseys',
    cardIds: [
      'Allies::Old Map',
      'Allies::Voyage',
      'Allies::Sunken Treasure',
      'Allies::Distant Shore',
    ],
  ),

  KingdomPileDefinition(
    name: 'Townsfolk',
    representativeCardId: 'Allies::Townsfolk',
    cardIds: [
      'Allies::Town Crier',
      'Allies::Blacksmith',
      'Allies::Miller',
      'Allies::Elder',
    ],
  ),

  KingdomPileDefinition(
    name: 'Wizards',
    representativeCardId: 'Allies::Wizards',
    cardIds: [
      'Allies::Student',
      'Allies::Conjurer',
      'Allies::Sorcerer',
      'Allies::Lich',
    ],
  ),
];

KingdomPileDefinition? getKingdomPileForCard(
  String cardId,
) {
  for (final pile in kingdomPileDefinitions) {
    if (pile.containsCard(cardId)) {
      return pile;
    }
  }

  return null;
}