// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/material.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cron/cron.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter_circular_slider/flutter_circular_slider.dart';

import 'package:grass_app/common.dart';
import 'package:grass_app/utils/utils.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/models/task.dart';
import 'package:grass_app/common_ui/empty_indicator.dart';
import 'package:grass_app/utils/scheduler.dart';

// Put here in common_ui as the profile settings page also uses it.

class IrrigationSchedulePage extends StatefulWidget {
  @override
  _IrrigationSchedulePageState createState() => _IrrigationSchedulePageState();
}

class _IrrigationSchedulePageState extends State<IrrigationSchedulePage>
    with SingleTickerProviderStateMixin {
  List<SubsystemTask> tasks;
  int count = 0;

  Scheduler _scheduler;
  @override
  void initState() {
    super.initState();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  Future<List<SubsystemTask>> getTasks() async {
    DatabaseService db = DatabaseService();
    List<SubsystemTask> result = await db.getTasks();
    // if (result.isEmpty) return [];
    // return result.where((SubsystemTask task) => task.subsystem == 0);
    return result;
  }

  void refresh(Function func) {
    getTasks().then((List<SubsystemTask> result) {
      tasks = result;
      count = tasks.length;
    });
    setState(func);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
        data: isDark ? kIrrigationThemeDataDark : kIrrigationThemeData,
        child: Scaffold(
            appBar: AppBar(title: Text('Scheduled tasks')),
            floatingActionButton: SpeedDial(
                icon: Icons.add,
                iconTheme: IconThemeData(color: Colors.white),
                activeIcon: Icons.cancel,
                visible: true,
                backgroundColor: kIrrigationPrimaryColor,
                children: <SpeedDialChild>[
                  SpeedDialChild(
                      child: Icon(Icons.repeat_one),
                      backgroundColor: Colors.teal,
                      labelBackgroundColor:
                          isDark ? Colors.white12 : Colors.white,
                      label: 'Daily',
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    IrrigationDailyTaskEditScreen()));
                      }),
                  SpeedDialChild(
                      child: Icon(Icons.view_week),
                      backgroundColor: Colors.amber,
                      labelBackgroundColor:
                          isDark ? Colors.white12 : Colors.white,
                      label: 'Weekly',
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    IrrigationWeeklyTaskEditScreen()));
                      }),
                  SpeedDialChild(
                      child: Icon(Icons.calendar_today_rounded),
                      backgroundColor: Colors.deepOrange,
                      labelBackgroundColor:
                          isDark ? Colors.white12 : Colors.white,
                      label: 'Monthly',
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    IrrigationMonthlyTaskEditScreen()));
                      }),
                ]),
            body: FutureBuilder(
                future: getTasks(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<SubsystemTask>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      tasks = snapshot.data;
                      count = tasks.length;
                    } else {
                      tasks = [];
                      count = 0;
                    }
                    if (count == 0)
                      return EmptyIndicator(
                        description:
                            'You don\'t have anything scheduled.\nTap the + button at the bottom-right corner to add one.',
                      );
                    tasks.sort((SubsystemTask a, SubsystemTask b) {
                      // Monthly (0) -> Weekly (1) -> Daily (2), then time, then duration
                      final Schedule scheduleA = a.schedule,
                          scheduleB = b.schedule;
                      final int typeA = scheduleA.days != null
                              ? 0
                              : (scheduleA.weekdays != null)
                                  ? 1
                                  : 2,
                          typeB = scheduleB.days != null
                              ? 0
                              : (scheduleB.weekdays != null)
                                  ? 1
                                  : 2;
                      if (typeA != typeB)
                        return typeA - typeB;
                      else if (typeA == 0) {
                        // Try to sort monthlies by the first day on which they are run
                        final int daysDiff =
                            scheduleA.days.first - scheduleB.days.first;
                        if (daysDiff != 0) return daysDiff;
                      } else if (typeA == 1) {
                        // Same for weeklies
                        final int daysDiff =
                            scheduleA.weekdays.first - scheduleB.weekdays.first;
                        if (daysDiff != 0) return daysDiff;
                      }
                      // Daily task, or all above fails.
                      final int timeA = scheduleA.hours.first * 60 +
                              scheduleA.minutes.first,
                          timeB = scheduleB.hours.first * 60 +
                              scheduleB.minutes.first;
                      if (timeA != timeB)
                        return timeA - timeB;
                      else
                        return a.data - b.data;
                    });
                    return AnimationLimiter(
                        child: ListView.builder(
                      itemCount: count,
                      padding: EdgeInsets.all(15),
                      itemBuilder: (BuildContext context, int idx) {
                        Icon leadingIcon;
                        Schedule parsedSchedule = tasks[idx].schedule;
                        String time =
                            parsedSchedule.hours[0].toString().padLeft(2, '0') +
                                ':' +
                                parsedSchedule.minutes[0]
                                    .toString()
                                    .padLeft(2, '0');
                        String title, subtitle;
                        if (parsedSchedule.weekdays != null) {
                          // Weekly task. Internally cron uses 1-7 with 1 being Monday.
                          title = Scheduler
                              .weekdayNames[parsedSchedule.weekdays.first % 7]
                              .substring(0, 3);
                          for (int i = 1;
                              i < parsedSchedule.weekdays.length;
                              ++i) {
                            title +=
                                ', ${Scheduler.weekdayNames[parsedSchedule.weekdays[i] % 7].substring(0, 3)}';
                            leadingIcon = Icon(Icons.view_week);
                          }
                          subtitle = 'Weekly at ' + time;
                        } else if (parsedSchedule.days != null) {
                          // Monthly task
                          title = monthDayOrdinal(parsedSchedule.days.first);
                          for (int i = 1; i < parsedSchedule.days.length; ++i) {
                            title +=
                                ', ' + monthDayOrdinal(parsedSchedule.days[i]);
                          }
                          subtitle = 'Monthly at ' + time;
                          leadingIcon = Icon(Icons.calendar_today_rounded);
                        } else {
                          // Daily task
                          title = time;
                          subtitle = 'Daily';
                          leadingIcon = Icon(Icons.repeat_one);
                        }
                        subtitle += ' for ${tasks[idx].data} seconds.';
                        return AnimationConfiguration.staggeredList(
                            position: idx,
                            duration: Duration(milliseconds: 400),
                            child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                    child: ListTile(
                                        title: Text(
                                          title,
                                          overflow: TextOverflow.fade,
                                        ),
                                        subtitle: Text(subtitle,
                                            overflow: TextOverflow.fade),
                                        leading: leadingIcon,
                                        trailing: TextButton(
                                            child: Icon(Icons.delete,
                                                color: Theme.of(context)
                                                    .accentColor),
                                            onPressed: () async {
                                              bool reallyDelete =
                                                  await showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          title: Text(
                                                              'Delete task?'),
                                                          content: Text(
                                                              'This cannot be undone.'),
                                                          actions: [
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            true),
                                                                child: Text(
                                                                    'DELETE',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red))),
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            false),
                                                                child: Text(
                                                                    'CANCEL'))
                                                          ],
                                                        );
                                                      });
                                              if (reallyDelete) {
                                                refresh(() {
                                                  _scheduler
                                                      .cancelIrrigationTask(
                                                          tasks[idx].id);
                                                });
                                              }
                                            })))));
                      },
                    ));
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator());
                  } else {
                    return Text('ERROR: Could not load tasks');
                  }
                })));
  }
}

