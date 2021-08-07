// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/material.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'package:grass_app/utils/scheduler.dart';
import 'package:grass_app/common_ui/timer.dart';
import 'package:grass_app/utils/settings.dart';
import 'package:grass_app/models/task.dart';
import 'package:grass_app/common.dart';

class LightingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LightingPageState();
}

class _LightingPageState extends State<StatefulWidget> {
  // int initTime;
  // int endTime;
  // String mode;
  // _LightingPageState(this.mode);
  //
  // int inBedTime;
  // int outBedTime;
  SubsystemTask task;

  Scheduler _scheduler;
  @override
  void initState() {
    super.initState();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  final baseColor = Color.fromRGBO(255, 255, 255, 0.3);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Theme(
        data: isDarkMode ? kLightingThemeDataDark : kLightingThemeData,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Lighting settings'),
            ),
            body: ListView(children: [
              Column(children: <Widget>[
                SimpleRadioSettingsTile(
                  title: 'Light level regulation mode',
                  settingKey: 'lighting-mode',
                  values: <String>[
                    EnumToString.convertToString(Mode.Automatic),
                    EnumToString.convertToString(Mode.Scheduled),
                    EnumToString.convertToString(Mode.Manual)
                  ],
                  selected: Settings.getValue('lighting-mode',
                      EnumToString.convertToString(Mode.Manual)),
                ),
                ExpandableSettingsTile(title: 'Fail-safe settings', children: <
                    Widget>[
                  RangeSlider(
                    values: RangeValues(
                        ProfileSettings.get('lighting-fallback-low'),
                        ProfileSettings.get('lighting-fallback-high')),
                    min: 1,
                    max: 1023,
                    onChanged: (RangeValues newValues) {/* do nothing*/},
                    onChangeEnd: (RangeValues newValues) => setState(() {
                      ProfileSettings.set(
                          'lighting-fallback-low', newValues.start);
                      ProfileSettings.set(
                          'lighting-fallback-high', newValues.end);
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
                              '${ProfileSettings.get('lighting-fallback-low').toInt()}W/m²',
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
                              '${ProfileSettings.get('lighting-fallback-high').toInt()}W/m²',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]),
                      ]),
                  RadioSettingsTile<int>(
                      title: 'Fail-safe behaviour',
                      settingKey: 'lighting-failsafe-behaviour',
                      values: <int, String>{
                        0: 'Warn and take action',
                        1: 'Warn only',
                        2: 'Do nothing'
                      },
                      selected:
                          ProfileSettings.get('lighting-failsafe-behaviour'),
                      onChange: (int value) {
                        setState(() {
                          ProfileSettings.set(
                              'lighting-failsafe-behaviour', value);
                        });
                      }),
                ]),
                ExpandableSettingsTile(
                    title: 'Automatic mode settings',
                    children: <Widget>[
                      RangeSlider(
                          values: RangeValues(
                              ProfileSettings.get('lighting-auto-low'),
                              ProfileSettings.get('lighting-auto-high')),
                          min: 1,
                          max: 1023,
                          onChanged: (RangeValues newValues) {/* do nothing*/},
                          onChangeEnd: (RangeValues newValues) => setState(() {
                                // setState needed to update the preview row
                                ProfileSettings.set(
                                    'lighting-auto-low', newValues.start);
                                ProfileSettings.set(
                                    'lighting-auto-high', newValues.end);
                              })),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [
                              Text('lamps on below',
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 16)),
                              Container(
                                padding: EdgeInsets.all(5),
                                // color: Colors.green,
                                child: Text(
                                  '${ProfileSettings.get('lighting-auto-low').toInt()}W/m²',
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
                              Text('lamps off above',
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 16)),
                              Container(
                                padding: EdgeInsets.all(5),
                                // color: Colors.green,
                                child: Text(
                                  '${ProfileSettings.get('lighting-auto-high').toInt()}W/m²',
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
                        subsystem: 1,
                        initialOnTime: _scheduler.lightingFrom,
                        initialOffTime: _scheduler.lightingTo,
                        onSelectionEnd:
                            (int startStep, int endStep, int rotations) =>
                                _scheduler.setGrowLampsSchedule(startStep * 300,
                                    endStep * 300), // 5-minute steps
                      ),
                    ]
                    // children: [
                    //
                    // ],
                    )
              ])
            ])));
  }
}
