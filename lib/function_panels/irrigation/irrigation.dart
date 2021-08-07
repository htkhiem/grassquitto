import 'package:flutter/material.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'package:grass_app/function_panels/irrigation/irrigation_sched_editor.dart';
import 'package:grass_app/utils/settings.dart';
import 'package:grass_app/common.dart';

// Back-end working
import '../../common.dart';

class IrrigationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) {
    Settings.setValue(
        'irrigation-mode', ProfileSettings.get('irrigation-mode'));
    // Manual again since we're overriding app theme
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return WillPopScope(
        child: Theme(
          data: isDarkMode ? kIrrigationThemeDataDark : kIrrigationThemeData,
          child: Scaffold(
              appBar: AppBar(
                title: const Text('Irrigation settings'),
              ),
              body: ListView(children: [
                Column(children: <Widget>[
                  SimpleRadioSettingsTile(
                    title: 'Moisture regulation mode',
                    settingKey: 'irrigation-mode',
                    // TODO: Replace these widgets with something else
                    values: <String>[
                      EnumToString.convertToString(Mode.Automatic),
                      EnumToString.convertToString(Mode.Scheduled),
                      EnumToString.convertToString(Mode.Manual)
                    ],
                    selected: ProfileSettings.get('irrigation-mode'),
                  ),
                  RadioSettingsTile<int>(
                      title: 'Fail-safe behaviour',
                      settingKey: 'irrigation-failsafe-behaviour',
                      values: <int, String>{
                        0: 'Warn and take action',
                        1: 'Warn only',
                        2: 'Do nothing'
                      },
                      selected:
                          ProfileSettings.get('irrigation-failsafe-behaviour'),
                      onChange: (int value) {
                        setState(() {
                          ProfileSettings.set(
                              'irrigation-failsafe-behaviour', value);
                        });
                      }),
                  ExpandableSettingsTile(
                      title: 'Automatic mode settings',
                      children: <Widget>[
                        RadioSettingsTile<int>(
                          title: 'Moisture level',
                          settingKey: 'irrigation-auto-threshold-mode',
                          values: <int, String>{
                            0: '🌵 Dry',
                            1: '🌻 Average',
                            2: '🌾 Wet',
                            3: '⚙ Custom'
                          },
                          selected: ProfileSettings.get(
                              'irrigation-auto-threshold-mode'),
                          onChange: (value) {
                            setState(() {
                              switch (value) {
                                case 0:
                                  {
                                    ProfileSettings.set(
                                        'irrigation-auto-threshold', 3.0);
                                    break;
                                  }
                                case 1:
                                  {
                                    ProfileSettings.set(
                                        'irrigation-auto-threshold',
                                        kIrrigationAutoThresholdDefault);
                                    break;
                                  }
                                case 2:
                                  {
                                    ProfileSettings.set(
                                        'irrigation-auto-threshold', 50.0);
                                    break;
                                  }
                                default:
                                  {}
                              }
                            });
                          },
                        ),
                        if (ProfileSettings.get(
                                'irrigation-auto-threshold-mode') ==
                            3)
                          SliderSettingsTile(
                            title: 'Custom moisture level',
                            settingKey: 'irrigation-auto-threshold',
                            defaultValue: kIrrigationAutoThresholdDefault,
                            min: 0,
                            max: 100,
                            step: 1,
                            leading: Icon(Icons.waves),
                          )
                      ]),
                  ExpandableSettingsTile(
                    title: 'Scheduled mode settings',
                    children: <Widget>[
                      SimpleSettingsTile(
                        title: "Edit schedule",
                        subtitle: "Add new tasks or cancel existing ones",
                        leading: Icon(Icons.calendar_today_rounded),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    IrrigationSchedulePage())),
                      ),
                    ],
                  ),
                ])
              ])),
        ),
        onWillPop: () async {
          ProfileSettings.saveSettings();
          return true;
        });
  }
}
