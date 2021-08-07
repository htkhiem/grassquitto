import 'dart:convert';
import 'dart:io';

import 'package:grass_app/common.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:path_provider/path_provider.dart';
import 'package:grass_app/utils/authority.dart';

// abstract class CacheProvider {
//   CacheProvider();
//
//   Future<void> init();
//
//   int getInt(String key);
//
//   String getString(String key);
//
//   double getDouble(String key);
//
//   bool getBool(String key);
//
//   Future<void> setInt(String key, int value);
//
//   Future<void> setString(String key, String value);
//
//   Future<void> setDouble(String key, double value);
//
//   Future<void> setBool(String key, bool value);
//
//   bool containsKey(String key);
//
//   Set getKeys();
//
//   Future<void> remove(String key);
//
//   Future<void> removeAll();
//
//   Future<void> setObject<T>(String key, T value);
//
//   T getValue<T>(String key, T defaultValue);
// }

class ProfileSettings implements CacheProvider {
  static bool initialised = false;
  static Map<String, dynamic> _profileSettings;

  @override
  Future<void> init() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    final File file = File(
        documentDirectory.path + '/' + Authority.currentProfile.name + '.json');
    if (await file.exists()) {
      String text = await file.readAsString();
      _profileSettings = jsonDecode(text);
    } else {
      // Profile from old version with SharedPreferences, or newly created
      _profileSettings = Map<String, dynamic>();
    }
    // For updating in case schema changed
    await initSettings();
    // Non-saved keys
    _profileSettings['app-visible'] = true;
    ProfileSettings.initialised = true;
  }

  // Initialises this new profile with a bunch of default settings.
  // Can also be used to update older schemas to the latest version.
  // Basically serves as our schema
  static Future<void> initSettings() async {
    // Subsystem defaults
    if (!_profileSettings.containsKey('irrigation-mode'))
      _profileSettings['irrigation-mode'] = 'Manual';
    if (!_profileSettings.containsKey('irrigation-last-measurement'))
      _profileSettings['irrigation-last-measurement'] = -1;
    if (!_profileSettings.containsKey('irrigation-auto-threshold-mode'))
      _profileSettings['irrigation-auto-threshold-mode'] = 2;
    if (!_profileSettings.containsKey('irrigation-auto-threshold'))
      _profileSettings['irrigation-auto-threshold'] =
          kIrrigationAutoThresholdDefault;
    if (!_profileSettings.containsKey('irrigation-failsafe-behaviour'))
      _profileSettings['irrigation-failsafe-behaviour'] = 0;
    if (!_profileSettings.containsKey('irrigation-pump-state'))
      _profileSettings['irrigation-pump-state'] = false;

    if (!_profileSettings.containsKey('temperature-mode'))
      _profileSettings['temperature-mode'] = 'Manual';
    if (!_profileSettings.containsKey('temperature-last-measurement'))
      _profileSettings['temperature-last-measurement'] = -1;
    if (!_profileSettings.containsKey('temperature-sunscreen-state'))
      _profileSettings['temperature-sunscreen-state'] = false;
    if (!_profileSettings.containsKey('temperature-failsafe-behaviour'))
      _profileSettings['temperature-failsafe-behaviour'] = 0;
    if (!_profileSettings.containsKey('temperature-auto-low'))
      _profileSettings['temperature-auto-low'] = 20.0;
    if (!_profileSettings.containsKey('temperature-auto-high'))
      _profileSettings['temperature-auto-high'] = 30.0;
    if (!_profileSettings.containsKey('temperature-fallback-low'))
      _profileSettings['temperature-fallback-low'] = 15.0;
    if (!_profileSettings.containsKey('temperature-fallback-high'))
      _profileSettings['temperature-fallback-high'] = 35.0;

    if (!_profileSettings.containsKey('lighting-mode'))
      _profileSettings['lighting-mode'] = 'Manual';
    if (!_profileSettings.containsKey('lighting-auto-low'))
      _profileSettings['lighting-auto-low'] = 650.0;
    if (!_profileSettings.containsKey('lighting-auto-high'))
      _profileSettings['lighting-auto-high'] = 800.0;
    if (!_profileSettings.containsKey('lighting-fallback-low'))
      _profileSettings['lighting-fallback-low'] = 500.0;
    if (!_profileSettings.containsKey('lighting-fallback-high'))
      _profileSettings['lighting-fallback-high'] = 1000.0;
    if (!_profileSettings.containsKey('lighting-failsafe-behaviour'))
      _profileSettings['lighting-failsafe-behaviour'] = 0;
    if (!_profileSettings.containsKey('lighting-last-measurement'))
      _profileSettings['lighting-last-measurement'] = -1;
    if (!_profileSettings.containsKey('lighting-grow-lamps-state'))
      _profileSettings['lighting-grow-lamps-state'] = false;
    if (!_profileSettings.containsKey('stats-display-from-ms'))
      _profileSettings['stats-display-from-ms'] =
          DateTime.now().millisecondsSinceEpoch;
    if (!_profileSettings.containsKey('stats-display-to-ms'))
      _profileSettings['stats-display-to-ms'] =
          DateTime.now().subtract(Duration(hours: 24)).millisecondsSinceEpoch;
    if (!_profileSettings.containsKey('scheduled-notifications-in-app'))
      _profileSettings['scheduled-notifications-in-app'] = true;
  }

  // TODO: These are disgusting - throw exceptions if type does not match
  int getInt(String key) {
    return get(key).toInt();
  }

  String getString(String key) {
    return get(key);
  }

  double getDouble(String key) {
    return get(key).toDouble();
  }

  bool getBool(String key) {
    return get(key);
  }

  Future<void> setInt(String key, int value, {int defaultValue = 0}) async {
    set(key, value);
  }

  Future<void> setString(String key, String value,
      {String defaultValue = ''}) async {
    set(key, value);
  }

  Future<void> setDouble(String key, double value,
      {double defaultValue = 0.0}) async {
    set(key, value);
  }

  Future<void> setBool(String key, bool value,
      {bool defaultValue = false}) async {
    set(key, value);
  }

  bool containsKey(String key) {
    return _profileSettings.containsKey(key);
  }

  Set getKeys() {
    return _profileSettings.keys.toSet();
  }

  Future<void> remove(String key) async {
    _profileSettings.remove(key);
  }

  Future<void> removeAll() async {
    initSettings();
  }

  Future<void> setObject<T>(String key, T value) {
    if (value is int) {
      return setInt(key, value);
    }
    if (value is double) {
      return setDouble(key, value);
    }
    if (value is bool) {
      return setBool(key, value);
    }
    if (value is String) {
      return setString(key, value);
    }
    throw Exception('No Implementation Found');
  }

  T getValue<T>(String key, T defaultValue) {
    if (defaultValue is int) {
      return getInt(key) as T;
    }
    if (defaultValue is double) {
      return getDouble(key) as T;
    }
    if (defaultValue is bool) {
      return getBool(key) as T;
    }
    if (defaultValue is String) {
      return getString(key) as T;
    }
    throw Exception('No Implementation Found');
  }

  static Future<void> saveSettings() async {
    if (ProfileSettings.initialised) {
      String profile = Authority.currentProfile.name;
      if (Authority.currentProfile != null) {
        Directory documentDirectory = await getApplicationDocumentsDirectory();
        final File file = File(documentDirectory.path + '/' + profile + '.json');
        String text = jsonEncode(_profileSettings);
        await file.writeAsString(text);
      }
    }
  }

  static void set(String key, dynamic value) {
    if (ProfileSettings.initialised) {
      _profileSettings[key] = value;
    }
  }

  static dynamic get(String key) {
    if (ProfileSettings.initialised && _profileSettings.containsKey(key)) {
      return _profileSettings[key];
    }
    return null;
  }

  static void reset() async {
    await saveSettings();
    ProfileSettings.initialised = false;
    _profileSettings = Map<String, dynamic>();
  }
}
