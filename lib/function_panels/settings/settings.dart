import 'package:flutter/material.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:grass_app/common_ui/server_device_config.dart';
import 'package:grass_app/utils/authority.dart';
import 'package:grass_app/utils/database.dart';

class ClientSettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ClientSettingsPageState();
}

class _ClientSettingsPageState extends State<StatefulWidget> {
  String _username = Authority.currentProfile.name;

  // String _password  =  AppMqttTransactions().password;
  final DatabaseService db = DatabaseService();

  _showDialog() async {
    await showDialog<String>(
      context: context,
      builder: (_) => new AlertDialog(
        scrollable: true,
        // contentPadding: const EdgeInsets.all(16.0),
        content: new Row(
          children: <Widget>[
            new Expanded(
              child: new TextField(
                autofocus: true,
                obscureText: true,
                decoration: new InputDecoration(
                    labelText: 'New password',
                    labelStyle: TextStyle(fontSize: 24),
                    hintText: 'Longer than 6 characters',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 12)),
                onSubmitted: (String value) async {
                  await showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('CONFIRM!'),
                        content: Text('Do you really want to change password?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('NO'),
                          ),
                          TextButton(
                            onPressed: () {
                              db.changePassword(_username, value);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('YES'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: <Widget>[
          new TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              }),
        ],
      ),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Profile settings'),
        ),
        body: ListView(children: <Widget>[
          SwitchSettingsTile(
              title: 'Scheduler notifications in app',
              subtitle:
                  'Disable if you only want to be notified of scheduled actions while outside of Grassquitto.',
              settingKey: 'scheduled-notifications-in-app',
              enabledLabel:
                  'Notifications will display even while you are already in the app.',
              disabledLabel:
                  'Notifications only displays when you are outside the app.',
              leading: Icon(Icons.chat_bubble)),
          SimpleSettingsTile(
            title: "Change password",
            leading: Icon(Icons.security),
            subtitle: "For the current profile.",
            onTap: () => _showDialog(),
          ),
          SimpleSettingsTile(
            title: 'Configure servers and devices',
            subtitle:
                'Add/edit/remove servers and change server-device assignments.',
            leading: Icon(Icons.api),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => ServerDeviceConfig(
                        username: Authority.currentProfile.name))),
          ),
          SimpleSettingsTile(
              title: "Delete profile",
              leading: Icon(Icons.delete),
              subtitle: "Deletes all measurements and logged activities.",
              onTap: () async {
                bool confirmed = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Are you sure?"),
                        content: Text(
                            "You are about to delete your profile and all its associated logs and credentials.\nThis process is irreversible!"),
                        actions: [
                          TextButton(
                            child: Text("YES"),
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
                          TextButton(
                            child: Text("NO"),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          )
                        ],
                      );
                    });
                if (confirmed) {
                  // Pop page and return a "true" to home screen.
                  // Home screen should then pop itself off the stack and call the database backend's
                  // profile delete handler.
                  Navigator.of(context).pop(true);
                }
              })
        ]));
  }
}
