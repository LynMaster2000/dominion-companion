class SavedExtra {
  final String cardId;
  final String? targetCardId;
  final bool isAutomatic;

  SavedExtra({
    required this.cardId,
    this.targetCardId,
    this.isAutomatic = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'targetCardId': targetCardId,
      'isAutomatic': isAutomatic,
    };
  }

  factory SavedExtra.fromJson(Map<String, dynamic> json) {
    return SavedExtra(
      cardId: json['cardId'] as String,
      targetCardId: json['targetCardId'] as String?,
      isAutomatic: json['isAutomatic'] as bool? ?? false,
    );
  }
}

class SavedSet {
  final String id;
  String name;
  List<String> kingdomCardIds;
  List<SavedExtra> extras;

  SavedSet({
    required this.id,
    required this.name,
    required this.kingdomCardIds,
    this.extras = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kingdomCardIds': kingdomCardIds,
      'extras': extras.map((extra) => extra.toJson()).toList(),
    };
  }

  factory SavedSet.fromJson(Map<String, dynamic> json) {
    return SavedSet(
      id: json['id'] as String,
      name: json['name'] as String,
      kingdomCardIds: List<String>.from(
        json['kingdomCardIds'] ?? [],
      ),
      extras: (json['extras'] as List<dynamic>? ?? [])
          .map(
            (extra) => SavedExtra.fromJson(
              extra as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}