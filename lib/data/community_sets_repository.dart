import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_set.dart';

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
}