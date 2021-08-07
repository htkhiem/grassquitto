import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:grass_app/function_panels/statistics/export.dart';

class ExportOption {
  String title;
  bool value;

  ExportOption({
    @required this.title,
    this.value = false,
  });
}

class ExportingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ExportingPageState();
}

class ExportingPageState extends State<StatefulWidget> {
  final exportAllOption = ExportOption(title: 'All Tables');
  final exportTableOptions = [
    ExportOption(title: 'TemperatureRecords'),
    ExportOption(title: 'LightRecords'),
    ExportOption(title: 'MoistureRecords'),
    ExportOption(title: 'ActivityLogs'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exporting options'),
      ),
      body: ListView(children: <Widget>[
        buildToggleCheckbox(exportAllOption),
        Divider(),
        ...exportTableOptions.map(buildSingleCheckbox).toList(),
        Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
                child:
                    Padding(child: Text('SHARE'), padding: EdgeInsets.all(20)),
                onPressed: () {
                  shareCSV(
                      exportTableOptions[0].value,
                      exportTableOptions[1].value,
                      exportTableOptions[2].value,
                      exportTableOptions[3].value);
                })),
      ]),
    );
  }

  Widget buildSingleCheckbox(ExportOption option) => buildCheckbox(
      option: option,
      onClicked: () {
        setState(() {
          final newValue = !option.value;
          option.value = newValue;

          if (!newValue) {
            exportAllOption.value = false;
          } else {
            final all =
                exportTableOptions.every((tableOption) => tableOption.value);
            exportAllOption.value = all;
          }
        });
      });
  Widget buildToggleCheckbox(ExportOption option) => buildCheckbox(
      option: option,
      onClicked: () {
        final newValue = !option.value;
        setState(() {
          exportAllOption.value = newValue;
          exportTableOptions.forEach((tableOption) {
            tableOption.value = newValue;
          });
        });
      });

  Widget buildCheckbox({
    @required VoidCallback onClicked,
    @required ExportOption option,
  }) =>
      ListTile(
        onTap: onClicked,
        leading: Checkbox(
          value: option.value,
          onChanged: (value) => onClicked(),
        ),
        title: Text(
          option.title,
        ),
      );
}
