import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pose.dart';

class YogaRepository {
  /// Loads the yoga poses from the local JSON asset file.
  ///
  /// This method reads the 'poses.json' file, decodes the JSON string,
  /// and then maps the list of JSON objects to a list of [Pose] objects.
  Future<List<Pose>> getPoses() async {
    // 1. Load the JSON file contents from the assets folder.
    final String jsonString = await rootBundle.loadString(
      'assets/json/poses.json',
    );

    // 2. Decode the JSON string into a List of dynamic maps.
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    // 3. Map the list of JSON maps to a list of Pose objects using the fromJson factory.
    return jsonList
        .map((json) => Pose.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final yogaRepositoryProvider = Provider((ref) => YogaRepository());
