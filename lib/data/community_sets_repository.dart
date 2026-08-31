import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_set.dart';
import '../models/dominion_card.dart';
import '../models/saved_set.dart';

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

  Future<List<CommunitySet>> getCommunitySets() async {
    final response = await _client
        .from('community_sets')
        .select()
        .order('created_at', ascending: false);

    return response
        .map(
          (json) => CommunitySet.fromJson(
            json,
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