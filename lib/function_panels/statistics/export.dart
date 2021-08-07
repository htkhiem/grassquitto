import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:grass_app/utils/database.dart';

// Convert a map list to csv
String mapListToCsv(List<Map<String, Object>> mapList,
    {ListToCsvConverter converter}) {
  if (mapList == null) {
    return null;
  }
  converter = const ListToCsvConverter();

  var data = <List>[];
  var keys = <String>[];
  var keyIndexMap = <String, int>{};

  // Add the key and fix previous records
  int _addKey(String key) {
    var index = keys.length;
    keyIndexMap[key] = index;
    keys.add(key);
    for (var dataRow in data) {
      dataRow.add(null);
    }
    return index;
  }

  for (var map in mapList) {
    // This list might grow if a new key is found
    var dataRow = List<Object>.filled(keyIndexMap.length, null);
    // Fix missing key
    map.forEach((key, value) {
      var keyIndex = keyIndexMap[key];
      if (keyIndex == null) {
        // New key is found
        // Add it and fix previous data
        keyIndex = _addKey(key);
        // grow our list
        dataRow = List.from(dataRow, growable: true)..add(value);
      } else {
        dataRow[keyIndex] = value;
      }
    });
    data.add(dataRow);
  }
  return converter.convert(<List>[keys, ...data]);
}

Future<String> export(String tableName, {int start = 0, int end = -1}) async {
  DatabaseService dbHelper = DatabaseService();
  Database dbClient = await dbHelper.db;
  List<Map<String, dynamic>> maps = await dbClient.rawQuery(
      'SELECT * FROM $tableName WHERE time >= $start AND time <= $end ');
  var csv = mapListToCsv(maps);

  final directory =
      await getApplicationDocumentsDirectory(); // get path local directory.
  final pathOfFile = directory.path;
  File file = File("$pathOfFile/$tableName.csv");
  file.writeAsString(csv); //writing new csv file with converted csv content.
  return pathOfFile;
}

Future<void> shareCSV(bool tempeOption, bool moistOption, bool lightOption,
    bool logsOption) async {
  var pathOfTempe, pathOfMoist, pathOfLight, pathOfLogs;
  final int endTime = Settings.getValue(
      'stats-display-to-ms', DateTime.now().millisecondsSinceEpoch);
  final int startTime = Settings.getValue(
      'stats-display-from-ms', endTime - Duration.secondsPerDay * 1000);

  List<String> fileNames = <String>[];

  if (tempeOption) {
    pathOfTempe =
        await export('TemperatureRecords', start: startTime, end: endTime);
    fileNames.add('$pathOfTempe/TemperatureRecords.csv');
  }
  if (moistOption) {
    pathOfMoist =
        await export('MoistureRecords', start: startTime, end: endTime);
    fileNames.add('$pathOfMoist/MoistureRecords.csv');
  }
  if (lightOption) {
    pathOfLight = await export('LightRecords', start: startTime, end: endTime);
    fileNames.add('$pathOfLight/LightRecords.csv');
  }
  if (logsOption) {
    pathOfLogs = await export('ActivityLogs', start: startTime, end: endTime);
    fileNames.add('$pathOfLogs/ActivityLogs.csv');
  }

  Share.shareFiles(fileNames);
  //
  // * Another sharing option
  //  final RenderBox box = context.findRenderObject();
  //  final String text = "$filename.csv - Records of past ";
  //  Share.share(
  //    text,
  //    sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
  //  );
}
/*
Future<List<String>> pickFile() async{
  final result = await FilePicker.platform.pickFiles(allowMultiple: true);
  return result == null ? <String>[] : result.paths;
}
*/
