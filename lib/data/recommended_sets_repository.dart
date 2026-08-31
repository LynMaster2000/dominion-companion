import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/recommended_set.dart';

class RecommendedSetsRepository {
  Future<List<RecommendedSet>> loadSets() async {
    final jsonString = await rootBundle.loadString(
      'assets/sets/official_sets.json',
    );

    final jsonList = jsonDecode(jsonString) as List<dynamic>;

    return jsonList
        .map(
          (json) => RecommendedSet.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}