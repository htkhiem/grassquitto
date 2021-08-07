/* Record entity, to be used as object-oriented variables for database handling */

// From https://github.com/salmaahhmed/sqflite-flutter
// and https://github.com/yaostyle/Flutter-SQFLite-Example

class Record {
  int _measurement;
  int _time; // millisecondsSinceEpoch property of DateTime class
  int _userId;

  // Constructor
  Record(int _measurement, int _time, int _userId) {
    this._measurement = _measurement;
    this._time = _time;
  }

  // Setter / Mapper (mapping to obj)
  Record.map(dynamic obj) {
    this._measurement = obj['measurement'];
    this._time = obj['time'];
    this._userId = obj['userId'];
  }

  // Getter
  int get measurement => _measurement;
  int get time => _time;
  int get userId => _userId;

  // Convert from obj to mapping
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['measurement'] = _measurement;
    map['time'] = _time;
    map['userId'] = _userId;
    return map;
  }
}

// add supplemental attributes and methods for subclass, if any, here

class TemperatureRecord extends Record {
  TemperatureRecord(int _measurement, int _time, int _userId)
      : super(_measurement, _time, _userId);
  TemperatureRecord.map(dynamic obj) : super.map(obj);
}

class LightRecord extends Record {
  LightRecord(int _measurement, int _time, int _userId)
      : super(_measurement, _time, _userId);
  LightRecord.map(dynamic obj) : super.map(obj);
}

class MoistureRecord extends Record {
  MoistureRecord(int _measurement, int _time, int _userId)
      : super(_measurement, _time, _userId);
  MoistureRecord.map(dynamic obj) : super.map(obj);
}
