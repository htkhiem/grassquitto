import 'dart:async';

class Reminder {
  int _id;
  String _title;
  String _description;
  int _time;
  int _userID;
  Timer _timer;

  Reminder(String _title, String _description, int _time, int _userID) {
    this._id = _id;
    this._title = _title;
    this._description = _description;
    this._time = _time;
    this._userID = _userID;
    this._timer = _timer;
  }

  set id(int value) {
    _id = value;
  }

  set timer(Timer value) {
    _timer = value;
  }

  Reminder.map(dynamic obj) {
    this._id = obj['id'];
    this._title = obj['title'];
    this._description = obj['description'];
    this._time = obj['time'];
    this._userID = obj['userID'];
  }

  int get id => _id;
  String get title => _title;
  String get description => _description;
  int get time => _time;
  int get userID => _userID;
  Timer get timer => _timer;

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    // do not write id and future back in
    map['title'] = _title;
    map['description'] = _description;
    map['time'] = _time;
    map['userID'] = _userID;
    return map;
  }
}
