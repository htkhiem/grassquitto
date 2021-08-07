import 'package:cron/cron.dart';

class SubsystemTask {
  int _id; // in database
  int _subsystem;
  String _cron;
  String _profile;
  int _data;
  // Corresponding ScheduledTask of the Cron backend.
  // Used for identifying which ScheduledTask to cancel if this task is deleted.
  // Starts off as null until the task has been scheduled by Cron.
  ScheduledTask _task;

  // Constructor
  SubsystemTask(this._subsystem, this._cron, this._data, this._profile);

  // Setter / Mapper
  SubsystemTask.map(dynamic obj) {
    this._id = obj['id'];
    this._subsystem = obj['subsystem'];
    this._cron = obj['cron'];
    this._data = obj['data'];
    this._profile = obj['profile'];
  }

  set id(int value) {
    _id = value;
  }

  set task(ScheduledTask value) {
    _task = value;
  }

  // Getter
  int get id => _id; // Needed for task editing and deletion
  int get subsystem => _subsystem;
  String get cron => _cron;
  int get data => _data;
  Schedule get schedule => Schedule.parse(_cron);
  String get profile => _profile;
  ScheduledTask get task => _task;

  // Convert from obj to mapping
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['subsystem'] = _subsystem;
    map['cron'] = _cron;
    map['data'] = _data;
    map['profile'] = _profile;
    // scheduledTask might change on each run, so don't store it
    return map;
  }
}
