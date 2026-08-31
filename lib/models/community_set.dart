class CommunitySet {
  final String id;
  final String name;
  final List<String> kingdomCardIds;
  final List<String> extraCardIds;
  final DateTime createdAt;

  const CommunitySet({
    required this.id,
    required this.name,
    required this.kingdomCardIds,
    required this.extraCardIds,
    required this.createdAt,
  });

  factory CommunitySet.fromJson(Map<String, dynamic> json) {
    return CommunitySet(
      id: json['id'] as String,
      name: json['name'] as String,
      kingdomCardIds: List<String>.from(
        json['kingdom_card_ids'] ?? [],
      ),
      extraCardIds: List<String>.from(
        json['extra_card_ids'] ?? [],
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
    );
  }
}