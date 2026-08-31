import 'package:supabase_flutter/supabase_flutter.dart';

class SetRatingSummary {
  final double average;
  final int count;
  final int? userRating;

  const SetRatingSummary({
    required this.average,
    required this.count,
    required this.userRating,
  });
}

class SetRatingsRepository {
  final SupabaseClient _client;

  SetRatingsRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  Future<SetRatingSummary> getRatingSummary(
    String setId,
  ) async {
    final response = await _client
        .from('set_ratings')
        .select('user_id, rating')
        .eq('set_id', setId);

    if (response.isEmpty) {
      return const SetRatingSummary(
        average: 0,
        count: 0,
        userRating: null,
      );
    }

    final userId = _client.auth.currentUser?.id;

    var total = 0;
    int? userRating;

    for (final row in response) {
      final rating = row['rating'] as int;

      total += rating;

      if (row['user_id'] == userId) {
        userRating = rating;
      }
    }

    return SetRatingSummary(
      average: total / response.length,
      count: response.length,
      userRating: userRating,
    );
  }

  Future<void> setRating(
    String setId,
    int rating,
  ) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError(
        'Rating must be between 1 and 5.',
      );
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in to rate a set.',
      );
    }

    await _client.from('set_ratings').upsert(
      {
        'set_id': setId,
        'user_id': user.id,
        'rating': rating,
        'updated_at': DateTime.now()
            .toUtc()
            .toIso8601String(),
      },
      onConflict: 'set_id,user_id',
    );
  }

  Future<void> removeRating(
    String setId,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return;
    }

    await _client
        .from('set_ratings')
        .delete()
        .eq('set_id', setId)
        .eq('user_id', user.id);
  }
}