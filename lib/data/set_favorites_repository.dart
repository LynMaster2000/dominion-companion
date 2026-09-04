import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_set.dart';

class SetFavoritesRepository {
  final SupabaseClient _client;

  SetFavoritesRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  Future<bool> isFavorited(String setId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await _client
        .from('set_favorites')
        .select('set_id')
        .eq('set_id', setId)
        .eq('user_id', user.id)
        .maybeSingle();

    return response != null;
  }

  Future<void> addFavorite(String setId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be signed in to favorite a set.');
    }

    await _client.from('set_favorites').insert({
      'set_id': setId,
      'user_id': user.id,
    });
  }

  Future<void> removeFavorite(String setId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return;
    }

    await _client
        .from('set_favorites')
        .delete()
        .eq('set_id', setId)
        .eq('user_id', user.id);
  }

  Future<List<CommunitySet>> getFavoriteSets() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return [];
    }

    final favoriteRows = await _client
        .from('set_favorites')
        .select('set_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (favoriteRows.isEmpty) {
      return [];
    }

    final setIds = favoriteRows
        .map((row) => row['set_id'] as String)
        .toList();

    final setRows = await _client
        .from('community_sets_with_ratings')
        .select()
        .inFilter('id', setIds);

    final setsById = <String, CommunitySet>{
      for (final row in setRows)
        row['id'] as String:
            CommunitySet.fromJson(row),
    };

    return setIds
        .map((id) => setsById[id])
        .whereType<CommunitySet>()
        .toList();
  }

  Future<void> setFavorited(
    String setId,
    bool favorited,
  ) async {
    if (favorited) {
      await addFavorite(setId);
    } else {
      await removeFavorite(setId);
    }
  }

  Future<int> getFavoriteCount(String setId) async {
    final response = await _client
        .from('set_favorites')
        .select('set_id')
        .eq('set_id', setId);

    return response.length;
  }
}