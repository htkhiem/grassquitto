/* User credentials */

class User {
  String _name;
  String _password; // password hashed as SHA-1 function
  int _id, _lightId, _soilId, _tempId, _ledId, _relayId, _servoId;

  // Constructor
  User.init(this._name, this._password, this._lightId, this._soilId,
      this._tempId, this._ledId, this._relayId, this._servoId);

  // Setter / Mapper
  User.map(dynamic obj) {
    this._id = obj["id"];
    this._name = obj['name'];
    this._password = obj['password'];
    this._lightId = obj['lightId'];
    this._soilId = obj['soilId'];
    this._tempId = obj['tempId'];
    this._ledId = obj['ledId'];
    this._relayId = obj['relayId'];
    this._servoId = obj['servoId'];
  }

  // Getter
  int get id => _id;
  String get name => _name;
  String get password => _password;
  int get lightId => _lightId;
  int get soilId => _soilId;
  int get tempId => _tempId;
  int get ledId => _ledId;
  int get relayId => _relayId;
  int get servoId => _servoId;

  // Convert from obj to mapping
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    // Do not pass id back in
    map['name'] = _name;
    map['password'] = _password;
    map['lightId'] = _lightId;
    map['soilId'] = _soilId;
    map['tempId'] = _tempId;
    map['ledId'] = _ledId;
    map['relayId'] = _relayId;
    map['servoId'] = _servoId;
    return map;
  }
}
