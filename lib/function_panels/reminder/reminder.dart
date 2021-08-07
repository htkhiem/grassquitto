// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:date_format/date_format.dart';
import 'package:intl/intl.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:grass_app/utils/database.dart';
import 'package:grass_app/utils/scheduler.dart';

import 'package:grass_app/models/reminder.dart';
import 'package:grass_app/common_ui/empty_indicator.dart';
import 'package:grass_app/utils/utils.dart';

class ReminderPage extends StatefulWidget {
  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  DatabaseService _db;
  List<Reminder> upcoming = [], scheduled = [], overdue = [];

  Scheduler _scheduler;
  @override
  void initState() {
    super.initState();
    _db = GetIt.I.get<DatabaseService>();
    _scheduler = GetIt.I.get<Scheduler>();
  }

  void getReminders() {
    upcoming = [];
    scheduled = [];
    overdue = [];
    final Future<List<Reminder>> futureList = _db.getReminders();
    futureList.then((List<Reminder> result) {
      setState(() {
        result.forEach((Reminder reminder) {
          int diff = reminder.time - DateTime.now().millisecondsSinceEpoch;
          if (diff > 0 && diff < Duration.millisecondsPerDay * 2)
            this.upcoming.add(reminder);
          else if (diff < 0)
            this.overdue.add(reminder);
          else
            this.scheduled.add(reminder);
        });
      });
    });
  }

  void refresh(Function func) {
    getReminders();
    setState(func);
  }

  List<Widget> buildReminderList(List<Reminder> reminders) {
    if (reminders.length > 0)
      return reminders
          .map((Reminder reminder) => ListTile(
                title: Text(
                    reminder.title != null ? reminder.title : '<UNKNOWN>',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.description != null
                            ? reminder.description
                            : '<UNKNOWN>',
                      ),
                      Text(msTimeToString(reminder.time))
                    ]),
                trailing: TextButton(
                  child: Icon(Icons.done),
                  onPressed: () async {
                    _scheduler.cancelReminder(reminder.id);
                    refresh(() {});
                  },
                ),
              ))
          .toList();
    else
      return [
        EmptyIndicator(
          description: 'There is no reminder here.',
        )
      ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _db.getReminders(),
        builder:
            (BuildContext context, AsyncSnapshot<List<Reminder>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              upcoming = [];
              scheduled = [];
              overdue = [];
              snapshot.data.forEach((Reminder reminder) {
                int diff =
                    reminder.time - DateTime.now().millisecondsSinceEpoch;
                if (diff > 0 && diff < Duration.millisecondsPerDay * 2)
                  this.upcoming.add(reminder);
                else if (diff < 0)
                  this.overdue.add(reminder);
                else
                  this.scheduled.add(reminder);
              });
              return ListView(children: [
                Column(children: <Widget>[
                  ExpandableSettingsTile(
                      title: 'Upcoming',
                      children: buildReminderList(this.upcoming))
                ]),
                ExpandableSettingsTile(
                    title: 'Overdue',
                    children: buildReminderList(this.overdue)),
                ExpandableSettingsTile(
                    title: 'Scheduled',
                    children: buildReminderList(this.scheduled)),
              ]);
            } else {
              return EmptyIndicator(
                description:
                    'No reminder set.\nTap the + at the bottom-right '
                        'of the screen to add one.',
              );
            }
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
                width: 200, height: 200, child: CircularProgressIndicator());
          } else {
            return Text("ERROR: Could not load servers");
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddNewReminderPage()));
          refresh(() {});
        },
      ),
    );
  }
}

class AddNewReminderPage extends StatefulWidget {
  @override
  _AddNewReminderPageState createState() => _AddNewReminderPageState();
}

class _AddNewReminderPageState extends State<AddNewReminderPage> {
  String _hour, _minute, _time;

  String dateTime;

  DateTime selectedDate = DateTime.now();
  int selectedTime = DateTime.now().millisecondsSinceEpoch;

  TimeOfDay initTime =
      TimeOfDay(hour: DateTime.now().hour, minute: DateTime.now().minute);

  String title, desc;

  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        initialDatePickerMode: DatePickerMode.day,
        firstDate: DateTime(DateTime.now().year),
        lastDate: DateTime(DateTime.now().year + 200));
    if (picked != null)
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat.yMd().format(selectedDate);
      });
  }

  Future<void> saveReminder(Reminder reminder) async {
    DatabaseService db = DatabaseService();
    db.saveReminder(reminder);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: initTime,
    );
    if (picked != null)
      setState(() {
        initTime = picked;
        _hour = initTime.hour.toString();
        _minute = initTime.minute.toString();
        _time = _hour + ' : ' + _minute;
        selectedTime = DateTime(selectedDate.year, selectedDate.month,
                selectedDate.day, initTime.hour, initTime.minute)
            .millisecondsSinceEpoch;
        _timeController.text = _time;
        _timeController.text = formatDate(
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
                initTime.hour, initTime.minute),
            [hh, ':', nn, " ", am]).toString();
      });
  }

  Scheduler _scheduler;

  @override
  void initState() {
    _dateController.text = DateFormat.yMd().format(DateTime.now());

    _timeController.text = formatDate(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
            DateTime.now().hour, DateTime.now().minute),
        [hh, ':', nn, " ", am]).toString();
    _scheduler = GetIt.I.get<Scheduler>();
    super.initState();
  }

  Widget build(BuildContext context) {
    // String title, desc;
    dateTime = DateFormat.yMd().format(DateTime.now());
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Date time picker'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 30)),
                Text(
                  'Choose date',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                InkWell(
                  onTap: () {
                    _selectDate(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 30),
                    alignment: Alignment.center,
                    child: TextFormField(
                      style: TextStyle(fontSize: 40),
                      textAlign: TextAlign.center,
                      enabled: false,
                      keyboardType: TextInputType.text,
                      controller: _dateController,
                      decoration: InputDecoration(
                          disabledBorder:
                              UnderlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.only(top: 0.0)),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: <Widget>[
                Text(
                  'Choose time',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                InkWell(
                  onTap: () {
                    _selectTime(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 30),
                    alignment: Alignment.center,
                    child: TextFormField(
                      style: TextStyle(fontSize: 40),
                      textAlign: TextAlign.center,
                      enabled: false,
                      keyboardType: TextInputType.text,
                      controller: _timeController,
                      decoration: InputDecoration(
                          disabledBorder:
                              UnderlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.all(5)),
                    ),
                  ),
                ),
              ],
            ),
            Column(children: [
              TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.assignment_rounded),
                    hintText: 'What should we remind you of?',
                    labelText: 'Title',
                  ),
                  onChanged: (String value) => setState(() {
                        title = value;
                      }))
            ]),
            Column(children: [
              TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.edit),
                    hintText: 'Add some notes (optional)',
                    labelText: 'Description',
                  ),
                  onChanged: (String value) => setState(() {
                        desc = value;
                      })),
            ]),
            Expanded(
                child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text(
                          'SAVE',
                        ),
                        onPressed: () async {
                          // Check info
                          if (title == null || title.length == 0) {
                            title = 'Untitled';
                          }
                          if (desc == null || desc.length == 0) {
                            desc = 'No description given.'; // This is optional,
                          }
                          _scheduler.addReminder(
                              title,
                              desc,
                              DateTime.fromMillisecondsSinceEpoch(
                                  selectedTime));
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  )
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
