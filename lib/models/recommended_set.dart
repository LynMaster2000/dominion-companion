class RecommendedTrait {
  final String traitCardId;
  final String targetCardId;

  const RecommendedTrait({
    required this.traitCardId,
    required this.targetCardId,
  });

  factory RecommendedTrait.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendedTrait(
      traitCardId: json['traitCardId'] as String,
      targetCardId: json['targetCardId'] as String,
    );
  }
}

class RecommendedSet {
  final String name;
  final List<String> kingdomCardIds;
  final List<String> extraCardIds;
  final List<String> expansions;
  final List<RecommendedTrait> traits;
  final String? note;

  const RecommendedSet({
    required this.name,
    required this.kingdomCardIds,
    this.extraCardIds = const [],
    required this.expansions,
    this.traits = const [],
    this.note,
  });

  factory RecommendedSet.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendedSet(
      name: json['name'] as String,

      kingdomCardIds: List<String>.from(
        json['kingdomCardIds'] ?? [],
      ),

      extraCardIds: List<String>.from(
        json['extraCardIds'] ?? [],
      ),

      expansions: List<String>.from(
        json['expansions'] ?? [],
      ),

      traits: (json['traits'] as List<dynamic>? ?? [])
          .map(
            (trait) => RecommendedTrait.fromJson(
              trait as Map<String, dynamic>,
            ),
          )
          .toList(),

      note: json['note'] as String?,
    );
  }
}