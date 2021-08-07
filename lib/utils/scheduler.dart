// DIP
import 'package:grass_app/utils/database.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:cron/cron.dart';

import 'package:grass_app/utils/subsystems.dart';
import 'package:grass_app/utils/settings.dart';
import 'package:grass_app/utils/notification.dart';
import 'package:grass_app/utils/authority.dart';
import 'package:grass_app/models/task.dart';
import 'package:grass_app/models/reminder.dart';
import 'package:grass_app/common.dart';

@singleton
class Scheduler {
  final DatabaseService _db;
  final IrrigationSubsystem _irrigationSubsystem;
  final LightingSubsystem _lightingSubsystem;
  final TemperatureSubsystem _temperatureSubsystem;
  Scheduler(this._db, this._irrigationSubsystem, this._lightingSubsystem,
      this._temperatureSubsystem);
  static final List<String> weekdayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  List<Reminder> reminders;

  Cron cron = Cron();

  Future<void> pumpAction(int data) async {
    if (ProfileSettings.get('irrigation-mode') == 'Scheduled') {
      _irrigationSubsystem.startPump(Mode.Scheduled);
      if (ProfileSettings.get('scheduled-notifications-in-app'))
        NotificationService().displayBasicNotification(
            'Pumping!', 'Pump started according to irrigation schedule.');
    }
    Timer(Duration(seconds: data), () {
      if (ProfileSettings.get('irrigation-mode') == 'Scheduled') {
        _irrigationSubsystem.stopPump(Mode.Scheduled);
        if (ProfileSettings.get('scheduled-notifications-in-app'))
          NotificationService().displayBasicNotification(
              'Pumped!', 'Ran for ${data}s according to schedule.');
      }
    });
  }

  Future<void> growLampsAction(int data) async {
    if (ProfileSettings.get('lighting-mode') == 'Scheduled') {
      if (ProfileSettings.get('scheduled-notifications-in-app'))
        NotificationService().displayBasicNotification(
            'Lamps on!', 'Grow lamps turned on according to schedule.');
      _lightingSubsystem.growLampsOn(Mode.Scheduled);
    }
    Timer(Duration(seconds: data), () {
      if (ProfileSettings.get('lighting-mode') == 'Scheduled') {
        if (ProfileSettings.get('scheduled-notifications-in-app'))
          NotificationService().displayBasicNotification(
              'Lamps off!', 'Grow lamps turned off according to schedule.');
        _lightingSubsystem.growLampsOff(Mode.Scheduled);
      }
    });
  }

  Future<void> sunscreenAction(int data) async {
    if (ProfileSettings.get('temperature-mode') == 'Scheduled') {
      if (ProfileSettings.get('scheduled-notifications-in-app'))
        NotificationService().displayBasicNotification(
            'Shaded!', 'Sunscreens deployed according to schedule.');
      _temperatureSubsystem.deploySunscreen(Mode.Scheduled);
    }
    Timer(Duration(seconds: data), () {
      if (ProfileSettings.get('temperature-mode') == 'Scheduled') {
        if (ProfileSettings.get('scheduled-notifications-in-app'))
          NotificationService().displayBasicNotification(
              'Shine on!', 'Sunscreens retracted according to schedule.');
        _temperatureSubsystem.retractSunscreen(Mode.Scheduled);
      }
    });
  }

  Future<void> remind(String title, String description) async {
    // Just post a local notification
    NotificationService()
        .displayBasicNotification('Reminder: $title', description);
  }

  List<SubsystemTask> irrigationTasks = [];
  SubsystemTask temperatureTask, lightingTask;

  // For quicker querying.
  TimeOfDay temperatureFrom, temperatureTo, lightingFrom, lightingTo;

  String cronScheduleToString(Schedule schedule) {
    // Only supports one second, minute, hour and month-day each.
    // Multiple week-days are supported, but if week-days are specified,
    // month-days will be ignored and vice versa.
    // Hour, minute and second MUST be specified.
    String result =
        '${schedule.seconds[0]} ${schedule.minutes[0]} ${schedule.hours[0]} ';
    if (schedule.weekdays != null) {
      result += '* * ${schedule.weekdays[0]}';
      for (int i = 1; i < schedule.weekdays.length; ++i) {
        result += ',${schedule.weekdays[i]}';
      }
    } else if (schedule.days != null) {
      result += '${schedule.days[0]}';
      for (int i = 1; i < schedule.days.length; ++i) {
        result += ',${schedule.days[i]}';
      }
      result += ' * *';
    } else {
      // Everyday
      result += '* * *';
    }
    return result;
  }