class IrrigationDailyTaskEditScreen extends StatefulWidget {
  @override
  _IrrigationDailyTaskEditScreenState createState() =>
      _IrrigationDailyTaskEditScreenState();
}

class _IrrigationDailyTaskEditScreenState
    extends State<IrrigationDailyTaskEditScreen> {
  TimeOfDay time;
  int durationStep = 1;

  Scheduler _scheduler;
  @override
  void initState() {
    super.initState();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
        data: isDark ? kIrrigationThemeDataDark : kIrrigationThemeData,
        child: Scaffold(
            appBar: AppBar(title: Text('Edit daily task')),
            body: ListView(padding: EdgeInsets.all(15), children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DateTimePicker(
                    type: DateTimePickerType.time,
                    icon: Icon(Icons.access_time),
                    timeLabelText: 'Time to water',
                    //use24HourFormat: false,
                    //locale: Locale('en', 'US'),
                    onChanged: (val) => setState(() => time = TimeOfDay(
                        hour: int.parse(val.split(':')[0]),
                        minute: int.parse(val.split(':')[1]))),
                  ),
                  SizedBox(height: 25),
                  Text(
                    'Watering duration',
                    style: TextStyle(color: kIrrigationPrimaryColor),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 25),
                      child: SingleCircularSlider(12, durationStep,
                          height: 260.0,
                          width: 260.0,
                          primarySectors: 6,
                          secondarySectors: 12,
                          baseColor: isDark ? Colors.white12 : Colors.black12,
                          selectionColor:
                              kIrrigationPrimaryColor.withOpacity(0.3),
                          handlerColor: kIrrigationPrimaryColor,
                          handlerOutterRadius: 12.0,
                          onSelectionChange: (int beg, int end, int lap) {
                        setState(() {
                          durationStep = end;
                        });
                      },
                          child: Padding(
                            padding: const EdgeInsets.all(42.0),
                            child: Center(
                                child: Text('${durationStep * 5}s',
                                    style: TextStyle(fontSize: 36.0))),
                          )))
                ],
              ),
              ElevatedButton(
                  onPressed: time != null
                      ? (() {
                          int duration = durationStep * 5;
                          if (duration >= 60)
                            duration = 59; // avoid spilling over to next day
                          _scheduler.addIrrigationTask(
                              Schedule(
                                  hours: [time.hour],
                                  minutes: [time.minute],
                                  seconds: [0]),
                              duration);
                          Navigator.of(context).pop();
                        })
                      : null, // Disable button if no time has been selected
                  child: Text('Add task'))
            ])));
  }
}

