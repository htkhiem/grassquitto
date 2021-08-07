/* User credentials */

class ServerRecord {
  int _id;
  String _username;
  String _address;
  String _apikey;
  String _profile; // associated username

  // Constructor
  ServerRecord(this._username, this._address, this._apikey, this._profile);

  ServerRecord.adafruitInit(this._username, this._apikey, this._profile)
      : this._address = 'io.adafruit.com';

  // Setter / Mapper
  ServerRecord.map(dynamic obj) {
    this._id = obj['id'];
    this._username = obj['username'];
    this._address = obj['address'];
    this._apikey = obj['apikey'];
    this._profile = obj['profile'];
  }

  // Getter
  int get id => _id;
  String get username => _username;
  String get address => _address;
  String get apikey => _apikey;
  String get profile => _profile;

  // Edit setter
  void setRecord(String username, String address, String apikey) {
    this._username = username;
    this._address = address;
    this._apikey = apikey;
  }

  void setApikey(String apikey) {
    this._apikey = apikey;
  }

  // Convert from obj to mapping
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    // do not add id when converting to map - SQLite takes care of rowId.
    map['username'] = _username;
    map['address'] = _address;
    map['apikey'] = _apikey;
    map['profile'] = _profile;
    return map;
  }
}
