import 'saved_set.dart';

class CommunitySet {
  final String id;
  final String name;
  final List<String> kingdomCardIds;
  final List<SavedExtra> extras;
  final List<String> expansions;
  final List<String> tags;
  final String? description;
  final String authorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double averageRating;
  final int ratingCount;

  const CommunitySet({
    required this.id,
    required this.name,
    required this.kingdomCardIds,
    required this.extras,
    required this.expansions,
    required this.tags,
    required this.description,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
    this.averageRating = 0,
    this.ratingCount = 0,
  });

  factory CommunitySet.fromJson(Map<String, dynamic> json) {
    return CommunitySet(
      id: json['id'] as String,
      name: json['name'] as String,
      kingdomCardIds: List<String>.from(
        json['kingdom_card_ids'] ?? [],
      ),
      extras: (json['extras'] as List<dynamic>? ?? [])
          .map(
            (extra) => SavedExtra.fromJson(
              extra as Map<String, dynamic>,
            ),
          )
          .toList(),
      expansions: List<String>.from(
        json['expansions'] ?? [],
      ),
      tags: List<String>.from(
        json['tags'] ?? [],
      ),
      description: json['description'] as String?,
      authorId: json['author_id'] as String,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String,
      ),
      averageRating:
          (json['average_rating'] as num?)?.toDouble() ?? 0,
      ratingCount:
          (json['rating_count'] as num?)?.toInt() ?? 0,
    );
  }
}