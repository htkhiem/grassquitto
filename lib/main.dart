// DIP
import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:get_it/get_it.dart';
import 'main.config.dart';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

// 3rd party
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:grass_app/utils/profile_util.dart';
import 'package:grass_app/utils/authority.dart';
import 'package:grass_app/utils/settings.dart';
import 'package:animations/animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_animated_icon/simple_animated_icon.dart';

// Ours
import 'package:grass_app/common.dart';
import 'package:grass_app/utils/mqtt_util.dart';
import 'package:grass_app/utils/subsystems.dart';
import 'package:grass_app/utils/scheduler.dart';
import 'package:grass_app/function_panels/temperature/temperature.dart';
import 'package:grass_app/function_panels/irrigation/irrigation.dart';
import 'package:grass_app/function_panels/lighting/lighting.dart';
import 'package:grass_app/function_panels/settings/settings.dart';
import 'package:grass_app/function_panels/statistics/statistics.dart';
import 'package:grass_app/function_panels/reminder/reminder.dart';
import 'package:grass_app/function_panels/login/login_screen.dart';

String modeToString(Mode mode) {
  switch (mode) {
    case Mode.Automatic:
      {
        return 'AUTOMATIC';
      }
    case Mode.Scheduled:
      {
        return 'SCHEDULED';
      }
    case Mode.Manual:
      {
        return 'MANUAL';
      }
    default:
      {
        return 'ERROR';
      }
  }
}

@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
void configureDependencies() => $initGetIt(GetIt.I);

Future<void> main() async {
  // Database comes first
  configureDependencies();
  // debugPaintSizeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Grassquitto',
        theme: kAppThemeData,
        darkTheme: kAppThemeDataDark,
        // TODO: If not logged out explicitly, just autologin.
        home: LoginPage());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Won't do anything if not currently logged in.
    ProfileSettings.saveSettings();
    super.dispose();
  }

  // Automatically save user settings to JSON file if app is exited
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Won't do anything if not currently logged in.
      ProfileSettings.saveSettings();
      ProfileSettings.set('app-visible', false);
    } else {
      if (Authority.currentProfile != null)
        ProfileSettings.set('app-visible', true);
    }
  }
}

@injectable
class OverviewTiles extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => OverviewTilesState();
}

class OverviewTilesState extends State<OverviewTiles> {
  // DISPLAY DATA
  AppMqttTransactions _mqtt;
  ProfileUtils _profileUtils;
  IrrigationSubsystem _irrigationSubsystem;
  LightingSubsystem _lightingSubsystem;
  TemperatureSubsystem _temperatureSubsystem;
  Scheduler _scheduler;

  StreamSubscription _ledStreamSubscription,
      _relayStreamSubscription,
      _servoStreamSubscription;

