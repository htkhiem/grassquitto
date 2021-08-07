/* Activity log, used to store data on activities performed over time span */

class ActivityLog {
  String _description;
  String
      _details; /* json-encoded string of the message(s) published to server */
  int _mode; /* 0 for automatic, 1 for scheduled, 2 for manual */
  String _category; /* "Temperature", "Light", "Irrigation", "General" */
  int _time; /* millisSinceEpoch */
  int _userId;

  // Constructor
  ActivityLog(this._description, this._details, this._mode, this._category,
      this._time, this._userId);

  // Setter / Mapper
  ActivityLog.map(dynamic obj) {
    this._description = obj['description'];
    this._details = obj['details'];
    this._mode = obj['mode'];
    this._category = obj['category'];
    this._time = obj['time'];
    this._userId = obj['userId'];
  }

  // Getter
  String get description => _description;
  String get details => _details;
  String get category => _category;
  int get mode => _mode;
  int get time => _time;
  int get userId => _userId;

  // Convert from obj to mapping
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['description'] = _description;
    map['details'] = _details;
    map['mode'] = _mode;
    map['category'] = _category;
    map['time'] = _time;
    map['userId'] = _userId;
    return map;
  }
}
