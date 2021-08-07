import 'package:grass_app/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:grass_app/function_panels/statistics/export_popup.dart';
import 'package:grass_app/function_panels/statistics/graphs.dart';
import 'package:grass_app/function_panels/statistics/logs.dart';

class StatisticsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatefulWidget> {
  @override
  void initState() {
    int defaultStartMs = DateTime.now().millisecondsSinceEpoch;
    defaultStartMs -= defaultStartMs % Duration.millisecondsPerDay;
    Settings.setValue('stats-display-from-ms', defaultStartMs);
    Settings.setValue(
        'stats-display-to-ms', defaultStartMs + Duration.millisecondsPerDay);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Just default to today for the data range each time the user switch to the stats screen.
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Statistics'),
            actions: [
              TextButton(
                  child: Icon(Icons.date_range, color: Colors.white),
                  onPressed: () async {
                    DatabaseService db = DatabaseService();
                    List<DateTime> range =
                        await db.getAvailableSensorTimeRange();
                    if (range.length == 0)
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                                title: Text('No data'),
                                content: Text(
                                    'Looks like there\'s nothing to select yet.'),
                                actions: [
                                  TextButton(
                                    child: Text('OK'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  )
                                ],
                              ));
                    else {
                      final DateTimeRange picked = await showDateRangePicker(
                          context: context,
                          firstDate: range.first,
                          lastDate: range.last,
                          helpText:
                              'Data between 00:00 of the first day and 00:00 '
                                  'of the day after the last will be '
                                  'displayed.');
                      if (picked != null) {
                        await Settings.setValue('stats-display-from-ms',
                            picked.start.millisecondsSinceEpoch);
                        await Settings.setValue(
                            'stats-display-to-ms',
                            picked.end
                                .add(Duration(hours: 24))
                                .millisecondsSinceEpoch);
                        setState(() {});
                      }
                    }
                  }),
              TextButton(
                  // TODO: implement CSV exporting
                  child: Icon(Icons.save, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExportingPage()));
                  })
              // [TO DO] Option to store file in external storage
            ],
            bottom: TabBar(
                tabs: <Tab>[Tab(text: 'Readings'), Tab(text: 'Actions')]),
          ),
          body: TabBarView(children: [GraphsTab(), LogsTab()]),
        ));
  }
}