  @override
  void initState() {
    super.initState();
    _mqtt = GetIt.I.get<AppMqttTransactions>();
    _profileUtils = GetIt.I.get<ProfileUtils>();
    _irrigationSubsystem = GetIt.I.get<IrrigationSubsystem>();
    _lightingSubsystem = GetIt.I.get<LightingSubsystem>();
    _temperatureSubsystem = GetIt.I.get<TemperatureSubsystem>();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  final BorderRadius tileRadius = BorderRadius.all(Radius.circular(10));

  @override
  void dispose() {
    if (_ledStreamSubscription != null) {
      _ledStreamSubscription.cancel();
    }
    if (_relayStreamSubscription != null) {
      _relayStreamSubscription.cancel();
    }
    if (_servoStreamSubscription != null) {
      _servoStreamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We have to do this ourselves, since our tiles don't
    // read from the ThemeData.
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (_ledStreamSubscription == null) {
      _ledStreamSubscription = _mqtt.ledStream.listen((bool event) {
        if (event &&
            ProfileSettings.get('lighting-grow-lamps-state') == false) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Grow lamps turned on!')));
          ProfileSettings.set('lighting-grow-lamps-state', true);
        } else if (!event
            && ProfileSettings.get('lighting-grow-lamps-state') == true) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Grow lamps turned off!')));
          ProfileSettings.set('lighting-grow-lamps-state', false);
        }
      });
    }
    if (_relayStreamSubscription == null) {
      _relayStreamSubscription = _mqtt.relayStream.listen((bool event) {
        if (event && ProfileSettings.get('irrigation-pump-state') == false) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Pumping!')));
          ProfileSettings.set('irrigation-pump-state', true);
        } else if (!event
            && ProfileSettings.get('irrigation-pump-state') == true) {
          ProfileSettings.set('irrigation-pump-state', false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Pump stopped!')));
        }
      });
    }
    if (_servoStreamSubscription == null) {
      _servoStreamSubscription = _mqtt.servoStream.listen((bool event) {
        if (event &&
            ProfileSettings.get('temperature-sunscreen-state') == false) {
          ProfileSettings.set('temperature-sunscreen-state', true);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Sunscreen deployed!')));
        } else if (!event
            && ProfileSettings.get('temperature-sunscreen-state') == true) {
          ProfileSettings.set('temperature-sunscreen-state', false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Sunscreen retracted!')));
        }
      });
    }

    // WillPopScope to catch the Android back button
    return WillPopScope(
        onWillPop: () async {
          bool logout = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                        'Going back from the home screen means logging out of '
                        'your current session. Do you want to continue?'),
                    actions: [
                      TextButton(
                          child: const Text('NO'),
                          onPressed: () => Navigator.of(context).pop(false)),
                      TextButton(
                          child: const Text('YES'),
                          onPressed: () {
                            ProfileSettings.saveSettings();
                            Navigator.of(context).pop(true);
                          })
                    ]);
              });
          if (logout) {
            _profileUtils.logout();
          }
          return logout;
        },
        child: Scaffold(
            appBar: null,
            body: AnimationLimiter(
                child: ListView(
              padding: const EdgeInsets.all(20),
              children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 700),
                  childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(child: widget)),
                  children: [
                    Container(
                        height: 100,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                child: SvgPicture.asset(
                                  'assets/grassquitto.svg',
                                  semanticsLabel: 'Application Logo',
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Expanded(child: SizedBox(width: 10)),
                              Row(children: [
                                SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ElevatedButton(
                                      child: Icon(Icons.notifications),
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ReminderPage())),
                                    )),
                                const SizedBox(width: 10),
                                SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ElevatedButton(
                                        child: Icon(Icons.stacked_bar_chart),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      StatisticsPage()));
                                          setState(() {
                                            // nothing, just regenerate the thing
                                          });
                                        })),
                                const SizedBox(width: 10),
                                SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ElevatedButton(
                                        child: Icon(Icons.account_circle),
                                        onPressed: () async {
                                          bool deleteProfile =
                                              await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          ClientSettingsPage()));
                                          if (deleteProfile != null &&
                                              deleteProfile) {
                                            // Only pop after deleting to ensure that the
                                            // login screen shows up AFTER deletion tasks have
                                            // finished.
                                            await _profileUtils.deleteProfile();
                                            Navigator.of(context).pop();
                                          }
                                        })),
                              ])
                            ])),
                    SubsystemTile(
                      subStream: _mqtt.moistureStream,
                      pubStream: _mqtt.relayStream,
                      name: 'Irrigation',
                      unit: '%',
                      initialMeasurement:
                          ProfileSettings.get('irrigation-last-measurement'),
                      dangerCheck: (int measurement) {
                        double autoLevel =
                            ProfileSettings.get('irrigation-auto-threshold');
                        return measurement < autoLevel * 0.5 ||
                            measurement > autoLevel * 2.0;
                      },
                      indicator: Spinner(
                        child: SvgPicture.asset('assets/propeller.svg',
                            color: Colors.white, fit: BoxFit.contain),
                        onOffStream: _mqtt.relayStream,
                      ),
                      modeKey: 'irrigation-mode',
                      getActionDescription: (Mode irrigationMode) =>
                          irrigationMode == Mode.Automatic
                              ? 'Keeping around'
                              : (irrigationMode == Mode.Scheduled
                                  ? 'Number of tasks:'
                                  : failsafeDescriptions[ProfileSettings.get(
                                      'irrigation-failsafe-behaviour')]),
                      getActionTarget: (Mode irrigationMode) =>
                          irrigationMode == Mode.Automatic
                              ? ProfileSettings.get('irrigation-auto-threshold')
                                      .toInt()
                                      .toString() +
                                  '%'
                              : (irrigationMode == Mode.Scheduled
                                  ? '${_scheduler.irrigationTasks.length}'
                                  : ''),
                      manualPrompt: 'HOLD TILE TO RUN PUMP',
                      gradient: isDarkMode
                          ? const <Color>[
                              kIrrigationHighlightColorDark,
                              kIrrigationPrimaryColorDark
                            ]
                          : const <Color>[
                              kIrrigationHighlightColor,
                              kIrrigationPrimaryColor,
                            ],
                      onManualLongPressStart: _irrigationSubsystem.startPump,
                      onManualLongPressEnd: _irrigationSubsystem.stopPump,
                      onSettingsPressed: () => IrrigationPage(),
                    ),
                    const SizedBox(height: 20),
                    SubsystemTile(
                      subStream: _mqtt.lightStream,
                      pubStream: _mqtt.ledStream,
                      name: 'Lighting',
                      unit: 'W/m²',
                      initialMeasurement:
                          ProfileSettings.get('lighting-last-measurement'),
                      dangerCheck: (int measurement) =>
                          measurement <
                              ProfileSettings.get('lighting-fallback-low') ||
                          measurement >
                              ProfileSettings.get('lighting-fallback-high'),
                      indicator: AnimatedIconWrapper(
                          start: Icons.lightbulb_outline,
                          end: Icons.lightbulb,
                          initial:
                              ProfileSettings.get('lighting-grow-lamps-state'),
                          onOffStream: _mqtt.ledStream),
                      modeKey: 'lighting-mode',
                      getActionDescription: (Mode lightingMode) =>
                          lightingMode == Mode.Automatic
                              ? 'Keeping around'
                              : (lightingMode == Mode.Scheduled
                                  ? 'Grow lamps on between'
                                  : failsafeDescriptions[ProfileSettings.get(
                                      'lighting-failsafe-behaviour')]),
                      getActionTarget: (Mode lightingMode) => lightingMode ==
                              Mode.Automatic
                          ? '${ProfileSettings.get('lighting-auto-low').toInt()} - ${ProfileSettings.get('lighting-auto-high').toInt()}'
                                  .toString() +
                              'W/m²'
                          : (lightingMode == Mode.Scheduled
                              ? '${_scheduler.lightingFrom.format(context)} - ${_scheduler.lightingTo.format(context)}'
                              : ''),
                      manualPrompt: 'HOLD TILE TO TOGGLE GROW LAMPS',
                      gradient: isDarkMode
                          ? const <Color>[
                              kLightingHighlightColorDark,
                              kLightingPrimaryColorDark
                            ]
                          : const <Color>[
                              kLightingHighlightColor,
                              kLightingPrimaryColor,
                            ],
                      onManualLongPressStart: (Mode mode) =>
                          _lightingSubsystem.toggleGrowLamps(),
                      onManualLongPressEnd: (Mode m) {
                        /* nothing to do */
                      },
                      onSettingsPressed: () => LightingPage(),
                    ),
                    const SizedBox(height: 20),
                    SubsystemTile(
                      subStream: _mqtt.temperatureStream,
                      pubStream: _mqtt.servoStream,
                      name: 'Temperature',
                      unit: '°C',
                      initialMeasurement:
                          ProfileSettings.get('temperature-last-measurement'),
                      dangerCheck: (int measurement) =>
                          measurement <
                              ProfileSettings.get('temperature-fallback-low') ||
                          measurement >
                              ProfileSettings.get('temperature-fallback-high'),
                      indicator: AnimatedIconWrapper(
                          start: Icons.wb_sunny_outlined,
                          end: Icons.wb_cloudy,
                          initial: ProfileSettings.get(
                              'temperature-sunscreen-state'),
                          onOffStream: _mqtt.servoStream),
                      modeKey: 'temperature-mode',
                      getActionDescription: (Mode temperatureMode) =>
                          temperatureMode == Mode.Automatic
                              ? 'Keeping around'
                              : (temperatureMode == Mode.Scheduled
                                  ? 'Sunscreens between'
                                  : failsafeDescriptions[ProfileSettings.get(
                                      'temperature-failsafe-behaviour')]),
                      getActionTarget: (Mode temperatureMode) => temperatureMode ==
                              Mode.Automatic
                          ? '${ProfileSettings.get('temperature-auto-low').toInt()} - ${ProfileSettings.get('temperature-auto-high').toInt()}'
                                  .toString() +
                              '°C'
                          : (temperatureMode == Mode.Scheduled
                              ? '${_scheduler.temperatureFrom.format(context)} - ${_scheduler.temperatureTo.format(context)}'
                              : ''),
                      manualPrompt: 'HOLD TILE TO TOGGLE SUNSCREEN',
                      gradient: isDarkMode
                          ? const <Color>[
                              kTemperatureHighlightColorDark,
                              kTemperaturePrimaryColorDark
                            ]
                          : const <Color>[
                              kTemperatureHighlightColor,
                              kTemperaturePrimaryColor,
                            ],
                      onManualLongPressStart: (Mode mode) =>
                          _temperatureSubsystem.toggleSunscreen(),
                      onManualLongPressEnd: (Mode m) {
                        /* nothing to do */
                      },
                      onSettingsPressed: () => TemperaturePage(),
                    ),
                  ]),
            ))));
  }
}

