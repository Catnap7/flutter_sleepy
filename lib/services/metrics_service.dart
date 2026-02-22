import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetricsService {
  MetricsService._();

  static final MetricsService instance = MetricsService._();

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> trackAppOpen() async {
    final preferences = await _prefs();
    final openCount = (preferences.getInt('metric_app_open_count') ?? 0) + 1;
    await preferences.setInt('metric_app_open_count', openCount);

    await track('app_open');
    if (openCount > 1) {
      await track('revisit');
    }
  }

  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    final preferences = await _prefs();
    final countKey = 'metric_count_$event';
    final eventCount = (preferences.getInt(countKey) ?? 0) + 1;
    await preferences.setInt(countKey, eventCount);
    await preferences.setString(
        'metric_last_$event', DateTime.now().toIso8601String());

    if (properties.isNotEmpty) {
      await preferences.setString(
        'metric_props_$event',
        jsonEncode(properties),
      );
    }

    if (kDebugMode) {
      debugPrint(
          'Metric tracked: $event ${properties.isEmpty ? '' : properties}');
    }
  }
}
