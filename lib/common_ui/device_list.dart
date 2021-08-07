// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:grass_app/utils/database.dart';
import 'package:grass_app/models/server.dart';
import 'package:grass_app/models/user.dart';
import 'package:grass_app/common.dart';
import 'package:grass_app/common_ui/empty_indicator.dart';
// Put here in common_ui as the profile settings page also uses it.

class DeviceList extends StatefulWidget {
  // If registered = false, do not try to query current values from database
  // (as there is none).
  DeviceList({this.username, this.registered = true});
  final String username;
  final bool registered;

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  // Duplicated here to keep local state
  int sLed, sTemp, sSoil, sPump, sLight, sServo;

  DatabaseService _db;

  @override
  void initState() {
    super.initState();
    _db = GetIt.I.get<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Edit device connections')),
        body: ListView(padding: EdgeInsets.all(15), children: [
          FutureBuilder(
              future: widget.registered
              ? (Future.wait([
                _db.getServersOfUser(widget.username),
                _db.getUser(widget.username)
              ]))
                  : (_db.getServersOfUser(widget.username))
              ,
              builder: (BuildContext context,
                  AsyncSnapshot<dynamic> variableSnapshot) {
                if (variableSnapshot.hasData) {
                  List<dynamic> snapshotData;
                  if (widget.registered) {
                    snapshotData = variableSnapshot.data;
                  } else {
                    int firstId = variableSnapshot.data.values.first.id;
                    User placeholderUser = User.init(
                        '', 
                        '', 
                        firstId, 
                        firstId, 
                        firstId, 
                        firstId, 
                        firstId, 
                        firstId
                    );
                    snapshotData = <dynamic>[
                      variableSnapshot.data, 
                      placeholderUser
                    ];
                  }
                  if (snapshotData[0].values.length == 0 ||
                      snapshotData[1] == null) {
                    return Container(
                        height: 200,
                        child: EmptyIndicator(
                            description: 'You haven\'t added any '
                                'server to this profile yet.'));
                  }
                  List<DropdownMenuItem<int>> optionsWidgets = snapshotData[0]
                      .values
                      .map<DropdownMenuItem<int>>((ServerRecord sr) {
                    return DropdownMenuItem<int>(
                        value: sr.id,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Text>[
                              Text(sr.username,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(sr.address,
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey))
                            ]));
                  }).toList();
                  if (sTemp == null) {
                    sTemp = snapshotData.last.tempId;
                  }
                  if (sPump == null) {
                    sPump = snapshotData.last.relayId;
                  }
                  if (sLed == null) {
                    sLed = snapshotData.last.ledId;
                  }
                  if (sLight == null) {
                    sLight = snapshotData.last.lightId;
                  }
                  if (sServo == null) {
                    sServo = snapshotData.last.servoId;
                  }
                  if (sSoil == null) {
                    sSoil = snapshotData.last.soilId;
                  }
                  return Column(children: <Widget>[
                    Row(children: <Widget>[
                      Text('LED'),
                      Expanded(child: Container()),
                      DropdownButton<int>(
                          value: sLed,
                          items: optionsWidgets,
                          onChanged: (int serverId) {
                            setState(() {
                              sLed = serverId;
                            });
                          })
                    ]),
                    Row(children: <Widget>[
                      Text('DHT11'),
                      Expanded(child: Container()),
                      DropdownButton<int>(
                          value: sTemp,
                          items: optionsWidgets,
                          onChanged: (int serverId) {
                            setState(() {
                              sTemp = serverId;
                            });
                          })
                    ]),
                    Row(children: <Widget>[
                      Text('Soil moisture sensor'),
                      Expanded(child: Container()),
                      DropdownButton<int>(
                          value: sSoil,
                          items: optionsWidgets,
                          onChanged: (int serverId) {
                            setState(() {
                              sSoil = serverId;
                            });
                          })
                    ]),
                    Row(children: <Widget>[
                      Text('Pump relay'),
                      Expanded(child: Container()),
                      DropdownButton<int>(
                          value: sPump,
                          items: optionsWidgets,
                          onChanged: (int serverId) {
                            setState(() {
                              sPump = serverId;
                            });
                          })
                    ]),
                    Row(children: <Widget>[
                      Text('Light sensor'),
                      Expanded(child: Container()),
                      DropdownButton<int>(
                          value: sLight,
                          items: optionsWidgets,
                          onChanged: (int serverId) {
                            setState(() {
                              sLight = serverId;
                            });
                          })
                    ]),
                    Row(children: <Widget>[
                      Text('Servo motor'),
                      Expanded(child: Container()),
                      DropdownButton<int>(
                          value: sServo,
                          items: optionsWidgets,
                          onChanged: (int serverId) {
                            setState(() {
                              sServo = serverId;
                            });
                          })
                    ]),
                    ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40)))),
                        onPressed: () =>
                            Navigator.of(context).pop(<Device, int>{
                              Device.Light: sLight,
                              Device.LED: sLed,
                              Device.Servo: sServo,
                              Device.DHT11: sTemp,
                              Device.Relay: sPump,
                              Device.Soil: sSoil
                            }),
                        child: Text('Apply'))
                  ]);
                } else if (variableSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator());
                } else {
                  return Text('ERROR: Something went wrong'
                      ' while fetching the server list');
                }
              })
        ]));
  }
}
