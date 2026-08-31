import '../models/recommended_set.dart';

const List<RecommendedSet> recommendedSets = [
  RecommendedSet(
    name: 'Basic Intro',
    expansions: ['Empires'],
    kingdomCardIds: [
      'Empires::Castles',
      'Empires::Chariot Race',
      'Empires::City Quarter',
      'Empires::Engineer',
      'Empires::Farmers\' Market',
      'Empires::Forum',
      'Empires::Legionary',
      'Empires::Patrician/Emporium',
      'Empires::Sacrifice',
      'Empires::Villa',
    ],
    extraCardIds: [
      'Empires::Tower',
      'Empires::Wedding',
    ],
  ),

  RecommendedSet(
    name: 'Advanced Intro',
    expansions: ['Empires'],
    kingdomCardIds: [
      'Empires::Archive',
      'Empires::Capital',
      'Empires::Catapult/Rocks',
      'Empires::Crown',
      'Empires::Enchantress',
      'Empires::Gladiator/Fortune',
      'Empires::Groundskeeper',
      'Empires::Royal Blacksmith',
      'Empires::Settlers/Bustling Village',
      'Empires::Temple',
    ],
    extraCardIds: [
      'Empires::Arena',
      'Empires::Triumphal Arch',
    ],
  ),
];