class IrrigationWeeklyTaskEditScreen extends StatefulWidget {
  @override
  _IrrigationWeeklyTaskEditScreenState createState() =>
      _IrrigationWeeklyTaskEditScreenState();
}

class _IrrigationWeeklyTaskEditScreenState
    extends State<IrrigationWeeklyTaskEditScreen> {
  SubsystemTask task;

  TimeOfDay time;

  int durationStep = 1;

  List<bool> days = new List<bool>.filled(7, false);

  Scheduler _scheduler;
  @override
  void initState() {
    super.initState();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  Iterable<Widget> get weekdayChips sync* /* Synchronous generator */ {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    for (int i = 0; i < 7; ++i) {
      final String weekdayName = Scheduler.weekdayNames[i];
      yield Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: RawMaterialButton(
            shape: const CircleBorder(side: BorderSide.none),
            child: Text(weekdayName[0],
                style: TextStyle(color: days[i] ? Colors.white : Colors.black)),
            elevation: days[i] ? 10 : 0,
            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
            fillColor: isDark
                ? (days[i] ? kIrrigationPrimaryColor : Colors.white12)
                : (days[i] ? kIrrigationPrimaryColor : Colors.black12),
            onPressed: () {
              setState(() {
                days[i] = !days[i];
              });
            },
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
        data: isDark ? kIrrigationThemeDataDark : kIrrigationThemeData,
        child: Scaffold(
            appBar: AppBar(title: Text('Edit task')),
            body: ListView(padding: EdgeInsets.all(15), children: [
              DateTimePicker(
                type: DateTimePickerType.time,
                icon: Icon(Icons.access_time),
                timeLabelText: 'Time to water',
                //use24HourFormat: false,
                //locale: Locale('en', 'US'),
                onChanged: (val) => setState(() => time = TimeOfDay(
                    hour: int.parse(val.split(':')[0]),
                    minute: int.parse(val.split(':')[1]))),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Column(children: [
                    Text(
                      'Weekdays to water',
                      style: TextStyle(color: kIrrigationPrimaryColor),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: weekdayChips.toList())
                  ])),
              Text(
                'Watering duration',
                style: TextStyle(color: kIrrigationPrimaryColor),
                textAlign: TextAlign.center,
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: SingleCircularSlider(12, durationStep,
                      height: 260.0,
                      width: 260.0,
                      primarySectors: 6,
                      secondarySectors: 12,
                      baseColor: isDark ? Colors.white12 : Colors.black12,
                      selectionColor: kIrrigationPrimaryColor.withOpacity(0.3),
                      handlerColor: kIrrigationPrimaryColor,
                      handlerOutterRadius: 12.0,
                      onSelectionChange: (int beg, int end, int lap) {
                    setState(() {
                      durationStep = end;
                    });
                  },
                      child: Padding(
                        padding: const EdgeInsets.all(42.0),
                        child: Center(
                            child: Text('${durationStep * 5}s',
                                style: TextStyle(fontSize: 36.0))),
                      ))),
              ElevatedButton(
                  onPressed: (time != null &&
                          days.where((day) => day).length > 0)
                      ? (() {
                          int duration = durationStep * 5;
                          if (duration >= 60)
                            duration = 59; // avoid spilling over to next day
                          List<int> weekdayIndices = <int>[];
                          for (int i = 0; i < 7; ++i) {
                            if (days[i]) weekdayIndices.add(i);
                          }
                          _scheduler.addIrrigationTask(
                              Schedule(
                                  weekdays: weekdayIndices,
                                  hours: [time.hour],
                                  minutes: [time.minute],
                                  seconds: [0]),
                              duration);
                          Navigator.of(context).pop();
                        })
                      : null,
                  // Disable button if no time and/or weekday has been selected
                  child: Text('Add task'))
            ])));
  }
}

class IrrigationMonthlyTaskEditScreen extends StatefulWidget {
  @override
  _IrrigationMonthlyTaskEditScreenState createState() =>
      _IrrigationMonthlyTaskEditScreenState();
}

class _IrrigationMonthlyTaskEditScreenState
    extends State<IrrigationMonthlyTaskEditScreen> {
  SubsystemTask task;

  TimeOfDay time;

  int durationStep = 1;

  List<bool> days = new List<bool>.filled(31, false);

  Scheduler _scheduler;
  @override
  void initState() {
    super.initState();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  Iterable<Widget> get monthDayChips sync* /* Synchronous generator */ {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    for (int i = 0; i < 31; ++i) {
      yield Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: RawMaterialButton(
            shape: const CircleBorder(side: BorderSide.none),
            child: Text((i + 1).toString(),
                style: TextStyle(color: days[i] ? Colors.white : Colors.black)),
            elevation: days[i] ? 10 : 0,
            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
            fillColor: isDark
                ? (days[i] ? kIrrigationPrimaryColor : Colors.white12)
                : (days[i] ? kIrrigationPrimaryColor : Colors.black12),
            onPressed: () {
              setState(() {
                days[i] = !days[i];
              });
            },
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
        data: isDark ? kIrrigationThemeDataDark : kIrrigationThemeData,
        child: Scaffold(
            appBar: AppBar(title: Text('Edit task')),
            body: ListView(padding: EdgeInsets.all(15), children: [
              DateTimePicker(
                type: DateTimePickerType.time,
                icon: Icon(Icons.access_time),
                timeLabelText: 'Time to water',
                //use24HourFormat: false,
                //locale: Locale('en', 'US'),
                onChanged: (val) => setState(() => time = TimeOfDay(
                    hour: int.parse(val.split(':')[0]),
                    minute: int.parse(val.split(':')[1]))),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Column(children: [
                    Text(
                      'Days to water',
                      style: TextStyle(color: kIrrigationPrimaryColor),
                      textAlign: TextAlign.center,
                    ),
                    Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        direction: Axis.horizontal,
                        children: monthDayChips.toList())
                  ])),
              Text(
                'Watering duration',
                style: TextStyle(color: kIrrigationPrimaryColor),
                textAlign: TextAlign.center,
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: SingleCircularSlider(12, durationStep,
                      height: 260.0,
                      width: 260.0,
                      primarySectors: 6,
                      secondarySectors: 12,
                      baseColor: isDark ? Colors.white12 : Colors.black12,
                      selectionColor: kIrrigationPrimaryColor.withOpacity(0.3),
                      handlerColor: kIrrigationPrimaryColor,
                      handlerOutterRadius: 12.0,
                      onSelectionChange: (int beg, int end, int lap) {
                    setState(() {
                      durationStep = end;
                    });
                  },
                      child: Padding(
                        padding: const EdgeInsets.all(42.0),
                        child: Center(
                            child: Text('${durationStep * 5}s',
                                style: TextStyle(fontSize: 36.0))),
                      ))),
              ElevatedButton(
                  onPressed: (time != null &&
                          days.where((day) => day).length > 0)
                      ? (() {
                          int duration = durationStep * 5;
                          if (duration >= 60)
                            duration = 59; // avoid spilling over to next day
                          List<int> dayIndices = <int>[];
                          for (int i = 0; i < 31; ++i) {
                            if (days[i]) dayIndices.add(i + 1);
                          }
                          _scheduler.addIrrigationTask(
                              Schedule(
                                  days: dayIndices,
                                  hours: [time.hour],
                                  minutes: [time.minute],
                                  seconds: [0]),
                              duration);
                          Navigator.of(context).pop();
                        })
                      : null,
                  // Disable button if no time and/or weekday has been selected
                  child: Text('Add task'))
            ])));
  }
}
