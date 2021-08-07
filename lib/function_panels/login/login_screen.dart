// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:progress_indicator_button/progress_button.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:grass_app/main.dart';
import 'package:grass_app/common_ui/server_device_config.dart';
import 'package:grass_app/function_panels/login/registration.dart';
import 'package:grass_app/utils/profile_util.dart';
import 'package:grass_app/utils/notification.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // GlobalKey<FormState> formKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _username;
  String _password;

  ProfileUtils _profileUtils;
  @override
  void initState() {
    super.initState();
    _profileUtils = GetIt.I.get<ProfileUtils>();
  }

  Future<void> validateAndLogin(BuildContext context) async {
    // Hash user password
    await NotificationService().init();
    final FormState form = _formKey.currentState;
    if (form.validate()) {
      int loginResult = await _profileUtils.tryConnect(_username, _password);
      switch (loginResult) {
        case 0:
          {
            // Login successful
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OverviewTiles()));
            break;
          }
        case 1:
          {
            // Unable to connect
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Unable to log in'),
                    content: Text(
                        'Connection refused by the MQTT server. Make sure your username and password are correct.'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'))
                    ],
                  );
                });
            break;
          }
        case 2:
          {
            // Remote auth error
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Server authentication error'),
                    content: Text(
                        'Looks like something have changed on the servers. You must update your server information to continue.'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('CANCEL')),
                      TextButton(
                          onPressed: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        ServerDeviceConfig(
                                            username: _username)));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Servers and devices reconfigured successfully!')));
                            Navigator.of(context).pop();
                          },
                          child: Text('UPDATE')),
                    ],
                  );
                });
            break;
          }
        case 3:
          {
            // Internal error
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Unable to log in'),
                    content: Text('An internal database error has occurred.'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'))
                    ],
                  );
                });
            break;
          }
        case 4:
          {
            // Wrong local password, or account does not exist
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Unable to log in'),
                    content: Text(
                        'Invalid profile name and/or password. If you have not set up any profile, please do so before logging in.'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'))
                    ],
                  );
                });
            break;
          }
        default:
          {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:
            ListView(padding: EdgeInsets.only(left: 15, right: 15), children: [
      Form(
        key: _formKey,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 100),
            Container(
              width: 100,
              height: 100,
              child: SvgPicture.asset('assets/grassquitto.svg'),
            ),
            const SizedBox(height: 10),
            Text('Grassquitto',
                textAlign: TextAlign.center,
                style: GoogleFonts.leckerliOne(
                    textStyle: TextStyle(color: Colors.green, fontSize: 30))),
            // input field for username
            TextFormField(
              decoration: InputDecoration(labelText: 'Username'),
              validator: (value) =>
                  value.isEmpty ? 'Username cannot be blank' : null,
              onChanged: (value) => _username = value,
            ),
            // input field for password
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) =>
                  value.isEmpty ? 'Password cannot be blank.' : null,
              onChanged: (value) => _password = value,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      ProgressButton(
        borderRadius: BorderRadius.circular(20),
        color: Colors.green,
        child: Text(
          'Login',
          style: TextStyle(fontSize: 20.0, color: Colors.white),
        ),
        onPressed: (AnimationController controller) async {
          if (!controller.isCompleted) {
            controller.forward();
          }
          await validateAndLogin(context);
          controller.reverse();
        },
      ),
      Container(
          padding: EdgeInsets.only(top: 20),
          child: Center(
              child: const Text('Don\'t have a local profile?',
                  style: const TextStyle(color: Colors.grey)))),
      TextButton(
        child: const Text(
          'Create profile',
          style: const TextStyle(fontSize: 20.0),
        ),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => RegistrationPage()));
        },
      ),
    ]));
  }
}