// Refactored outside to make integration to generic subsystem tiles easier.
class Spinner extends StatefulWidget {
  final Stream<bool> onOffStream;
  final Widget child;

  Spinner({@required this.child, @required this.onOffStream});

  @override
  SpinnerState createState() => SpinnerState();
}

class SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  AnimationController animationController;

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.onOffStream.listen((bool event) {
      if (event) {
        animationController.repeat();
      } else {
        animationController.stop();
      }
    });
    return AnimatedBuilder(
        animation: animationController,
        child: Container(width: 24, height: 24, child: widget.child),
        builder: (BuildContext context, Widget widget) {
          return Transform.rotate(
              angle: animationController.value * 6.28, child: widget);
        });
  }
}

// This library is such a simpleton it requires setting state on each frame.
// I have tried going without setting state, it doesn't work.
// Therefore it has to live in its own wrapper class so we could avoid rebuilding
// the entire home screen.
class AnimatedIconWrapper extends StatefulWidget {
  final IconData start, end;
  final bool initial;
  final Stream<bool> onOffStream;

  AnimatedIconWrapper(
      {@required this.start,
      @required this.end,
      @required this.onOffStream,
      this.initial = false});

  @override
  AnimatedIconWrapperState createState() => AnimatedIconWrapperState();
}

