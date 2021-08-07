// DIP
import 'package:get_it/get_it.dart';

import 'package:flutter/material.dart';

import 'package:grass_app/utils/database.dart';
import 'package:grass_app/models/server.dart';
import 'package:grass_app/common_ui/empty_indicator.dart';

// Put here in common_ui as the profile settings page also uses it.
class ServerList extends StatefulWidget {
  final String username;

  ServerList({@required this.username});

  @override
  _ServerListState createState() => _ServerListState();
}

class _ServerListState extends State<ServerList> {
  List<ServerRecord> userServers;
  int count = 0;

  DatabaseService _db;

  @override
  void initState() {
    super.initState();
    _db = GetIt.I.get<DatabaseService>();
  }

  Future<void> getServers() async {
    Map<int, ServerRecord> serverMap =
        await _db.getServersOfUser(widget.username);
    userServers = serverMap.values.toList();
    count = userServers.length;
  }

  void refresh(Function func) {
    getServers();
    setState(func);
  }

  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    return Scaffold(
        appBar: AppBar(title: Text('Server list')),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () async {
              List<String> serverInfo = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => ServerEditScreen(
                          profileName: widget.username, currentRecord: null)));
              if (serverInfo != null) {
                // User tapped Add, not a non-confirming Android back button
                refresh(() {});
              }
            }),
        body: FutureBuilder(
            future: db.getServersOfUser(widget.username),
            builder: (BuildContext context,
                AsyncSnapshot<Map<int, ServerRecord>> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  userServers = snapshot.data.values.toList();
                  count = userServers.length;
                } else {
                  userServers = [];
                  count = 0;
                }
                if (count == 0)
                  return EmptyIndicator(
                    description:
                        'You don\'t have any server registered.\nTap the + at '
                        'the bottom-right of the screen to add one.',
                  );
                return ListView.builder(
                  itemCount: count,
                  padding: EdgeInsets.all(15),
                  itemBuilder: (BuildContext context, int idx) {
                    return ListTile(
                        title: Text(userServers[idx].username),
                        subtitle: Text(userServers[idx].address),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: <
                                Widget>[
                          IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                List<String> serverInfo = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            ServerEditScreen(
                                                profileName: widget.username,
                                                currentRecord:
                                                    userServers[idx])));
                                if (serverInfo != null) {
                                  refresh(() {});
                                }
                              }),
                          IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                bool reallyDelete = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            Text('Delete server information?'),
                                        content: Text('This cannot be undone.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: Text('DELETE',
                                                  style: TextStyle(
                                                      color: Colors.red))),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: Text('CANCEL'))
                                        ],
                                      );
                                    });
                                if (reallyDelete) {
                                  refresh(() {
                                    DatabaseService db = DatabaseService();
                                    db.deleteServers(userServers[idx].id);
                                  });
                                }
                              })
                        ]));
                  },
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator());
              } else {
                return Text('ERROR: Could not load servers');
              }
            }));
  }
}

// TODO: Make this work for existing servers too, by filling existing details in
class ServerEditScreen extends StatefulWidget {
  final String profileName;
  final ServerRecord currentRecord;

  ServerEditScreen({this.profileName, this.currentRecord});

  @override
  _ServerEditScreenState createState() => _ServerEditScreenState();
}

class _ServerEditScreenState extends State<ServerEditScreen> {
  String _address = '';
  String _username = '';
  String _apiKey = '';

  @override
  Widget build(BuildContext context) {
    if (widget.currentRecord != null) {
      _address = widget.currentRecord.address;
      _username = widget.currentRecord.username;
      _apiKey = widget.currentRecord.apikey;
    }
    return Scaffold(
        appBar: AppBar(title: Text('Edit server details')),
        body: ListView(padding: EdgeInsets.all(15), children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Server address'),
            initialValue: _address,
            onChanged: (String value) => _address = value,
            validator: (String value) => (value.isEmpty || value == '')
                ? 'Address cannot be blank'
                : null,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Server username'),
            initialValue: _username,
            onChanged: (String value) => _username = value,
            validator: (String value) => (value.isEmpty || value == '')
                ? 'Username cannot be blank'
                : null,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Server API key'),
            initialValue: _apiKey,
            onChanged: (String value) => _apiKey = value,
            validator: (String value) => (value.isEmpty || value == '')
                ? 'API key cannot be blank'
                : null,
          ),
          ElevatedButton(
              style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)))),
              onPressed: () {
                DatabaseService db = DatabaseService();
                if (widget.currentRecord == null)
                  db.saveServer(ServerRecord(
                      _username, _address, _apiKey, widget.profileName));
                else {
                  ServerRecord newRecord = widget.currentRecord;
                  newRecord.setRecord(_username, _address, _apiKey);
                  db.updateServer(newRecord);
                }
                Navigator.of(context)
                    .pop(<String>[_address, _username, _apiKey]);
              },
              child: Text('Finish server form'))
        ]));
  }
}
