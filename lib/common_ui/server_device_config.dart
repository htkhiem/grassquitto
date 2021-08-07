// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cool_stepper/cool_stepper.dart';

import 'package:grass_app/common.dart';
import 'package:grass_app/common_ui/server_list.dart';
import 'package:grass_app/common_ui/device_list.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/models/user.dart';

class ServerDeviceConfig extends StatefulWidget {
  ServerDeviceConfig({@required this.username});
  final String username;
  @override
  _ServerDeviceConfigState createState() => _ServerDeviceConfigState();
}

class _ServerDeviceConfigState extends State<ServerDeviceConfig> {
  DatabaseService _db;
  Map<Device, int> updatedDeviceToServer;

  @override
  void initState() {
    super.initState();
    _db = GetIt.I.get<DatabaseService>();
  }

  void updateConfig(BuildContext context) async {
    // Hash user password
    User user = await _db.getUser(widget.username);
    Map<String, dynamic> userMap = user.toMap();
    userMap['id'] = user.id;
    userMap['lightId'] = updatedDeviceToServer[Device.Light];
    userMap['soilId'] = updatedDeviceToServer[Device.Soil];
    userMap['tempId'] = updatedDeviceToServer[Device.DHT11];
    userMap['ledId'] = updatedDeviceToServer[Device.LED];
    userMap['relayId'] = updatedDeviceToServer[Device.Relay];
    userMap['servoId'] = updatedDeviceToServer[Device.Servo];
    user = User.map(userMap);
    await _db.updateUser(user);
    // Pop and return to login
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        appBar: AppBar(title: Text('Server-Device Configuration')),
        body: CoolStepper(
          config: CoolStepperConfig(
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              subtitleTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              )),
          showErrorSnackbar: true,
          steps: [
            CoolStep(
              title: 'Configure servers',
              subtitle: 'Add or remove the MQTT servers you need to connect '
                  'to. We\'ll specify which device uses which server soon.',
              content: Container(
                  height: 120,
                  child: Center(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40)))),
                        child: Text('Open server settings',
                            style: TextStyle(fontSize: 20)),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    ServerList(username: widget.username)))),
                  )),
              validation: () => null,
              // TODO: Find a way to synchronously get server count
            ),
            CoolStep(
                title: 'Hook up devices',
                subtitle:
                    'Specify which server to subscribe/publish to for each '
                    'device. If you need to add more servers, feel free '
                    'to go back to step 2.',
                content: Container(
                    height: 150,
                    child: Center(
                        child: ElevatedButton(
                      onPressed: () async {
                        updatedDeviceToServer = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => DeviceList(
                                      username: widget.username,
                                    )));
                      },
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40)))),
                      child: Text('Configure devices',
                          style: TextStyle(fontSize: 20)),
                    ))),
                validation: () {
                  // updatedDeviceToServer = remapServer();
                  print('Updated: $updatedDeviceToServer');
                  if (updatedDeviceToServer == null ||
                      updatedDeviceToServer.values.contains(null))
                    return 'Please reconfigure all devices before proceeding!';
                  return null;
                })
          ],
          onCompleted: () => updateConfig(context),
        ));
  }
}
