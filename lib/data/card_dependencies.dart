import '../models/dominion_card.dart';

enum DependencyKind {
  card,
  type,
  setup,
}

class TypeDependencyRule {
  final String triggerType;
  final List<CardDependency> dependencies;

  const TypeDependencyRule({
    required this.triggerType,
    required this.dependencies,
  });
}

class CardDependency {
  final DependencyKind kind;
  final String value;

  const CardDependency.card(String cardId)
      : kind = DependencyKind.card,
        value = cardId;

  const CardDependency.type(String type)
      : kind = DependencyKind.type,
        value = type;

  const CardDependency.setup(String name)
    : kind = DependencyKind.setup,
      value = name;

}

final List<TypeDependencyRule> typeDependencyRules = [
  TypeDependencyRule(
    triggerType: 'Liaison',
    dependencies: [
      CardDependency.type('Ally'),
    ],
  ),

  TypeDependencyRule(
    triggerType: 'Omen',
    dependencies: [
      CardDependency.type('Prophecy'),
    ],
  ),

  TypeDependencyRule(
    triggerType: 'Looter',
    dependencies: [
      CardDependency.setup('Ruins pile'),
    ],
  ),

  TypeDependencyRule(
    triggerType: 'Fate',
    dependencies: [
      CardDependency.setup('Boons'),
      CardDependency.setup('Will-o\'-Wisp pile'),
    ],
  ),

  TypeDependencyRule(
    triggerType: 'Doom',
    dependencies: [
      CardDependency.setup('Hexes'),
      CardDependency.setup('Deluded / Envious'),
      CardDependency.setup('Miserable / Twice Miserable'),
    ],
  ),
];

final Map<String, List<CardDependency>> cardDependencies = {
  // Menagerie — Horse
  'Menagerie::Cavalry': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Groom': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Hostelry': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Livery': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Paddock': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Scrap': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Sleigh': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Supplies': [
    CardDependency.card('Menagerie::Horse'),
  ],

  // Menagerie Events — Horse
  'Menagerie::Bargain': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Demand': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Ride': [
    CardDependency.card('Menagerie::Horse'),
  ],
  'Menagerie::Stampede': [
    CardDependency.card('Menagerie::Horse'),
  ],

  // Dark Ages — other special cards
  'Dark Ages::Marauder': [
    CardDependency.card('Dark Ages::Spoils'),
  ],
  'Dark Ages::Bandit Camp': [
    CardDependency.card('Dark Ages::Spoils'),
  ],
  'Dark Ages::Pillage': [
    CardDependency.card('Dark Ages::Spoils'),
  ],
  'Dark Ages::Urchin': [
    CardDependency.card('Dark Ages::Mercenary'),
  ],
  'Dark Ages::Hermit': [
    CardDependency.card('Dark Ages::Madman'),
  ],

  // Nocturne — special cards/piles
  'Nocturne::Devil\'s Workshop': [
    CardDependency.card('Nocturne::Imp'),
  ],

  'Nocturne::Tormentor': [
    CardDependency.card('Nocturne::Imp'),
  ],

  'Nocturne::Vampire': [
    CardDependency.card('Nocturne::Bat'),
  ],

  'Nocturne::Leprechaun': [
    CardDependency.card('Nocturne::Wish'),
  ],

  'Nocturne::Exorcist': [
    CardDependency.card('Nocturne::Will-o\'-Wisp'),
    CardDependency.card('Nocturne::Imp'),
    CardDependency.card('Nocturne::Ghost'),
  ],

  'Nocturne::Fool': [
    CardDependency.card('Nocturne::Lost in the Woods'),
  ],

  'Nocturne::Necromancer': [
    CardDependency.card('Nocturne::Zombie Apprentice'),
    CardDependency.card('Nocturne::Zombie Mason'),
    CardDependency.card('Nocturne::Zombie Spy'),
  ],

  // Nocturne — more special cards/piles
  'Nocturne::Druid': [
    CardDependency.setup('3 set-aside Boons'),
  ],

  'Nocturne::Cemetery': [
    CardDependency.card('Nocturne::Haunted Mirror'),
  ],

  'Nocturne::Pixie': [
    CardDependency.card('Nocturne::Goat'),
  ],

  'Nocturne::Pooka': [
    CardDependency.card('Nocturne::Cursed Gold'),
  ],

  'Nocturne::Secret Cave': [
    CardDependency.card('Nocturne::Magic Lamp'),
  ],

  'Nocturne::Shepherd': [
    CardDependency.card('Nocturne::Pasture'),
  ],

  'Nocturne::Tracker': [
    CardDependency.card('Nocturne::Pouch'),
  ],
};

class DependencyRequirements {
  final Set<String> cardIds;
  final Set<String> types;
  final Set<String> setupItems;

  const DependencyRequirements({
    required this.cardIds,
    required this.types,
    required this.setupItems,
  });
}

DependencyRequirements getDependencyRequirements(
  Iterable<String> sourceCardIds,
  List<DominionCard> allCards,
) {
  final requiredCardIds = <String>{};
  final requiredTypes = <String>{};
  final requiredSetupItems = <String>{};

  for (final sourceCardId in sourceCardIds) {
    final dependencies = cardDependencies[sourceCardId];

    if (dependencies == null) {
      continue;
    }

    for (final dependency in dependencies) {
      switch (dependency.kind) {
        case DependencyKind.card:
          requiredCardIds.add(dependency.value);

        case DependencyKind.type:
          requiredTypes.add(dependency.value);

        case DependencyKind.setup:
          requiredSetupItems.add(dependency.value);
      }
    }
  }

  for (final sourceCardId in sourceCardIds) {
    final sourceCard = allCards.where(
      (card) => card.id == sourceCardId,
    ).firstOrNull;

    if (sourceCard == null) {
      continue;
    } 

    // Plunder: any card that refers to Loot requires
    // the shared Loot pile.
    if (!sourceCard.types.contains('Loot') &&
        RegExp(r'\bLoot\b').hasMatch(sourceCard.instructions)) {
      requiredSetupItems.add('Loot pile');
    }

    for (final rule in typeDependencyRules) {
      if (!sourceCard.types.contains(rule.triggerType)) {
        continue;
      }

      for (final dependency in rule.dependencies) {
        switch (dependency.kind) {
          case DependencyKind.card:
            requiredCardIds.add(dependency.value);

          case DependencyKind.type:
            requiredTypes.add(dependency.value);

          case DependencyKind.setup:
            requiredSetupItems.add(dependency.value);
        }
      }
    }
  }

  return DependencyRequirements(
    cardIds: requiredCardIds,
    types: requiredTypes,
    setupItems: requiredSetupItems,
  );
}