import 'package:flutter/material.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:grass_app/common.dart';
import 'package:grass_app/models/activity_log.dart';
import 'package:grass_app/utils/utils.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/common_ui/empty_indicator.dart';

class LogsTab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LogsTabState();
}

class _LogsTabState extends State<StatefulWidget> {
  final db = DatabaseService();

  List<ActivityLog> logs;
  int count = 0;

  void getLogs() {
    final Future<List<ActivityLog>> futureList = db.getLogs();
    futureList.then((updatedLogs) {
      setState(() {
        this.logs = updatedLogs;
        this.count = updatedLogs.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.logs == null) getLogs();
    if (this.count != 0)
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          child: Text('Tap on an entry to view detailed information.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          padding: EdgeInsets.all(20),
        ),
        Expanded(
            child: AnimationLimiter(
                child: ListView.builder(
          addAutomaticKeepAlives: true,
          itemCount: this.count,
          itemBuilder: (BuildContext context, int pos) {
            Icon logType, logCategory;
            switch (logs[pos].mode) {
              case 0:
                {
                  // Automatic
                  logType = Icon(Icons.android, color: Colors.green);
                  break;
                }
              case 1:
                {
                  // Scheduled
                  logType =
                      Icon(Icons.calendar_today_rounded, color: Colors.purple);
                  break;
                }
              case 2:
                {
                  // Manual
                  logType = Icon(Icons.person, color: Colors.blue);
                  break;
                }
              case 3:
                {
                  // Fallback
                  logType = Icon(Icons.warning, color: Colors.amber);
                  break;
                }
              default:
                {
                  logType = Icon(Icons.device_unknown);
                }
            }
            switch (logs[pos].category) {
              case "Temperature":
                {
                  logCategory = Icon(Icons.thermostat_outlined,
                      color: kTemperaturePrimaryColor);
                  break;
                }
              case "Light":
                {
                  logCategory = Icon(Icons.wb_sunny_outlined,
                      color: kLightingPrimaryColor);
                  break;
                }
              case "Irrigation":
                {
                  logCategory =
                      Icon(Icons.waves, color: kIrrigationPrimaryColor);
                  break;
                }
              default:
                logCategory = Icon(Icons.info_outline);
            }
            return AnimationConfiguration.staggeredList(
                position: pos,
                duration: Duration(milliseconds: 400),
                child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                        child: GestureDetector(
                            child: ListTile(
                                leading: Container(
                                    width: 48,
                                    child: Center(
                                        child: Row(
                                            children: [logType, logCategory]))),
                                title: Text(logs[pos].description),
                                subtitle: Text(
                                  msTimeToString(logs[pos].time),
                                  style: TextStyle(color: Colors.grey),
                                ),
                                // TODO: Open Details popup here
                                onTap: () => showDialog(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        SimpleDialog(children: [
                                          Padding(
                                              padding: EdgeInsets.all(20),
                                              child: Text(logs[pos].details))
                                        ])))))));
          },
        )))
      ]);
    else {
      return EmptyIndicator();
    }
  }
}
