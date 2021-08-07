// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/material.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'package:grass_app/common_ui/timer.dart';
import 'package:grass_app/utils/scheduler.dart';
import 'package:grass_app/utils/settings.dart';
import 'package:grass_app/common.dart';

class TemperaturePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<StatefulWidget> {
  Scheduler _scheduler;
  @override
  void initState() {
    super.initState();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Theme(
        data: isDarkMode ? kTemperatureThemeDataDark : kTemperatureThemeData,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Temperature settings'),
            ),
            body: ListView(children: [
              Column(children: <Widget>[
                SimpleRadioSettingsTile(
                  title: 'Temperature regulation mode',
                  settingKey: 'temperature-mode',
                  values: <String>[
                    EnumToString.convertToString(Mode.Automatic),
                    EnumToString.convertToString(Mode.Scheduled),
                    EnumToString.convertToString(Mode.Manual)
                  ],
                  selected: Settings.getValue('temperature-mode',
                      EnumToString.convertToString(Mode.Manual)),
                ),
                ExpandableSettingsTile(title: 'Fail-safe settings', children: <
                    Widget>[
                  RangeSlider(
                    values: RangeValues(
                        ProfileSettings.get('temperature-fallback-low'),
                        ProfileSettings.get('temperature-fallback-high')),
                    min: -10,
                    max: 60,
                    onChanged: (RangeValues newValues) {/* do nothing*/},
                    onChangeEnd: (RangeValues newValues) => setState(() {
                      ProfileSettings.set(
                          'temperature-fallback-low', newValues.start);
                      ProfileSettings.set(
                          'temperature-fallback-high', newValues.end);
                    }),
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(children: [
                          Text('warn below',
                              style: TextStyle(
                                  color: Colors.black45, fontSize: 16)),
                          Container(
                            padding: EdgeInsets.all(5),
                            // color: Colors.green,
                            child: Text(
                              '${ProfileSettings.get('temperature-fallback-low').toInt()}°C',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]),
                        const SizedBox(
                            width: 2,
                            height: 24,
                            child: DecoratedBox(
                                decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(2))))),
                        Column(children: [
                          Text('warn above',
                              style: TextStyle(
                                  color: Colors.black45, fontSize: 16)),
                          Container(
                            padding: EdgeInsets.all(5),
                            // color: Colors.green,
                            child: Text(
                              '${ProfileSettings.get('temperature-fallback-high').toInt()}°C',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]),
                      ]),
                  RadioSettingsTile<int>(
                      title: 'Fail-safe behaviour',
                      settingKey: 'temperature-failsafe-behaviour',
                      values: <int, String>{
                        0: 'Warn and take action',
                        1: 'Warn only',
                        2: 'Do nothing'
                      },
                      selected:
                          ProfileSettings.get('temperature-failsafe-behaviour'),
                      onChange: (int value) {
                        setState(() {
                          ProfileSettings.set(
                              'temperature-failsafe-behaviour', value);
                        });
                      }),
                ]),
                ExpandableSettingsTile(
                    title: 'Automatic mode settings',
                    children: <Widget>[
                      RangeSlider(
                          values: RangeValues(
                              ProfileSettings.get('temperature-auto-low'),
                              ProfileSettings.get('temperature-auto-high')),
                          min: -10,
                          max: 60,
                          onChanged: (RangeValues newValues) {/* do nothing*/},
                          onChangeEnd: (RangeValues newValues) => setState(() {
                                // setState needed to update the preview row
                                ProfileSettings.set(
                                    'temperature-auto-low', newValues.start);
                                ProfileSettings.set(
                                    'temperature-auto-high', newValues.end);
                              })),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [
                              Text('retract below',
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 16)),
                              Container(
                                padding: EdgeInsets.all(5),
                                // color: Colors.green,
                                child: Text(
                                  '${ProfileSettings.get('temperature-auto-low').toInt()}°C',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]),
                            const SizedBox(
                                width: 2,
                                height: 24,
                                child: DecoratedBox(
                                    decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(2))))),
                            Column(children: [
                              Text('deploy above',
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 16)),
                              Container(
                                padding: EdgeInsets.all(5),
                                // color: Colors.green,
                                child: Text(
                                  '${ProfileSettings.get('temperature-auto-high').toInt()}°C',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]),
                          ]),
                    ]),
                ExpandableSettingsTile(
                    title: 'Scheduled mode settings',
                    children: <Widget>[
                      TimeRangeSelector(
                        subsystem: 2,
                        initialOnTime: _scheduler.temperatureFrom,
                        initialOffTime: _scheduler.temperatureTo,
                        onSelectionEnd:
                            (int startStep, int endStep, int rotations) =>
                                _scheduler.setSunscreenSchedule(startStep * 300,
                                    endStep * 300), // 5-minute steps
                      ),
                    ] // TODO: draw list of events here
                    )
              ])
            ])));
  }
}