class AnimatedIconWrapperState extends State<AnimatedIconWrapper>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _progress;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..addListener(() {
            // call `build` on animation progress
            setState(() {});
          });

    CurvedAnimation curve = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 1.0, curve: Curves.easeInOutBack),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    widget.onOffStream.listen((bool event) {
      if (event) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    if (widget.initial == true) _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleAnimatedIcon(
      color: Colors.white,
      // startIcon, endIcon, and progress are required
      startIcon: widget.start,
      endIcon: widget.end,
      progress: _progress,
      // use default transition
      // transitions: [Transitions.rotate_cw],
    );
  }
}

class SubsystemTile extends StatefulWidget {
  final Stream<String> subStream;
  final Stream<bool> pubStream;
  final String Function(Mode) getActionDescription, getActionTarget;
  final String name, unit, modeKey, manualPrompt;
  final Widget Function() onSettingsPressed;
  final Function(Mode) onManualLongPressStart, onManualLongPressEnd;
  final Function(int) dangerCheck;
  final Widget indicator;
  final List<Color> gradient;
  final int initialMeasurement;

  SubsystemTile(
      {this.subStream,
      this.initialMeasurement,
      this.pubStream,
      this.name,
      this.indicator,
      this.modeKey,
      this.unit,
      this.dangerCheck,
      this.getActionDescription,
      this.getActionTarget,
      this.manualPrompt,
      this.gradient,
      this.onSettingsPressed,
      this.onManualLongPressStart,
      this.onManualLongPressEnd});

  @override
  SubsystemTileState createState() => SubsystemTileState();
}