  // This has been upgraded to also handle reminders
  Future<void> init() async {
    // Cancel all current tasks, if any.
    //List<SubsystemTask> tasks;
    if (irrigationTasks != null)
      for (int i = 0; i < irrigationTasks.length; ++i) {
        irrigationTasks[i].task.cancel();
      }
    // Start over
    List<SubsystemTask> tasks = await _db.getTasks();
    for (int i = 0; i < tasks.length; ++i) {
      Schedule schedule = tasks[i].schedule;
      switch (tasks[i].subsystem) {
        case 0:
          {
            // Irrigation
            ScheduledTask task =
                cron.schedule(schedule, () => pumpAction(tasks[i].data));
            tasks[i].task = task;
            irrigationTasks.add(tasks[i]);
            break;
          }
        case 1:
          {
            // Lighting
            ScheduledTask task =
                cron.schedule(schedule, () => growLampsAction(tasks[i].data));
            tasks[i].task = task;
            lightingTask = tasks[i];
            lightingFrom =
                TimeOfDay(hour: schedule.hours[0], minute: schedule.minutes[0]);
            int hourDiff = (tasks[i].data + lightingFrom.minute * 60) ~/
                Duration.secondsPerHour;
            lightingTo = TimeOfDay(
                hour: (lightingFrom.hour + hourDiff) % 24,
                minute: lightingFrom.minute +
                    (tasks[i].data - hourDiff * 3600) ~/ 60);
            break;
          }
        case 2:
          {
            // Temperature
            ScheduledTask task =
                cron.schedule(schedule, () => sunscreenAction(tasks[i].data));
            tasks[i].task = task;
            temperatureTask = tasks[i];
            temperatureFrom =
                TimeOfDay(hour: schedule.hours[0], minute: schedule.minutes[0]);
            int hourDiff = (tasks[i].data + temperatureFrom.minute * 60) ~/
                Duration.secondsPerHour;
            temperatureTo = TimeOfDay(
                hour: (temperatureFrom.hour + hourDiff) % 24,
                minute: temperatureFrom.minute +
                    (tasks[i].data - hourDiff * 3600) ~/ 60);
            break;
          }
        default:
          {}
      }
    }
    // Initialise default values
    if (temperatureFrom == null) {
      temperatureFrom = TimeOfDay(hour: 11, minute: 0);
    }
    if (temperatureTo == null) {
      temperatureTo = TimeOfDay(hour: 16, minute: 0);
    }
    if (lightingFrom == null) {
      lightingFrom = TimeOfDay(hour: 18, minute: 0);
    }
    if (lightingTo == null) {
      lightingTo = TimeOfDay(hour: 6, minute: 0);
    }

    // Register reminders in the future
    reminders = await _db.getReminders();
    for (int i = 0; i < reminders.length; ++i) {
      DateTime remindAt =
          DateTime.fromMillisecondsSinceEpoch(reminders[i].time);
      if (remindAt.isAfter(DateTime.now())) {
        reminders[i].timer = Timer(remindAt.difference(DateTime.now()),
            () => remind(reminders[i].title, reminders[i].description));
      }
    }
  }

  void reset() {
    reminders.forEach((Reminder reminder) {
      if (reminder.timer != null) {
        reminder.timer.cancel();
      }
    });
    reminders.clear();
    irrigationTasks.forEach((SubsystemTask task) {
      task.task.cancel();
    });
    if (temperatureTask != null) temperatureTask.task.cancel();
    if (lightingTask != null) lightingTask.task.cancel();
  }

