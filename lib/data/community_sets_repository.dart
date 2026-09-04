import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_set.dart';
import '../models/dominion_card.dart';
import '../models/saved_set.dart';
import '../models/community_filter.dart';

class CommunitySetAlreadyPublishedException implements Exception {
  const CommunitySetAlreadyPublishedException();

  @override
  String toString() {
    return 'You have already published this set.';
  }
}

class CommunitySetsRepository {
  final SupabaseClient _client;

  CommunitySetsRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  Future<List<CommunitySet>> getCommunitySets(
    CommunityFilter filter,
  ) async {
    var baseQuery = _client
        .from('community_sets_with_ratings')
        .select();

    if (filter.expansions.isNotEmpty) {
      baseQuery = baseQuery.contains(
        'expansions',
        filter.expansions.toList(),
      );
    }

    if (filter.tags.isNotEmpty) {
      baseQuery = baseQuery.contains(
        'tags',
        filter.tags.toList(),
      );
    }

    late final List<dynamic> response;

    switch (filter.sort) {
      case CommunitySort.newest:
        response = await baseQuery.order(
          'created_at',
          ascending: false,
        );
        break;

      case CommunitySort.oldest:
        response = await baseQuery.order(
          'created_at',
          ascending: true,
        );
        break;

      case CommunitySort.alphabetical:
        response = await baseQuery.order(
          'name',
          ascending: true,
        );
        break;

      case CommunitySort.highestRated:
        response = await baseQuery
            .order(
              'average_rating',
              ascending: false,
            )
            .order(
              'rating_count',
              ascending: false,
            )
            .order(
              'created_at',
              ascending: false,
            );
        break;

      case CommunitySort.mostRated:
        response = await baseQuery
            .order(
              'rating_count',
              ascending: false,
            )
            .order(
              'average_rating',
              ascending: false,
            )
            .order(
              'created_at',
              ascending: false,
            );
        break;
    }

    return response
        .map(
          (json) => CommunitySet.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> deletePublishedSet(String setId) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be signed in to delete a published set.');
    }

    await Supabase.instance.client
        .from('community_sets')
        .delete()
        .eq('id', setId)
        .eq('author_id', user.id);
  }

  Future<List<CommunitySet>> getMyPublishedSets() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return [];
    }

    final rows = await Supabase.instance.client
        .from('community_sets_with_ratings')
        .select()
        .eq('author_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => CommunitySet.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<bool> hasAlreadyPublished(
    SavedSet savedSet,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return false;
    }

    final manualExtras = savedSet.extras
        .where((extra) => !extra.isAutomatic)
        .toList();

    final existingRows = await _client
        .from('community_sets')
        .select('kingdom_card_ids, extras')
        .eq('author_id', user.id);

    final kingdomIds = _normalizedKingdomIds(
      savedSet.kingdomCardIds,
    );

    final extraIds = _normalizedExtras(
      manualExtras,
    );

    for (final row in existingRows) {
      final existingKingdomIds = _normalizedKingdomIds(
        List<String>.from(
          row['kingdom_card_ids'] ?? [],
        ),
      );

      final existingExtras =
          (row['extras'] as List<dynamic>? ?? [])
              .map(
                (json) => SavedExtra.fromJson(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();

      final existingExtraIds = _normalizedExtras(
        existingExtras,
      );

      if (_sameStringLists(
            kingdomIds,
            existingKingdomIds,
          ) &&
          _sameStringLists(
            extraIds,
            existingExtraIds,
          )) {
        return true;
      }
    }

    return false;
  }

  List<String> _normalizedKingdomIds(
    Iterable<String> ids,
  ) {
    final result = ids.toList()..sort();
    return result;
  }

  List<String> _normalizedExtras(
    Iterable<SavedExtra> extras,
  ) {
    final result = extras
        .map(
          (extra) =>
              '${extra.cardId}|${extra.targetCardId ?? ''}',
        )
        .toList()
      ..sort();

    return result;
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

  Future<void> publishSet(
    SavedSet savedSet,
    List<DominionCard> allCards, {
    String? description,
    List<String> tags = const [],
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be signed in to publish a set.');
    }

    if (tags.length > 5) {
      throw Exception('A set can have at most 5 tags.');
    }

    // Automatic extras are derived from the setup and do not need
    // to be stored as part of the published set.
    final manualExtras = savedSet.extras
        .where((extra) => !extra.isAutomatic)
        .toList();

    if (await hasAlreadyPublished(savedSet)) {
      throw const CommunitySetAlreadyPublishedException();
    }

    final publishedExtras = manualExtras
        .map(
          (extra) => {
            'cardId': extra.cardId,
            'targetCardId': extra.targetCardId,
          },
        )
        .toList();

    // Determine expansions from the actual cards being published.
    final publishedCardIds = <String>{
      ...savedSet.kingdomCardIds,
      ...manualExtras.map((extra) => extra.cardId),
    };

    final expansions = allCards
        .where((card) => publishedCardIds.contains(card.id))
        .map((card) => card.set)
        .toSet()
        .toList()
      ..sort();

    await _client.from('community_sets').insert({
      'name': savedSet.name,
      'kingdom_card_ids': savedSet.kingdomCardIds,
      'extras': publishedExtras,
      'expansions': expansions,
      'tags': tags,
      'description': description,
      'author_id': user.id,
    });
  }
}