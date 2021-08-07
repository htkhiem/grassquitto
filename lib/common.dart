import 'package:flutter/material.dart';
import 'dart:core';

// Application version, used for internal data updates
const int kVersion = 1;

// Function mode enum to avoid int coercion
enum Mode { None, Automatic, Scheduled, Manual, Fallback }

// Convert between enum and string
const Map<String, int> kModeIndex = {
  'Automatic': 0,
  'Scheduled': 1,
  'Manual': 2
};

const Map<String, Mode> kModeStringToEnum = {
  'Automatic': Mode.Automatic,
  'Scheduled': Mode.Scheduled,
  'Manual': Mode.Manual
};

const List<String> kModeNames = ['Automatic', 'Scheduled', 'Manual'];

enum Device { Light, DHT11, Soil, LED, Relay, Servo }

const List<String> SubscribingTopics = [
  'bk-iot-light',
  'bk-iot-soil',
  'bk-iot-temp-humid'
];
const List<String> PublishingTopics = [
  'bk-iot-led',
  'bk-iot-relay',
  'bk-iot-servo'
];

const Map<String, Map<String, String>> deviceMap = {
  '/feeds/bk-iot-led': {'id': '1', 'name': 'LED', 'unit': ''},
  '/feeds/bk-iot-temp-humid': {'id': '7', 'name': 'TEMP-HUMID', 'unit': 'C-%'},
  '/feeds/bk-iot-soil': {'id': '9', 'name': 'SOIL', 'unit': '%'},
  '/feeds/bk-iot-relay': {'id': '11', 'name': 'RELAY', 'unit': ''},
  '/feeds/bk-iot-light': {'id': '13', 'name': 'LIGHT', 'unit': ''},
  '/feeds/bk-iot-servo': {'id': '17', 'name': 'SERVO', 'unit': 'degree'}
};

const Map<String, Map<String, int>> Thresholds = {
  'temperature': {
    'auto-low': 20,
    'auto-high': 30,
    'fallback-low': 15,
    'fallback-high': 35
  },
  'moisture': {
    'auto-low': 2,
    'auto-high': 8,
    'fallback-low': 1,
    'fallback-high': 20
  },
  'light': {
    'auto-low': 650,
    'auto-high': 800,
    'fallback-low': 500,
    'fallback-high': 1000
  }
};

// Our swatch
const Color kTemperaturePrimaryColor = const Color(0xFFE58F0C);
const Color kTemperatureHighlightColor = const Color(0xFFECC985);

const Color kIrrigationPrimaryColor = const Color(0xFF017CEF);
const Color kIrrigationHighlightColor = const Color(0xFF9ECCF6);

const Color kLightingPrimaryColor = const Color(0xFF6DAF06);
const Color kLightingHighlightColor = const Color(0xFFBCE57C);

const Color kTemperaturePrimaryColorDark = const Color(0xFF472C02);
const Color kTemperatureHighlightColorDark = const Color(0xFF895E09);

const Color kIrrigationPrimaryColorDark = const Color(0xFF031B32);
const Color kIrrigationHighlightColorDark = const Color(0xFF0D5595);

const Color kLightingPrimaryColorDark = const Color(0xFF294202);
const Color kLightingHighlightColorDark = const Color(0xFF5B8B0C);

const List<Color> kDangerousGradient = <Color>[
  Color(0xFFC12020),
  Color(0xFF8D0B0B)
];
const List<Color> kDangerousGradientHighlight = <Color>[
  Color(0xFFE34E4E),
  Color(0xFFD71D1D)
];

// Database schema
const String kTemperatureDBTable = 'TemperatureRecords';
const String kLightDBTable = 'LightRecords';
const String kMoistureDBTable = 'MoistureRecords';
const String kActivityDBTable = 'ActivityLogs';

// Default settings
const double kIrrigationAutoThresholdDefault = 10;
const double kLightingAutoThresholdDefault = 650;
const double kTemperatureAutoThresholdDefault = 28;

