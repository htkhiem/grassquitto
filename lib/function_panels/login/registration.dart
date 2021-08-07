import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cool_stepper/cool_stepper.dart';

import 'package:grass_app/common.dart';
import 'package:grass_app/common_ui/server_list.dart';
import 'package:grass_app/common_ui/device_list.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/models/user.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<StatefulWidget> {
  List<String> existingUsernames;

  String _username = "";
  String _password = "";
  String _confirmPassword = "";
  Map<Device, int> deviceToServer;

  void validateAndSave(BuildContext context) async {
    // Hash user password
    final DatabaseService db = DatabaseService();
    String _hpassword =
        _password; // TODO: sha1.convert(utf8.encode(_password)).toString();
    var user = User.init(
        _username,
        _hpassword,
        deviceToServer[Device.Light],
        deviceToServer[Device.Soil],
        deviceToServer[Device.DHT11],
        deviceToServer[Device.LED],
        deviceToServer[Device.Relay],
        deviceToServer[Device.Servo]);
    int result = await db.saveUser(user);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        appBar: AppBar(title: Text("Registration")),
        body: CoolStepper(
          showErrorSnackbar: true,
          config: CoolStepperConfig(
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              subtitleTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              )),
          steps: [
            CoolStep(
                title: "Basic information",
                subtitle: "Pick a unique username and a memorable password.",
                content: FutureBuilder(
                    future: db.getUsers(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<User>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData)
                          existingUsernames = snapshot.data
                              .map((User user) => user.name)
                              .toList();
                        else
                          existingUsernames = <String>[];
                        return Column(
                            // CoolStep's content field is already scrollable
                            //padding: EdgeInsets.all(15),
                            children: [
                              TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Username'),
                                onChanged: (value) => _username = value,
                                validator: (value) => value.isEmpty
                                    ? "Username cannot be blank"
                                    : null,
                              ),
                              TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Password'),
                                obscureText: true,
                                onChanged: (value) => _password = value,
                                validator: (value) => value.isEmpty
                                    ? "Password cannot be blank"
                                    : null,
                              ),
                              TextFormField(
                                decoration: InputDecoration(
                                    labelText: 'Confirm password'),
                                obscureText: true,
                                onChanged: (value) => _confirmPassword = value,
                                validator: (value) {
                                  if (value.isEmpty)
                                    return "Please confirm your password";
                                  else if (value != _password)
                                    return "Your confirmation does not match";
                                  else
                                    return null;
                                },
                              ),
                            ]);
                      } else if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator());
                      } else {
                        return Text(
                            "ERROR: Could not query existing usernames");
                      }
                    }),
                validation: () {
                  if (existingUsernames == null)
                    return "Please try again in a bit. Working behind the scenes...";
                  if (_username.length == 0) return "Username cannot be blank!";
                  if (existingUsernames.contains(_username))
                    return "Username already exists!";
                  else if (_password.length == 0)
                    return "Password cannot be blank!";
                  else if (_confirmPassword != _password)
                    return "Passwords did not match!";
                  else
                    return null;
                }),
            CoolStep(
              title: "Add servers",
              subtitle:
                  "Add all the MQTT servers you need to connect to. We'll specify which device uses which server soon.",
              content: Container(
                  height: 120,
                  child: Center(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40)))),
                        child: Text("Open server settings",
                            style: TextStyle(fontSize: 20)),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    ServerList(username: _username)))),
                  )),
              validation: () =>
                  null, // TODO: Find a way to synchronously get server count
            ),
            CoolStep(
                title: "Hook up devices",
                subtitle:
                    "Specify which server to subscribe/publish to for each device. If you need to add more servers, feel free to go back to step 2.",
                content: Container(
                    height: 150,
                    child: Center(
                        child: ElevatedButton(
                      onPressed: () async {
                        deviceToServer = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => DeviceList(
                                      username: _username,
                                    registered: false
                                    )));
                      },
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40)))),
                      child: Text("Configure devices",
                          style: TextStyle(fontSize: 20)),
                    ))),
                validation: () {
                  if (deviceToServer == null ||
                      deviceToServer.values.contains(null))
                    return "Please configure all devices before proceeding!";
                  return null;
                })
          ],
          onCompleted: () => validateAndSave(context),
        ));
  }
}
