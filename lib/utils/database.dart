// DIP
import 'package:injectable/injectable.dart';

// Path handling
import 'package:grass_app/common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io' as io;

import 'package:grass_app/utils/authority.dart';

// Sqlite utility
import 'package:sqflite/sqflite.dart';
import '../models/record.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../models/server.dart';
import '../models/reminder.dart';
import '../common.dart';

/* DatabaseService is a utility class for handling the app's database in general
to handle SQL database transaction. At the moment, all the methods for each
is defined to insert/update/delete or retrieve data to and from the database */

@singleton
class DatabaseService {
  Database _db;

  // Getter for db entity
  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }

    _db = await initDb();
    return _db;
  }

  // Initialize database upon installing
  initDb() async {
    io.Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentDirectory.path, 'main.db');
    Database ourDb =
        await openDatabase(path, version: kVersion, onCreate: _onCreate);
    // Hacky migration, I need TypeORM in my life
    await ourDb.execute(
        'CREATE TABLE IF NOT EXISTS Reminders(id INTEGER PRIMARY KEY, title '
        'TEXT, description TEXT, time INTEGER, isDone INTEGER, '
        'userId INTEGER)');
    // await ourDb.execute('ALTER TABLE ActivityLogs ADD COLUMN details TEXT');
    return ourDb;
  }

  // Optional table reset functionality in case the old models fail
  resetTables() async {
    var dbClient = await db;
    await dbClient.execute('DROP TABLE IF EXISTS ActivityLogs');
    await dbClient.execute('DROP TABLE IF EXISTS TemperatureRecords');
    await dbClient.execute('DROP TABLE IF EXISTS LightRecords');
    await dbClient.execute('DROP TABLE IF EXISTS MoistureRecords');
    await dbClient.execute('DROP TABLE IF EXISTS Users');
    await dbClient.execute('DROP TABLE IF EXISTS Schedules');
    await dbClient.execute('DROP TABLE IF EXISTS ServerRecords');
    await dbClient.execute('DROP TABLE IF EXISTS Reminders');

    _onCreate(dbClient, kVersion);
  }

  // Creating tables
  // Schedule entries.
  // subsystem INTEGER: 0 for irrigation, 1 for lighting, 2 for temperature
  // cron TEXT: scheduling info in crontab syntax.
  // data INTEGER: interpreted differently based on subsystem
  //    - irrigation: duration of each irrigation (in seconds)
  //    - lighting: how long to keep grow lamps on (in seconds).
  //    - temperature: how long to keep the sunscreen deployed (in seconds).
  // the 'from' time for these tasks are defined in the cron string.
  void _onCreate(Database db, int version) async {
    await db.execute(
        'CREATE TABLE TemperatureRecords(id INTEGER PRIMARY KEY, measurement '
        'INTEGER, time INTEGER, userId INTEGER)');
    await db.execute(
        'CREATE TABLE LightRecords(id INTEGER PRIMARY KEY, measurement '
        'INTEGER, time INTEGER, userId INTEGER)');
    await db.execute(
        'CREATE TABLE MoistureRecords(id INTEGER PRIMARY KEY, measurement '
        'INTEGER, time INTEGER, userId INTEGER)');
    await db.execute(
        'CREATE TABLE ActivityLogs(id INTEGER PRIMARY KEY, description TEXT, '
        'details TEXT, mode INTEGER, category TEXT, time INTEGER, userId '
        'INTEGER)');
    await db.execute(
        'CREATE TABLE Schedules(id INTEGER PRIMARY KEY, subsystem INTEGER, '
        'cron TEXT, data INTEGER, profile TEXT)');
    await db
        .execute('CREATE TABLE Users(id INTEGER PRIMARY KEY, name TEXT UNIQUE, '
            'password TEXT, lightId INT, soilId, tempId INT, ledId INT, '
            'relayId INT, servoId INT)');
    await db
        .execute('CREATE TABLE Reminders(id INTEGER PRIMARY KEY, title TEXT, '
            'description TEXT, time INTEGER, isDone INTEGER, userId '
            'INTEGER)');
    await db
        .execute('CREATE TABLE ServerRecords(id INTEGER PRIMARY KEY, username '
            'TEXT, address TEXT, apikey TEXT, profile TEXT)');
  }

  /* TEMPERATURE RECORDS TABLE */

  // insertion
  Future<int> saveTemp(TemperatureRecord record) async {
    final Database dbClient = await db;
    final Map<String, dynamic> insertMap = record.toMap();
    insertMap['userId'] = Authority.currentProfile.id;
    int res = await dbClient.insert('TemperatureRecords', insertMap);
    return res;
  }

  // retrieval
  Future<List<TemperatureRecord>> getTemp() async {
    // Get a reference to the database.
    final Database dbClient = await db;

    List<TemperatureRecord> result = <TemperatureRecord>[];

    // Query the table for all temp rec.
    final List<Map<String, dynamic>> maps = await dbClient.query(
        'TemperatureRecords',
        where: 'userId=?',
        whereArgs: <int>[Authority.currentProfile.id]);
    // Convert into list of model objects
    if (maps.length > 0) {
      maps.forEach((Map<String, dynamic> obj) {
        result.add(TemperatureRecord.map(obj));
      });
    }
    return result;
  }

  // Union of all sensor tables
  Future<List<DateTime>> getAvailableSensorTimeRange() async {
    final Database dbClient = await db;
    final List<Map<String, dynamic>> dbObj = await dbClient
        .rawQuery('SELECT MIN(time) AS xmin, MAX(time)AS xmax, userId FROM '
            '(SELECT time, userId FROM $kTemperatureDBTable UNION '
            'SELECT time,userId FROM $kLightDBTable UNION '
            'SELECT time,userId FROM $kMoistureDBTable) '
            'WHERE userId = ${Authority.currentProfile.id}');
    if (dbObj.length != 0)
      return [
        DateTime.fromMillisecondsSinceEpoch(dbObj[0]['xmin']),
        DateTime.fromMillisecondsSinceEpoch(dbObj[0]['xmax'])
      ];
    return [];
  }

  // Retrieval
  Future<List<Record>> getMeasurements(String tableName,
      {int startMs = 0, int endMs = -1}) async {
    final Database dbClient = await db;
    List<Record> result = [];
    final List<Map<String, dynamic>> maps = await dbClient
        .rawQuery('SELECT measurement, time FROM $tableName WHERE time >= '
            '$startMs AND time <= $endMs AND userId='
            '${Authority.currentProfile.id};');
    if (maps.length > 0) {
      result = maps.map((obj) => Record.map(obj)).toList();
    }
    return result;
  }

  Future<int> getLatestStoredMeasurement(String tableName) async {
    final Database dbClient = await db;
    final List<Map<String, Object>> dbObj =
        await dbClient.rawQuery('SELECT MAX(time), * from $tableName '
            'WHERE userId=${Authority.currentProfile.id}');
    return dbObj[0]['measurement'];
  }

  Future<List<double>> getValueRange(String tableName,
      {int startMs = 0, int endMs = -1}) async {
    final Database dbClient = await db;
    final List<Map<String, Object>> dbObj = await dbClient
        .rawQuery('SELECT MIN(measurement) AS ymin, MAX(measurement) '
            'AS ymax FROM $tableName WHERE time >= $startMs '
            'AND time <= $endMs AND userId=${Authority.currentProfile.id}');
    final int ymin = dbObj[0]['ymin'], ymax = dbObj[0]['ymax'];
    if (ymin == null) return [0.0, 1.0];
    return [ymin.toDouble(), ymax.toDouble()];
  }

  // deletion
  Future<int> deleteTemp(int id) async {
    Database dbClient = await db;
    int res = await dbClient
        .delete('TemperatureRecords', where: 'id=?', whereArgs: [id]);
    return res;
  }

  /* LIGHT RECORDS TABLE */

  // insertion
  Future<int> saveLight(LightRecord record) async {
    Database dbClient = await db;
    final Map<String, dynamic> insertMap = record.toMap();
    insertMap['userId'] = Authority.currentProfile.id;
    int res = await dbClient.insert('LightRecords', insertMap);
    return res;
  }

  // retrieval
  Future<List<LightRecord>> getLight() async {
    // Get a reference to the database.
    final Database dbClient = await db;
    List<LightRecord> result = [];

    // Query the table for all temp rec.
    final List<Map<String, dynamic>> maps = await dbClient.query('LightRecords',
        where: 'userId=?', whereArgs: [Authority.currentProfile.id]);
    // Convert into list of model objects
    if (maps.length > 0) {
      maps.forEach((Map<String, dynamic> obj) {
        result.add(LightRecord.map(obj));
      });
    }
    return result;
  }

  // deletion
  Future<int> deleteLight(int id) async {
    Database dbClient = await db;
    int res =
        await dbClient.delete('LightRecords', where: 'id=?', whereArgs: [id]);
    return res;
  }

  /* MOISTURE RECORDS TABLE */

  // insertion
  Future<int> saveMoisture(MoistureRecord record) async {
    Database dbClient = await db;
    final Map<String, dynamic> insertMap = record.toMap();
    insertMap['userId'] = Authority.currentProfile.id;
    int res = await dbClient.insert('MoistureRecords', insertMap);
    return res;
  }

  // retrieval
  Future<List<MoistureRecord>> getMoisture() async {
    // Get a reference to the database.
    final Database dbClient = await db;
    List<MoistureRecord> result = [];

    // Query the table for all temp rec.
    final List<Map<String, dynamic>> maps = await dbClient.query(
        'MoistureRecords',
        where: 'userId=?',
        whereArgs: [Authority.currentProfile.id]);
    // Convert into list of model objects
    if (maps.length > 0) {
      maps.forEach((Map<String, dynamic> obj) {
        result.add(MoistureRecord.map(obj));
      });
    }
    return result;
  }

  // deletion
  Future<int> deleteMoisture(int id) async {
    Database dbClient = await db;
    int res = await dbClient
        .delete('MoistureRecords', where: 'id=?', whereArgs: [id]);
    return res;
  }

  /* USERS */
  // insertion
  Future<int> saveUser(User record) async {
    Database dbClient = await db;
    try {
      int resultId = await dbClient.insert('Users', record.toMap());
      return resultId;
    } on DatabaseException catch (e) {
      return -1;
    }
  }

  // retrieval
  Future<List<User>> getUsers() async {
    // Get a reference to the database.
    final Database dbClient = await db;
    List<User> result = [];

    // Query the table for all users
    final List<Map<String, dynamic>> maps = await dbClient.query('Users');
    // Convert into list of model objects
    if (maps.length > 0) {
      maps.forEach((Map<String, dynamic> obj) {
        result.add(User.map(obj));
      });
    }
    return result;
  }

  Future<bool> tryLogIn(String username, String password) async {
    final Database dbClient = await db;
    final List<Map<String, dynamic>> dbObj = await dbClient
        .rawQuery('SELECT password FROM Users WHERE name = \'$username\'');
    if (dbObj.length == 0) return false;
    return (dbObj[0]['password'] == password);
  }

  Future<User> getUser(String username) async {
    final Database dbClient = await db;
    final List<Map<String, dynamic>> dbObj = await dbClient
        .rawQuery('SELECT * FROM Users WHERE name = \'$username\'');
    final User user = User.map(dbObj[0]);
    return user;
  }

  // deletion
  Future<int> deleteUser(User user) async {
    final Database dbClient = await db;
    int res = await dbClient
        .delete('Users', where: 'id=?', whereArgs: <int>[user.id]);
    // Delete everything related to this user
    await dbClient.delete('TemperatureRecords',
        where: 'userId=?', whereArgs: <int>[user.id]);
    await dbClient
        .delete('LightRecords', where: 'userId=?', whereArgs: <int>[user.id]);
    await dbClient.delete('MoistureRecords',
        where: 'userId=?', whereArgs: <int>[user.id]);

    await dbClient
        .delete('ActivityLogs', where: 'userId=?', whereArgs: <int>[user.id]);
    await dbClient.delete('Schedules',
        where: 'profile=?', whereArgs: <String>[user.name]);
    await dbClient.delete('ServerRecords',
        where: 'profile=?', whereArgs: <String>[user.name]);
    return res;
  }

  // update
  // Note that this assumes the new User retains the original id
  Future<int> updateUser(User user) async {
    final Database dbClient = await db;
    int result = await dbClient
        .update('Users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);

    return result;
  }

  //change password
  Future<bool> changePassword(String username, String newPassword) async {
    final Database dbClient = await db;
    await dbClient.rawQuery(
        'UPDATE Users SET password=\'$newPassword\' WHERE name=\'$username\'');
    return true;
  }

  /* ACTIVITY LOG */

  // insertion
  Future<int> saveLog(ActivityLog record) async {
    Database dbClient = await db;
    final Map<String, dynamic> insertMap = record.toMap();
    insertMap['userId'] = Authority.currentProfile.id;
    int res = await dbClient.insert('ActivityLogs', insertMap);
    return res;
  }

  // Retrieval
  Future<List<ActivityLog>> getLogs() async {
    // Get a reference to the database.
    final Database dbClient = await db;
    List<ActivityLog> result = [];

    // Query the table for current user
    final List<Map<String, dynamic>> maps = await dbClient.query('ActivityLogs',
        where: 'userId=?', whereArgs: [Authority.currentProfile.id]);
    // Convert into list of model objects
    if (maps.length > 0) {
      maps.forEach((Map<String, dynamic> obj) {
        result.add(ActivityLog.map(obj));
      });
    }
    return result;
  }

  // Deletion
  Future<int> deleteLog(int id) async {
    Database dbClient = await db;
    int res =
        await dbClient.delete('ActivityLogs', where: 'id=?', whereArgs: [id]);
    return res;
  }

  /* SCHEDULED SUBSYSTEM TASKS */

  // Insertion
  Future<int> saveTask(SubsystemTask task) async {
    Database dbClient = await db;
    int res = await dbClient.insert('Schedules', task.toMap());
    return res;
  }

  // Retrieval
  Future<List<SubsystemTask>> getTasks() async {
    // Get a reference to the database.
    final Database dbClient = await db;
    List<SubsystemTask> result = [];

    // Query the table for all users
    final List<Map<String, dynamic>> maps = await dbClient.query('Schedules',
        where: 'profile=?', whereArgs: [Authority.currentProfile.name]);
    // Convert into list of model objects
    if (maps.length > 0) {
      result = maps.map((obj) => SubsystemTask.map(obj)).toList();
    }
    return result;
  }

  // Deletion
  Future<int> deleteTask(int id) async {
    Database dbClient = await db;
    int res =
        await dbClient.delete('Schedules', where: 'id=?', whereArgs: [id]);
    return res;
  }

  /* SERVERS */

  // insertion
  Future<int> saveServer(ServerRecord record) async {
    Database dbClient;
    dbClient = await db;
    int res = await dbClient.insert('ServerRecords', record.toMap());
    return res;
  }

  // retrieval
  Future<List<ServerRecord>> getServers() async {
    // Get a reference to the database.
    final Database dbClient = await db;
    List<ServerRecord> result = [];

    // Query the table for all users
    final List<Map<String, dynamic>> maps =
        await dbClient.rawQuery('SELECT * FROM ServerRecords');
    // Convert into list of model objects
    if (maps.length > 0) {
      result = maps.map((Map<String, dynamic> obj) => ServerRecord.map(obj));
    }
    return result;
  }

  // deletion
  Future<int> deleteServers(int id) async {
    Database dbClient = await db;
    int res =
        await dbClient.delete('ServerRecords', where: 'id=?', whereArgs: [id]);
    return res;
  }

  // update
  Future<int> updateServer(ServerRecord server) async {
    final Database dbClient = await db;
    int result = await dbClient.update('ServerRecords', server.toMap(),
        where: 'id = ?', whereArgs: [server.id]);
    return result;
  }

  // Returns a list of server names. A server's name is just the username used
  // to log into it.
  Future<List<String>> getServerNames() async {
    final Database dbClient = await db;
    List<Map<String, dynamic>> res =
        await dbClient.query('ServerRecords', columns: ['username']);
    if (res.length > 0)
      return res.map((Map<String, dynamic> row) => row['username']);
    return [];
  }

  // Return a mapping from ID to server username of servers of a user (using
  // user's login name as FK)
  Future<Map<int, ServerRecord>> getServersOfUser([String profile = '']) async {
    final Database dbClient = await db;
    if (profile == '') profile = Authority.currentProfile.name;
    List<Map<String, dynamic>> maps = await dbClient
        .rawQuery('SELECT * FROM ServerRecords WHERE profile = \'$profile\'');
    if (maps.length > 0) {
      Map<int, ServerRecord> serverMap = Map<int, ServerRecord>();
      for (int i = 0; i < maps.length; ++i) {
        serverMap[maps[i]['id']] = ServerRecord.map(maps[i]);
      }
      return serverMap;
    }
    return {};
  }

  // reminder
  Future<int> saveReminder(Reminder reminder) async {
    final Database dbClient = await db;
    final Map<String, dynamic> insertMap = reminder.toMap();
    insertMap['userId'] = Authority.currentProfile.id;
    int res = await dbClient.insert('Reminders', insertMap);
    return res;
  }

  Future<List<Reminder>> getReminders() async {
    final Database dbClient = await db;
    List<Reminder> result = <Reminder>[];

    final List<Map<String, dynamic>> maps = await dbClient.query('Reminders',
        where: 'userId=?', whereArgs: <int>[Authority.currentProfile.id]);
    if (maps.length > 0) {
      maps.forEach((Map<String, dynamic> obj) {
        result.add(Reminder.map(obj));
      });
    }
    return result;
  }

  Future<int> deleteReminder(int id) async {
    Database dbClient;
    dbClient = await db;
    int res =
        await dbClient.delete('Reminders', where: 'id=?', whereArgs: <int>[id]);
    return res;
  }
}
