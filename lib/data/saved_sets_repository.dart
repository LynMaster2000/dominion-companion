import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_set.dart';

class SavedSetRepository {
  static const String _storageKey = 'saved_sets';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<SavedSet>> loadSets() async {
    final jsonString = await _prefs.getString(_storageKey);

    if (jsonString == null) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map(
          (json) => SavedSet.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveSets(List<SavedSet> sets) async {
    final jsonList = sets
        .map((set) => set.toJson())
        .toList();

    await _prefs.setString(
      _storageKey,
      jsonEncode(jsonList),
    );
  }
}