import 'package:flutter/material.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:grass_app/common.dart';
import 'package:grass_app/models/record.dart';
import 'package:grass_app/utils/database.dart';
import 'package:grass_app/utils/utils.dart';
import 'package:grass_app/common_ui/empty_indicator.dart';

class GraphsTab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GraphsTabState();
}

class _GraphsTabState extends State<StatefulWidget> {
  /// GRAPH STYLING

  final TextStyle graphTextStyle = TextStyle(
    color: Color(0xFFE2E2E2),
    fontSize: 12,
  );

  FlGridData getGrids(
      double graphHorizontalInterval, double graphVerticalInterval) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return FlGridData(
      show: true,
      horizontalInterval: graphVerticalInterval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: isDark ? Colors.white12 : const Color(0xFFE2E2E2),
          strokeWidth: 1,
        );
      },
      drawVerticalLine: true,
      verticalInterval: graphHorizontalInterval,
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: isDark ? Colors.white12 : const Color(0xFFE2E2E2),
          strokeWidth: 1,
        );
      },
    );
  }

  SideTitles getYAxisTitles(double interval) {
    return SideTitles(
      showTitles: true,
      interval: interval,
      // Output every 5 degrees Celsius
      getTextStyles: (value) => graphTextStyle,
      getTitles: (value) {
        return value.toString();
      },
      reservedSize: 30,
      margin: 10,
    );
  }

  SideTitles getXAxisTitles(List<Record> records, double interval) {
    return SideTitles(
      showTitles: true,
      reservedSize: 25,
      interval: interval,
      rotateAngle: 45,
      getTextStyles: (value) => graphTextStyle,
      getTitles: (value) {
        int ms = value.toInt();
        return generateDynamicTimeTickMark(ms, interval.toInt());
      },
      margin: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: 400),
            childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: -50.0, child: FadeInAnimation(child: widget)),
            children: [
          /// IRRIGATION
          FutureBuilder<List>(
            future: moistureGraphDataAdapter(),
            builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) // non-null return value from adapter
                  return Container(
                      padding: EdgeInsets.all(25),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(children: [
                              Text('Moisture', style: TextStyle(fontSize: 22)),
                              Expanded(child: Container()),
                              Text(
                                  'Last measured ' +
                                      snapshot.data[2].toString() +
                                      '%',
                                  style: TextStyle(
                                      color: kIrrigationPrimaryColor,
                                      fontSize: 16))
                            ]),
                            Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 10),
                                child: Text(
                                    'Showing data from ' +
                                        msTimeToString(snapshot.data[1]),
                                    style: TextStyle(color: Colors.grey))),
                            Container(
                              height: 150,
                              child: LineChart(
                                snapshot.data[0],
                              ),
                            )
                          ]));
                else {
                  return Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyIndicator(
                          description:
                              "Not enough data for a nice graph yet."));
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                    height: 250,
                    padding: EdgeInsets.all(10),
                    child: Center(
                        child: Container(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator())));
              } else
                return Center(
                    child: Icon(Icons.not_interested, color: Colors.grey));
            },
          ),

          /// LIGHTING
          FutureBuilder<List>(
            future: lightingGraphDataAdapter(),
            builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) // non-null return value from adapter
                  return Container(
                      padding: EdgeInsets.all(25),
                      child: Column(children: [
                        Row(children: [
                          Text('Lighting', style: TextStyle(fontSize: 22)),
                          Expanded(child: Container()),
                          Text(
                              'Last measured ' +
                                  snapshot.data[2].toString() +
                                  'W/m2',
                              style: TextStyle(
                                  color: kLightingPrimaryColor, fontSize: 16))
                        ]),
                        Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Text(
                                'Showing data from ' +
                                    msTimeToString(snapshot.data[1]),
                                style: TextStyle(color: Colors.grey))),
                        Container(
                          height: 150,
                          child: LineChart(
                            snapshot.data[0],
                          ),
                        )
                      ]));
                else {
                  return Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyIndicator(
                          description:
                              "Not enough data for a nice graph yet."));
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                    height: 250,
                    padding: EdgeInsets.all(10),
                    child: Center(
                        child: Container(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator())));
              } else
                return Center(
                    child: Icon(Icons.not_interested, color: Colors.grey));
            },
          ),

          /// TEMPERATURE
          FutureBuilder<List>(
            future: temperatureGraphDataAdapter(),
            builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) // non-null return value from adapter
                  return Container(
                      padding: EdgeInsets.all(25),
                      child: Column(children: [
                        Row(children: [
                          Text('Temperature', style: TextStyle(fontSize: 22)),
                          Expanded(child: Container()),
                          Text(
                              'Last measured ' +
                                  snapshot.data[2].toString() +
                                  'oC',
                              style: TextStyle(
                                  color: kTemperaturePrimaryColor,
                                  fontSize: 16))
                        ]),
                        Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Text(
                                'Showing data from ' +
                                    msTimeToString(snapshot.data[1]),
                                style: TextStyle(color: Colors.grey))),
                        Container(
                          height: 150,
                          child: LineChart(
                            snapshot.data[0],
                          ),
                        )
                      ]));
                else {
                  return Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyIndicator(
                          description:
                              "Not enough data for a nice graph yet."));
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                    height: 250,
                    padding: EdgeInsets.all(10),
                    child: Center(
                        child: Container(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator())));
              } else
                return Center(
                    child: Icon(Icons.not_interested, color: Colors.grey));
            },
          )
        ]));
  }

  String generateDynamicTimeTickMark(int ms, int interval) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final DateTime dtPrev = dt.subtract(Duration(milliseconds: interval));
    if (dtPrev.minute != dt.minute) {
      if (dtPrev.hour != dt.hour) {
        if (dtPrev.day != dt.day) {
          if (dtPrev.month != dt.month) {
            if (dtPrev.year != dt.year) {
              return msTimeToFormattedString(ms, 'yyyy/M/d');
            }
            return msTimeToFormattedString(ms, 'M/d HH:mm');
          }
          return msTimeToFormattedString(ms, 'd HH:mm');
        }
        return msTimeToFormattedString(ms, 'HH:mm:ss');
      }
      return msTimeToFormattedString(ms, 'mm:ss');
    }
    return msTimeToFormattedString(ms, 's');
  }

  Future<List> temperatureGraphDataAdapter() async {
    final DatabaseService db = DatabaseService();
    // Get data for last 24h
    final int endTime = Settings.getValue(
        'stats-display-to-ms', DateTime.now().millisecondsSinceEpoch);
    final int startTime = Settings.getValue(
        'stats-display-from-ms', endTime - Duration.millisecondsPerDay);
    List<double> verticalBounds = await db.getValueRange(kTemperatureDBTable,
        startMs: startTime, endMs: endTime);
    // Scale y-axis to 125% of the height for some headroom
    verticalBounds.last += 0.25 * (verticalBounds.last - verticalBounds.first);
    final List<Record> tempRecords = await db.getMeasurements(
        kTemperatureDBTable,
        startMs: startTime,
        endMs: endTime);

    if (tempRecords.length < 3) {
      return null;
    } else {
      // Precalculate this to make life easier
      double graphHorizontalInterval =
          (tempRecords.last.time - tempRecords.first.time) / 10;
      double graphVerticalInterval =
          (verticalBounds.last - verticalBounds.first) / 5;
      return [
        LineChartData(
          gridData: getGrids(graphHorizontalInterval, graphVerticalInterval),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: getXAxisTitles(tempRecords, graphHorizontalInterval),
            leftTitles: getYAxisTitles(graphVerticalInterval),
          ),
          borderData: FlBorderData(show: false),
          minX: tempRecords.first.time.toDouble(),
          maxX: tempRecords.last.time.toDouble(),
          minY: verticalBounds[0],
          maxY: verticalBounds[1],
          lineBarsData: [
            LineChartBarData(
              spots: tempRecords
                  .map((rec) =>
                      FlSpot(rec.time.toDouble(), rec.measurement.toDouble()))
                  .toList(),
              isCurved: false,
              colors: [
                kTemperaturePrimaryColor,
              ],
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                  show: true,
                  colors: [
                    kTemperaturePrimaryColor.withOpacity(0.5),
                    kTemperaturePrimaryColor.withOpacity(0.0)
                  ],
                  gradientFrom: Offset(0, 0),
                  gradientTo: Offset(0, 2)),
            ),
          ],
        ),
        tempRecords.first.time,
        tempRecords.last.measurement
      ];
    }
  }

  Future<List> moistureGraphDataAdapter() async {
    final DatabaseService db = DatabaseService();
    // Get data for last 24h
    final int endTime = Settings.getValue(
        'stats-display-to-ms', DateTime.now().millisecondsSinceEpoch);
    final int startTime = Settings.getValue(
        'stats-display-from-ms', endTime - Duration.secondsPerDay * 1000);
    List<double> verticalBounds = await db.getValueRange(kMoistureDBTable,
        startMs: startTime, endMs: endTime);
    // Scale y-axis to 125% of the height for some headroom
    verticalBounds.last += 0.25 * (verticalBounds.last - verticalBounds.first);
    final List<Record> moistureRecords = await db
        .getMeasurements(kMoistureDBTable, startMs: startTime, endMs: endTime);

    if (moistureRecords.length < 3) {
      return null;
    } else {
      // Precalculate this to make life easier
      double graphHorizontalInterval =
          (moistureRecords.last.time - moistureRecords.first.time) / 10;
      double graphVerticalInterval =
          (verticalBounds.last - verticalBounds.first) / 5;
      return [
        LineChartData(
          gridData: getGrids(graphHorizontalInterval, graphVerticalInterval),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles:
                getXAxisTitles(moistureRecords, graphHorizontalInterval),
            leftTitles: getYAxisTitles(graphVerticalInterval),
          ),
          borderData: FlBorderData(show: false),
          minX: moistureRecords.first.time.toDouble(),
          maxX: moistureRecords.last.time.toDouble(),
          minY: verticalBounds[0],
          maxY: verticalBounds[1],
          lineBarsData: [
            LineChartBarData(
              spots: moistureRecords
                  .map((rec) =>
                      FlSpot(rec.time.toDouble(), rec.measurement.toDouble()))
                  .toList(),
              isCurved: false,
              colors: [
                kIrrigationPrimaryColor,
              ],
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                  show: true,
                  colors: [
                    kIrrigationPrimaryColor.withOpacity(0.5),
                    kIrrigationPrimaryColor.withOpacity(0.0)
                  ],
                  gradientFrom: Offset(0, 0),
                  gradientTo: Offset(0, 2)),
            ),
          ],
        ),
        moistureRecords.first.time,
        moistureRecords.last.measurement
      ];
    }
  }

  Future<List> lightingGraphDataAdapter() async {
    final DatabaseService db = DatabaseService();
    // Get data for last 24h
    final int endTime = Settings.getValue(
        'stats-display-to-ms', DateTime.now().millisecondsSinceEpoch);
    final int startTime = Settings.getValue(
        'stats-display-from-ms', endTime - Duration.secondsPerDay * 1000);
    List<double> verticalBounds = await db.getValueRange(kLightDBTable,
        startMs: startTime, endMs: endTime);
    // Scale y-axis to 125% of the height for some headroom
    verticalBounds.last += 0.25 * (verticalBounds.last - verticalBounds.first);
    final List<Record> lightRecords = await db.getMeasurements(kLightDBTable,
        startMs: startTime, endMs: endTime);

    if (lightRecords.length < 3) {
      return null;
    } else {
      // Precalculate this to make life easier
      double graphHorizontalInterval =
          (lightRecords.last.time - lightRecords.first.time) / 10;
      double graphVerticalInterval =
          (verticalBounds.last - verticalBounds.first) / 5;
      return [
        LineChartData(
          gridData: getGrids(graphHorizontalInterval, graphVerticalInterval),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: getXAxisTitles(lightRecords, graphHorizontalInterval),
            leftTitles: getYAxisTitles(graphVerticalInterval),
          ),
          borderData: FlBorderData(show: false),
          minX: lightRecords.first.time.toDouble(),
          maxX: lightRecords.last.time.toDouble(),
          minY: verticalBounds[0],
          maxY: verticalBounds[1],
          lineBarsData: [
            LineChartBarData(
              spots: lightRecords
                  .map((rec) =>
                      FlSpot(rec.time.toDouble(), rec.measurement.toDouble()))
                  .toList(),
              isCurved: false,
              colors: [
                kLightingPrimaryColor,
              ],
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                  show: true,
                  colors: [
                    kLightingPrimaryColor.withOpacity(0.5),
                    kLightingPrimaryColor.withOpacity(0.0)
                  ],
                  gradientFrom: Offset(0, 0),
                  gradientTo: Offset(0, 2)),
            ),
          ],
        ),
        lightRecords.first.time,
        lightRecords.last.measurement
      ];
    }
  }
}
