import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pose.dart';

class YogaRepository {
  List<Pose>? _cachedPoses;

  /// Loads the yoga poses from the local JSON asset file with caching.
  ///
  /// This method reads the 'poses.json' file, decodes the JSON string,
  /// and then maps the list of JSON objects to a list of [Pose] objects.
  /// Results are cached to avoid repeated file reads.
  Future<List<Pose>> getPoses() async {
    // Return cached poses if available
    if (_cachedPoses != null) {
      return _cachedPoses!;
    }

    try {
      // 1. Load the JSON file contents from the assets folder.
      final String jsonString = await rootBundle.loadString(
        'assets/json/poses.json',
      );

      // 2. Decode the JSON string into a List of dynamic maps.
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      // 3. Map the list of JSON maps to a list of Pose objects using the fromJson factory.
      _cachedPoses = jsonList
          .map((json) => Pose.fromJson(json as Map<String, dynamic>))
          .toList();

      return _cachedPoses!;
    } catch (e) {
      // Log error and return empty list
      // ignore: avoid_print
      print('Error loading poses: $e');
      return [];
    }
  }

  /// Clear the cache (useful for testing or when poses are updated)
  void clearCache() {
    _cachedPoses = null;
  }
}

final yogaRepositoryProvider = Provider((ref) => YogaRepository());
