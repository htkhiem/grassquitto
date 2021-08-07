// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import 'main.dart' as _i3;
import 'utils/database.dart' as _i5;
import 'utils/dataprocess.dart' as _i8;
import 'utils/mqtt_util.dart' as _i6;
import 'utils/notification.dart' as _i7;
import 'utils/profile_util.dart' as _i10;
import 'utils/scheduler.dart' as _i9;
import 'utils/subsystems.dart' as _i4; // ignore_for_file: unnecessary_lambdas

// ignore_for_file: lines_longer_than_80_chars
/// initializes the registration of provided dependencies inside of [GetIt]
_i1.GetIt $initGetIt(_i1.GetIt get,
    {String environment, _i2.EnvironmentFilter environmentFilter}) {
  final gh = _i2.GetItHelper(get, environment, environmentFilter);
  gh.factory<_i3.OverviewTiles>(() => _i3.OverviewTiles());
  gh.factory<_i4.IrrigationSubsystem>(() => _i4.IrrigationSubsystem(
      get<_i5.DatabaseService>(), get<_i6.AppMqttTransactions>()));
  gh.factory<_i4.LightingSubsystem>(() => _i4.LightingSubsystem(
      get<_i5.DatabaseService>(), get<_i6.AppMqttTransactions>()));
  gh.factory<_i4.TemperatureSubsystem>(() => _i4.TemperatureSubsystem(
      get<_i5.DatabaseService>(), get<_i6.AppMqttTransactions>()));
  gh.singleton<_i5.DatabaseService>(_i5.DatabaseService());
  gh.singleton<_i7.NotificationService>(_i7.NotificationService());
  gh.singleton<_i6.AppMqttTransactions>(
      _i6.AppMqttTransactions(get<_i5.DatabaseService>()));
  gh.singleton<_i8.AutomaticProcessor>(_i8.AutomaticProcessor(
      get<_i5.DatabaseService>(),
      get<_i6.AppMqttTransactions>(),
      get<_i7.NotificationService>(),
      get<_i4.TemperatureSubsystem>(),
      get<_i4.IrrigationSubsystem>(),
      get<_i4.LightingSubsystem>()));
  gh.singleton<_i9.Scheduler>(_i9.Scheduler(
      get<_i5.DatabaseService>(),
      get<_i4.IrrigationSubsystem>(),
      get<_i4.LightingSubsystem>(),
      get<_i4.TemperatureSubsystem>()));
  gh.singleton<_i10.ProfileUtils>(_i10.ProfileUtils(
      get<_i5.DatabaseService>(),
      get<_i6.AppMqttTransactions>(),
      get<_i9.Scheduler>(),
      get<_i8.AutomaticProcessor>()));
  return get;
}
