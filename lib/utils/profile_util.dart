// DIP
import 'package:grass_app/utils/dataprocess.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:grass_app/utils/authority.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/utils/settings.dart';
import 'package:grass_app/utils/mqtt_util.dart';
import 'package:grass_app/utils/scheduler.dart';

@singleton
class ProfileUtils {
  final DatabaseService _db;
  final AppMqttTransactions _mqtt;
  final AutomaticProcessor _automaticProcessor;
  final Scheduler _scheduler;
  ProfileUtils(this._db, this._mqtt, this._scheduler, this._automaticProcessor);
  // This is only done once all s%ervers have been created and all devices
  // have had its id matched.
  // @return  0: successful
  //          1: unable to connect
  //          2: remote authentication failure
  //          3: internal error
  //          4: wrong profile password
  Future<int> tryConnect(String username, String password) async {
    // Authority _authority = Authority();
    bool passwordCorrect = await _db.tryLogIn(username, password);
    if (!passwordCorrect) return 4;
    // Can correct profile password
    Authority.currentProfile = await _db.getUser(username);
    // DB initialised to profile. Now we can subscribe.
    int result = await _mqtt.subscribeTopics();
    if (result == 0) {
      // These have to be run after setting logged-in-value.
      ProfileSettings profileSettings = ProfileSettings();
      await profileSettings.init();
      Settings.init(cacheProvider: profileSettings);
      // Then scheduler, which needs DB for task management and MQTT for publishing.
      await _scheduler.init();
      _automaticProcessor.init();
    } else {
      Authority.currentProfile = null;

      if (result != 1 && result != 2) _mqtt.logout();
    }
    return result;
  }

  Future<void> logout() async {
    _mqtt.logout();
    _automaticProcessor.reset();
    _scheduler.reset();
    ProfileSettings.reset();
    Authority.currentProfile = null;
  }

  // Delete the currently logged-in profile.
  Future<void> deleteProfile() async {
    _mqtt.logout();
    await _db.deleteUser(Authority.currentProfile);
    Authority.currentProfile = null;
  }
}