class SubsystemTileState extends State<SubsystemTile>
    with SingleTickerProviderStateMixin {
  final BorderRadius tileRadius = BorderRadius.all(Radius.circular(24));
  List<Color> _activatedGradient;
  bool isPressed = false, isDangerous = false;
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    _activatedGradient = widget.gradient
        .map((Color c) => c
            .withRed((c.red * 1.2).toInt().clamp(0, 255))
            .withGreen((c.green * 1.2).toInt().clamp(0, 255))
            .withBlue((c.blue * 1.2).toInt().clamp(0, 255)))
        .toList();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    ));
    widget.subStream.listen((numStr) {
      setState(() {
        isDangerous = widget.dangerCheck(int.parse(numStr));
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String modeStr = ProfileSettings.get(widget.modeKey);
    final Mode mode = EnumToString.fromString(Mode.values, modeStr);
    return ScaleTransition(
        scale: _animation,
        child: OpenContainer(
            closedColor: widget.gradient.last,
            middleColor: widget.gradient.last,
            transitionType: ContainerTransitionType.fade,
            transitionDuration: const Duration(seconds: 1),
            closedElevation: 10,
            openElevation: 12,
            closedShape: RoundedRectangleBorder(
              borderRadius: tileRadius,
              side: BorderSide.none,
            ),
            closedBuilder: (BuildContext context, VoidCallback action) {
              return GestureDetector(
                  child: AnimatedContainer(
                      duration: Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                          borderRadius: tileRadius,
                          gradient: RadialGradient(
                              colors: isPressed
                                  ? (isDangerous
                                      ? kDangerousGradientHighlight
                                      : _activatedGradient)
                                  : (isDangerous
                                      ? kDangerousGradient
                                      : widget.gradient),
                              center: Alignment.bottomCenter,
                              radius: 1.3)),
                      child: Stack(children: [
                        Container(
                            alignment: Alignment.topRight,
                            child: RawMaterialButton(
                                fillColor: Colors.white38,
                                elevation: 0,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                shape: const CircleBorder(),
                                onPressed: action,
                                child: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ))),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, left: 10, right: 10),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: 20, bottom: 20),
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(widget.name,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    color: Colors
                                                                        .white),
                                                                overflow:
                                                                    TextOverflow
                                                                        .fade),
                                                            SizedBox(width: 10),
                                                            widget.indicator
                                                          ]),
                                                      StreamBuilder(
                                                          stream:
                                                              widget.subStream,
                                                          builder: (context,
                                                              snapshot) {
                                                            switch (snapshot
                                                                .connectionState) {
                                                              case ConnectionState
                                                                  .waiting:
                                                                {
                                                                  if (widget
                                                                          .initialMeasurement !=
                                                                      -1) {
                                                                    return Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            widget.initialMeasurement.toString(),
                                                                            style:
                                                                                TextStyle(fontSize: 72, color: Colors.white38),
                                                                            overflow:
                                                                                TextOverflow.fade,
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 24,
                                                                              width: 24,
                                                                              child: CircularProgressIndicator(color: Colors.white54))
                                                                        ]);
                                                                  }
                                                                  return const SizedBox(
                                                                      height:
                                                                          100,
                                                                      child: Center(
                                                                          child:
                                                                              CircularProgressIndicator(color: Colors.white54)));
                                                                }
                                                              case ConnectionState
                                                                  .none:
                                                                {
                                                                  return const SizedBox(
                                                                      height:
                                                                          100,
                                                                      child: const Icon(
                                                                          Icons
                                                                              .warning,
                                                                          color:
                                                                              Colors.white));
                                                                }
                                                              case ConnectionState
                                                                  .active:
                                                                {
                                                                  return Text(
                                                                      snapshot
                                                                          .data
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              72,
                                                                          color:
                                                                              Colors.white));
                                                                }

                                                              default:
                                                                return const Text(
                                                                    'ERROR: Connection closed',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white));
                                                            }
                                                          }),
                                                      Text(widget.unit,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 15,
                                                                  color: Colors
                                                                      .white))
                                                    ]))),
                                        const SizedBox(
                                          width: 2,
                                          height: 120,
                                          child: const DecoratedBox(
                                              decoration: const BoxDecoration(
                                            color: Colors.white38,
                                            borderRadius:
                                                const BorderRadius.all(
                                                    const Radius.circular(2)),
                                          )),
                                        ),
                                        Expanded(
                                            child: Container(
                                                alignment: Alignment.center,
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                          modeStr.toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white)),
                                                      Text(
                                                          widget
                                                              .getActionDescription(
                                                                  mode),
                                                          overflow:
                                                              TextOverflow.fade,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 15,
                                                                  height: 2,
                                                                  color: Colors
                                                                      .white)),
                                                      Text(
                                                          widget
                                                              .getActionTarget(
                                                                  mode),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20,
                                                                  height: 2,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white)),
                                                    ]))),
                                      ])),
                              if (mode == Mode.Manual)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Text(widget.manualPrompt,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white54)))
                              else
                                const SizedBox(height: 10)
                            ])
                      ])),
                  onLongPressStart: (LongPressStartDetails details) {
                    if (mode == Mode.Manual) {
                      setState(() {
                        isPressed = true;
                        _controller.forward();
                        widget.onManualLongPressStart(Mode.Manual);
                      });
                    }
                  },
                  onLongPressEnd: (LongPressEndDetails details) {
                    if (mode == Mode.Manual) {
                      setState(() {
                        isPressed = false;
                        _controller.reverse();
                        widget.onManualLongPressEnd(Mode.Manual);
                      });
                    }
                  });
            },
            onClosed: (data) {
              setState(() {
                debugPrint('Updating home screen');
              });
            },
            openBuilder: (BuildContext context, VoidCallback action) =>
                widget.onSettingsPressed(),
            tappable: false));
  }
}