const List<String> failsafeDescriptions = [
  'Warnings & fail-safe actions on',
  'Warnings on',
  'Warnings off'
];

// API link for http request to CSE
const String CSE_Key_Link = 'http://dadn.esp32thanhdanh.link';

final ThemeData kAppThemeData = ThemeData.from(
  colorScheme: const ColorScheme.light()
      .copyWith(primary: Colors.green, secondary: Colors.lightGreen),
).copyWith(
  floatingActionButtonTheme: FloatingActionButtonThemeData(
      foregroundColor: Colors.white, backgroundColor: Colors.green),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
    shape: MaterialStateProperty.all(CircleBorder(side: BorderSide.none)),
    shadowColor: MaterialStateProperty.all(Colors.green),
    padding: MaterialStateProperty.all(EdgeInsets.all(10)),
    elevation: MaterialStateProperty.resolveWith((Set<MaterialState> states) =>
        states.contains(MaterialState.disabled) ? 0 : 10),
    minimumSize: MaterialStateProperty.all(Size(36, 36)),
    foregroundColor: MaterialStateProperty.resolveWith(
        (Set<MaterialState> states) => states.contains(MaterialState.disabled)
            ? Colors.white30
            : Colors.white),
    backgroundColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.disabled)
            ? Colors.green.withOpacity(0.3)
            : Colors.green),
  )),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    },
  ),
);

final ThemeData kAppThemeDataDark = ThemeData.from(
        colorScheme: const ColorScheme.dark()
            .copyWith(primary: Colors.green, secondary: Colors.lightGreen))
    .copyWith(
  floatingActionButtonTheme: FloatingActionButtonThemeData(
      foregroundColor: Colors.white, backgroundColor: Colors.white24),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
    shape: MaterialStateProperty.all(CircleBorder(side: BorderSide.none)),
    shadowColor: MaterialStateProperty.all(Colors.white38),
    padding: MaterialStateProperty.all(EdgeInsets.all(10)),
    elevation: MaterialStateProperty.resolveWith((Set<MaterialState> states) =>
        states.contains(MaterialState.disabled) ? 0 : 10),
    minimumSize: MaterialStateProperty.all(Size(36, 36)),
    foregroundColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.disabled)
            ? Colors.white30
            : Colors.white),
    backgroundColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.disabled)
            ? Colors.white12
            : Colors.white24),
  )),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    },
  ),
);

final ThemeData kIrrigationThemeData = ThemeData(
    primaryColor: kIrrigationPrimaryColor,
    accentColor: kIrrigationPrimaryColor,
    sliderTheme: SliderThemeData.fromPrimaryColors(
        primaryColor: kIrrigationPrimaryColor,
        primaryColorDark: kIrrigationPrimaryColor.withOpacity(0.8),
        primaryColorLight: kIrrigationHighlightColor,
        valueIndicatorTextStyle: TextStyle(fontSize: 11, color: Colors.black)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(
                (Set<MaterialState> states) =>
                    states.contains(MaterialState.disabled)
                        ? kIrrigationHighlightColor
                        : kIrrigationPrimaryColor),
            overlayColor:
                MaterialStateProperty.all(kIrrigationHighlightColor))));

final ThemeData kTemperatureThemeData = ThemeData(
    primaryColor: kTemperaturePrimaryColor,
    accentColor: kTemperaturePrimaryColor,
    sliderTheme: SliderThemeData.fromPrimaryColors(
        primaryColor: kTemperaturePrimaryColor,
        primaryColorDark: kTemperaturePrimaryColor.withOpacity(0.8),
        primaryColorLight: kTemperatureHighlightColor,
        valueIndicatorTextStyle: TextStyle(fontSize: 11, color: Colors.black)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(
                (Set<MaterialState> states) =>
                    states.contains(MaterialState.disabled)
                        ? kTemperatureHighlightColor
                        : kTemperaturePrimaryColor),
            overlayColor:
                MaterialStateProperty.all(kTemperatureHighlightColor))));

