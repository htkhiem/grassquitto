// DIP
import 'package:grass_app/utils/mqtt_util.dart';
import 'package:injectable/injectable.dart';

import 'package:enum_to_string/enum_to_string.dart';
import 'dart:async';

import 'package:grass_app/utils/subsystems.dart';
import 'package:grass_app/utils/notification.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/utils/settings.dart';
import 'package:grass_app/common.dart';
import 'package:grass_app/models/record.dart';

@singleton
class AutomaticProcessor {
  final DatabaseService _db;
  final AppMqttTransactions _mqtt;
  final NotificationService _notificationService;
  final TemperatureSubsystem _temperatureSys;
  final IrrigationSubsystem _irrigationSys;
  final LightingSubsystem _lightingSys;

  AutomaticProcessor(this._db, this._mqtt, this._notificationService,
      this._temperatureSys, this._irrigationSys, this._lightingSys);

  StreamSubscription temperatureStreamSubscription,
      moistureStreamSubscription,
      lightStreamSubscription;

  void init() {
    temperatureStreamSubscription =
        _mqtt.temperatureStream.listen(processTemperature);
    moistureStreamSubscription = _mqtt.moistureStream.listen(processMoisture);
    lightStreamSubscription = _mqtt.lightStream.listen(processLight);
  }

  void reset() {
    temperatureStreamSubscription.cancel();
    moistureStreamSubscription.cancel();
    lightStreamSubscription.cancel();
  }

  // TEMPERATURE LEVEL PROCESSING
  Future<void> processTemperature(String data) async {
    var measurement = int.parse(data);
    assert(measurement is int);

    // Database insertion
    var newRecord = TemperatureRecord(
        measurement, DateTime.now().millisecondsSinceEpoch, -1);
    await _db.saveTemp(newRecord);

    // Fallback logic (applicable to all modes)
    final List<double> autoThreshold = [
      ProfileSettings.get('temperature-auto-low'),
      ProfileSettings.get('temperature-auto-high')
    ];
    final List<double> fallbackThreshold = [
      ProfileSettings.get('temperature-fallback-low'),
      ProfileSettings.get('temperature-fallback-high')
    ];

    final int failsafe = ProfileSettings.get('temperature-failsafe-behaviour');
    final Mode currentMode = EnumToString.fromString(
        Mode.values, ProfileSettings.get('temperature-mode'));

    // Fallback logic (applies to all modes)
    if (failsafe < 2) {
      if (measurement < fallbackThreshold.first) {
        if (failsafe == 0) {
          await _temperatureSys.retractSunscreen(Mode.Fallback);
          await _notificationService.displayBasicNotification(
              'Warning: low temperature',
              'Temperature is currently $measurement %, which is much lower than desired.\nYou have previously enabled fail-safe actions.');
        } else {
          await _notificationService.displayBasicNotification(
              'Warning: low temperature',
              'Temperature is currently $measurement %, which is much lower than desired.\nConsider turning on heating equipment if available.');
        }
        return;
      } else if (measurement > fallbackThreshold.last) {
        if (failsafe == 0) {
          await _temperatureSys.deploySunscreen(Mode.Fallback);
          await _notificationService.displayBasicNotification(
              'Warning: high temperature',
              'Temperature is currently $measurement %, which is much higher than desired.\nYou have previously enabled fail-safe actions.');
        } else {
          await _notificationService.displayBasicNotification(
              'Warning: high temperature',
              'Temperature is currently $measurement %, which is much higher than desired.\nConsider deploying your sunscreen, or allow us to take action automatically.');
        }
        return;
      }
    }

    // Automatic logic
    if (currentMode != Mode.Automatic) return;
    if (measurement < autoThreshold.first) {
      await _temperatureSys.retractSunscreen(currentMode);
    } else if (measurement > autoThreshold.last) {
      await _temperatureSys.deploySunscreen(currentMode);
    }
    return;
  }

