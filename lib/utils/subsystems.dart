// DIP
import 'package:injectable/injectable.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:grass_app/utils/mqtt_util.dart';
import 'package:grass_app/utils/authority.dart';
import 'package:grass_app/common.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/models/activity_log.dart';

@injectable
class TemperatureSubsystem {
  final DatabaseService _db;
  final AppMqttTransactions _mqtt;
  TemperatureSubsystem(this._db, this._mqtt);

  // Shortcut for tile toggle, so it's manual
  Future<void> toggleSunscreen() async {
    bool sunscreenDeployed =
        Settings.getValue('temperature-sunscreens-deployed', false);
    if (sunscreenDeployed) {
      retractSunscreen(Mode.Manual);
    } else {
      deploySunscreen(Mode.Manual);
    }
  }

  Future<void> deploySunscreen(Mode mode) async {
    String message = await _mqtt.publish('/feeds/bk-iot-servo', '180');
    Settings.setValue('temperature-sunscreens-deployed', true);
    // For logging
    switch (mode) {
      case Mode.Automatic:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen deployed automatically.',
              message,
              0,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Scheduled:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen deployed according to schedule.',
              message,
              1,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Manual:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen deployed manually.',
              message,
              2,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Fallback:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen deployed due to high temperature.',
              message,
              3,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      default:
        {
        }
    }
  }

  Future<void> retractSunscreen(Mode mode) async {
    String message = await _mqtt.publish('/feeds/bk-iot-servo', '0');
    Settings.setValue('temperature-sunscreens-deployed', false);
    // For logging
    switch (mode) {
      case Mode.Automatic:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen retracted automatically.',
              message,
              0,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Scheduled:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen retracted according to schedule.',
              message,
              1,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Manual:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen retracted manually.',
              message,
              2,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Fallback:
        {
          await _db.saveLog(ActivityLog(
              'Sunscreen retracted due to low temperature.',
              message,
              3,
              'Temperature',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      default:
        {
        }
    }
  }
}

@injectable
class IrrigationSubsystem {
  final DatabaseService _db;
  final AppMqttTransactions _mqtt;
  IrrigationSubsystem(this._db, this._mqtt);

  DateTime lastStartTime;
  String lastStartMessage;

  Future<void> startPump(Mode mode) async {
    lastStartMessage = await _mqtt.publish('/feeds/bk-iot-relay', '1');
    Settings.setValue('irrigation-pump-on', true);
    // For logging
    lastStartTime = DateTime.now();
  }

  Future<void> stopPump(Mode mode) async {
    String endMessage = await _mqtt.publish('/feeds/bk-iot-relay', '0');
    String pubMessages = lastStartMessage + '\n' + endMessage;
    Settings.setValue('irrigation-pump-on', false);
    // For logging
    Duration pumpDuration = DateTime.now().difference(lastStartTime);
    switch (mode) {
      case Mode.Automatic:
        {
          await _db.saveLog(ActivityLog(
              'Pump ran automatically for ${pumpDuration.inSeconds}s.',
              pubMessages,
              0,
              'Irrigation',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Scheduled:
        {
          await _db.saveLog(ActivityLog(
              'Pump ran according to schedule for ${pumpDuration.inSeconds}s.',
              pubMessages,
              1,
              'Irrigation',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Manual:
        {
          await _db.saveLog(ActivityLog(
              'Pump ran manually for ${pumpDuration.inSeconds}s.',
              pubMessages,
              2,
              'Irrigation',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Fallback:
        {
          await _db.saveLog(ActivityLog(
              'Pump ran for ${pumpDuration.inSeconds}s '
                  'due to dangerously low moisture.',
              pubMessages,
              3,
              'Irrigation',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      default:
        {
        }
    }
  }
}

@injectable
class LightingSubsystem {
  final DatabaseService _db;
  final AppMqttTransactions _mqtt;
  LightingSubsystem(this._db, this._mqtt);

  // Shortcut for tile toggle, so it's manual
  Future<void> toggleGrowLamps() async {
    bool lampsOn = Settings.getValue('lighting-lamps-on', false);
    if (lampsOn) {
      growLampsOff(Mode.Manual);
    } else {
      growLampsOn(Mode.Manual);
    }
  }

  // Red for now, since that's what grow lamps on the ISS do.
  Future<void> growLampsOn(Mode mode) async {
    String message = await _mqtt.publish('/feeds/bk-iot-led', '1');
    Settings.setValue('lighting-lamps-on', true);
    // For logging
    switch (mode) {
      case Mode.Automatic:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned on automatically.',
              message,
              0,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Scheduled:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned on according to schedule.',
              message,
              1,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Manual:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned on manually.',
              message,
              2,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Fallback:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned on due to unusually weak lighting.',
              message,
              3,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      default:
        {
        }
    }
  }

  Future<void> growLampsOff(Mode mode) async {
    String message = await _mqtt.publish('/feeds/bk-iot-led', '0');
    Settings.setValue('lighting-lamps-on', false);
    // For logging
    switch (mode) {
      case Mode.Automatic:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned off automatically.',
              message,
              0,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Scheduled:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned off according to schedule.',
              message,
              1,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Manual:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned off manually.',
              message,
              2,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      case Mode.Fallback:
        {
          await _db.saveLog(ActivityLog(
              'Grow lamps turned off as light levels have recovered.',
              message,
              3,
              'Light',
              DateTime.now().millisecondsSinceEpoch,
              Authority.currentProfile.id));
          break;
        }
      default:
        {
        }
    }
  }
}