  // from and to are minutes from daybreak.
  void setSunscreenSchedule(int from, int to) {
    final int duration =
        (to < from) ? (to + Duration.secondsPerDay) - from : to - from;
    // Cancel the old sunscreen task
    if (temperatureTask != null) {
      temperatureTask.task.cancel();
      _db.deleteTask(temperatureTask.id);
    }

    // Create a new SubsystemTask object and schedule its two cron tasks.
    // Temperature subsystem tasks are daily.
    final int startHour = (from ~/ 3600);
    final int startMin = (from % 3600) ~/ 60;
    final int startSec = from - 3600 * startHour - 60 * startMin;
    final String startCron = '$startSec $startMin $startHour * * *';
    temperatureTask =
        SubsystemTask(2, startCron, duration, Authority.currentProfile.name);
    temperatureTask.task = cron.schedule(
        Schedule.parse(startCron), () => sunscreenAction(duration));

    // Update database
    _db.saveTask(temperatureTask).then((int dbId) {
      temperatureTask.id = dbId;
    });

    // Cache parsed results
    temperatureFrom = TimeOfDay(hour: startHour, minute: startMin);
    final int hourDiff = (duration + startMin * 60) ~/ Duration.secondsPerHour;
    temperatureTo = TimeOfDay(
        hour: (temperatureFrom.hour + hourDiff) % 24,
        minute: temperatureFrom.minute + (duration - hourDiff * 3600) ~/ 60);
  }

  // from and to are minutes from daybreak.
  void setGrowLampsSchedule(int from, int to) {
    final int duration =
        (to < from) ? (to + Duration.secondsPerDay) - from : to - from;
    // Cancel the old sunscreen task
    if (lightingTask != null) {
      lightingTask.task.cancel();
      _db.deleteTask(lightingTask.id);
    }

    // Create a new SubsystemTask object and schedule its two cron tasks.
    // Lighting subsystem tasks are daily.
    final int startHour = (from ~/ 3600);
    final int startMin = (from % 3600) ~/ 60;
    final int startSec = from - 3600 * startHour - 60 * startMin;
    String startCron = '$startSec $startMin $startHour * * *';
    lightingTask =
        SubsystemTask(1, startCron, duration, Authority.currentProfile.name);
    lightingTask.task = cron.schedule(
        Schedule.parse(startCron), () => growLampsAction(duration));

    // Update database
    _db.saveTask(lightingTask).then((int dbId) {
      lightingTask.id = dbId;
    });

    // Cache parsed results
    lightingFrom = TimeOfDay(hour: startHour, minute: startMin);
    final int hourDiff = (duration + startMin * 60) ~/ Duration.secondsPerHour;
    lightingTo = TimeOfDay(
        hour: (lightingFrom.hour + hourDiff) % 24,
        minute: lightingFrom.minute + (duration - hourDiff * 3600) ~/ 60);
  }

  // duration in seconds
  void addIrrigationTask(Schedule schedule, int duration) {
    SubsystemTask subsystemTask = SubsystemTask(
        0,
        cronScheduleToString(schedule),
        duration,
        Authority.currentProfile.name);
    subsystemTask.task = cron.schedule(schedule, () => pumpAction(duration));
    // Update database
    _db.saveTask(subsystemTask).then((int dbId) {
      subsystemTask.id = dbId;
    });
    // Save to ref list
    irrigationTasks.add(subsystemTask);
  }

  void cancelIrrigationTask(int sstId) {
    int taskListIdx =
        irrigationTasks.indexWhere((SubsystemTask task) => task.id == sstId);
    irrigationTasks[taskListIdx].task.cancel();

    // Delete from DB
    _db.deleteTask(irrigationTasks[taskListIdx].id);

    // Delete from ref list
    irrigationTasks.removeAt(taskListIdx);
  }

  void addReminder(String title, String description, DateTime time) {
    Reminder reminder = Reminder(title, description,
        time.millisecondsSinceEpoch, Authority.currentProfile.id);
    reminder.timer = Timer(
        time.difference(DateTime.now()), () => remind(title, description));
    _db.saveReminder(reminder).then((dbId) {
      reminder.id = dbId;
      reminders.add(reminder);
    });
  }

  // Also works for reminders that are already due (i.e. when ticking as Complete)
  // Takes in DB index!
  void cancelReminder(int dbId) {
    Reminder reminder = reminders.firstWhere((element) => element.id == dbId);
    // Cancel it if it's in the future
    if (reminder.timer != null) {
      reminder.timer.cancel();
    }
    // Remove from DB
    _db.deleteReminder(dbId);
    // Remove from runtime
    reminders.remove(reminder);
  }
}