final ThemeData kLightingThemeData = ThemeData(
    primaryColor: kLightingPrimaryColor,
    accentColor: kLightingPrimaryColor,
    sliderTheme: SliderThemeData.fromPrimaryColors(
        primaryColor: kLightingPrimaryColor,
        primaryColorDark: kLightingPrimaryColor.withOpacity(0.8),
        primaryColorLight: kLightingHighlightColor,
        valueIndicatorTextStyle: TextStyle(fontSize: 11, color: Colors.black)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(
                (Set<MaterialState> states) =>
                    states.contains(MaterialState.disabled)
                        ? kLightingHighlightColor
                        : kLightingPrimaryColor),
            overlayColor: MaterialStateProperty.all(kLightingHighlightColor))));

final ThemeData kIrrigationThemeDataDark = ThemeData.from(colorScheme: ColorScheme.dark(secondary: kIrrigationPrimaryColor, secondaryVariant: kIrrigationPrimaryColor)).copyWith(
    iconTheme: IconThemeData(color: kIrrigationPrimaryColor),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            overlayColor:
                MaterialStateProperty.all(kIrrigationHighlightColor))),
    radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith(
            (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? kIrrigationPrimaryColor
                : Colors.grey)),
    sliderTheme: SliderThemeData.fromPrimaryColors(
        primaryColor: kIrrigationPrimaryColor,
        primaryColorDark: kIrrigationPrimaryColor.withOpacity(0.8),
        primaryColorLight: kIrrigationHighlightColor,
        valueIndicatorTextStyle: TextStyle(fontSize: 11, color: Colors.black)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? kIrrigationHighlightColor : kIrrigationPrimaryColor),
            overlayColor: MaterialStateProperty.all(kIrrigationHighlightColor))));

final ThemeData kTemperatureThemeDataDark = ThemeData.from(colorScheme: ColorScheme.dark(secondary: kTemperaturePrimaryColor, secondaryVariant: kTemperaturePrimaryColor)).copyWith(
    iconTheme: IconThemeData(color: kTemperaturePrimaryColor),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            overlayColor:
                MaterialStateProperty.all(kTemperatureHighlightColor))),
    radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith(
            (Set<MaterialState> states) => states.contains(MaterialState.selected)
                ? kTemperaturePrimaryColor
                : Colors.grey)),
    sliderTheme: SliderThemeData.fromPrimaryColors(
        primaryColor: kTemperaturePrimaryColor,
        primaryColorDark: kTemperaturePrimaryColor.withOpacity(0.8),
        primaryColorLight: kTemperatureHighlightColor,
        valueIndicatorTextStyle: TextStyle(fontSize: 11, color: Colors.black)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) => states.contains(MaterialState.disabled) ? kTemperatureHighlightColor : kTemperaturePrimaryColor),
            overlayColor: MaterialStateProperty.all(kTemperatureHighlightColor))));

final ThemeData kLightingThemeDataDark = ThemeData.from(colorScheme: ColorScheme.dark(secondary: kLightingPrimaryColor, secondaryVariant: kLightingPrimaryColor)).copyWith(
    iconTheme: IconThemeData(color: kLightingPrimaryColor),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(kLightingHighlightColor))),
    radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith(
            (Set<MaterialState> states) =>
                states.contains(MaterialState.selected)
                    ? kLightingPrimaryColor
                    : Colors.grey)),
    sliderTheme: SliderThemeData.fromPrimaryColors(
        primaryColor: kLightingPrimaryColor,
        primaryColorDark: kLightingPrimaryColor.withOpacity(0.8),
        primaryColorLight: kLightingHighlightColor,
        valueIndicatorTextStyle: TextStyle(fontSize: 11, color: Colors.black)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) => states.contains(MaterialState.disabled) ? kLightingHighlightColor : kLightingPrimaryColor),
            overlayColor: MaterialStateProperty.all(kLightingHighlightColor))));