  // MOISTURE LEVEL PROCESSING
  Future<void> processMoisture(String data) async {
    var measurement = int.parse(data);
    assert(measurement is int);

    // Database insertion
    var newRecord =
        MoistureRecord(measurement, DateTime.now().millisecondsSinceEpoch, -1);
    await _db.saveMoisture(newRecord);

    // Fallback logic (applicable to all modes)
    double autoLevel = ProfileSettings.get('irrigation-auto-threshold');
    Mode currentMode = EnumToString.fromString(
        Mode.values, ProfileSettings.get('irrigation-mode'));
    int failsafe = ProfileSettings.get('irrigation-failsafe-behaviour');
    if (measurement < autoLevel * 0.5 && failsafe < 2) {
      // Irrigate for 10 seconds
      if (failsafe == 0) {
        await _irrigationSys.startPump(Mode.Fallback);
        Timer(Duration(seconds: 20), () {
          _irrigationSys.stopPump(Mode.Fallback);
        });
      }
      // Warn user
      await _notificationService.displayBasicNotification(
          'Warning: please do check your soil\'s moisture',
          'Recent soil moisture level is $measurement %, which is much lower than recommended.\nPlease check if the water pump is working fine and the irrigation scheme is suitable.');
      return;
    } else if (measurement > autoLevel * 2.0 && failsafe < 2) {
      // Warn user of possible water redundancy
      await _notificationService.displayBasicNotification(
          'Warning: too much water',
          'Recent soil moisture level is $measurement %, which could impede nutrient absorption.\nPlease adjust the irrigation scheme suitably.');
      return;
    }

    // Automatic logic
    if (currentMode != Mode.Automatic) return;
    // Auto mode settings
    if (measurement < autoLevel * 0.75) {
      // 5 seconds irrigation
      await _irrigationSys.startPump(currentMode);
      Timer(Duration(seconds: 5), () {
        _irrigationSys.stopPump(currentMode);
      });
    } else if (measurement > autoLevel * 1.25) {
      // Do nothing for now
    }
    return;
  }

  // LIGHT LEVEL PROCESSING
  Future<void> processLight(String data) async {
    var measurement = int.parse(data);
    assert(measurement is int);

    // Database insertion
    var newRecord =
        LightRecord(measurement, DateTime.now().millisecondsSinceEpoch, -1);
    await _db.saveLight(newRecord);

    // Fallback logic (applicable to all modes)
    List<double> autoThreshold = [
      ProfileSettings.get('lighting-auto-low'),
      ProfileSettings.get('lighting-auto-high')
    ];
    List<double> warnThreshold = [
      ProfileSettings.get('lighting-fallback-low'),
      ProfileSettings.get('lighting-fallback-high')
    ];
    Mode currentMode = EnumToString.fromString(
        Mode.values, ProfileSettings.get('lighting-mode'));
    int failsafeBehaviour = ProfileSettings.get('lighting-failsafe-behaviour');
    if (failsafeBehaviour < 2) {
      if (measurement < warnThreshold[0]) {
        // Warn user
        if (failsafeBehaviour == 0) {
          await _notificationService.displayBasicNotification(
              'Warning: grow lamps turned on as failsafe.',
              'Recent light level is $measurement, which is much lower than recommended.\nYou have previously enabled fail-safe actions.');
          await _lightingSys.growLampsOn(Mode.Fallback);
        } else {
          await _notificationService.displayBasicNotification(
              'Warning: please check your environment\'s lighting',
              'Recent light level is $measurement, which is much lower than recommended.\nConsider turning on your grow lamps, or allow us to take action automatically.');
        }
        return;
      } else if (measurement > warnThreshold[1]) {
        if (failsafeBehaviour == 0) {
          await _lightingSys.growLampsOff(Mode.Fallback);
        }
        // Warn user of possible energy overload
        await _notificationService.displayBasicNotification(
            'Warning: intense lighting',
            'Recent light level is $measurement, which could burn out sensitive plants.\nConsider also deploying the sunscreen.');
        return;
      }
    }

    if (currentMode != Mode.Automatic) return;
    // Automatic logic
    if (measurement < autoThreshold[0]) {
      await _lightingSys.growLampsOn(currentMode);
    } else if (measurement > autoThreshold[1]) {
      // Do nothing for now
      _lightingSys.growLampsOff(currentMode);
    }
    return;
  }
}
