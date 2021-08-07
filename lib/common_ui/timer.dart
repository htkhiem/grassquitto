import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_circular_slider/flutter_circular_slider.dart';

class TimeRangeSelector extends StatefulWidget {
  final int subsystem;
  final TimeOfDay initialOnTime, initialOffTime;
  final void Function(int, int, int) onSelectionEnd;

  TimeRangeSelector(
      {@required this.onSelectionEnd,
      @required this.subsystem,
      @required this.initialOnTime,
      @required this.initialOffTime});

  @override
  TimeRangeSelectorState createState() => TimeRangeSelectorState();
}

class TimeRangeSelectorState extends State<TimeRangeSelector> {
  final Color baseColor = Color.fromRGBO(255, 255, 255, 0.9);

  int onStep, offStep;

  @override
  void initState() {
    final int onTime = (widget.initialOnTime.hour * Duration.secondsPerHour +
            widget.initialOnTime.minute * Duration.secondsPerMinute) %
        Duration.secondsPerDay;
    final int offTime = (widget.initialOffTime.hour * Duration.secondsPerHour +
            widget.initialOffTime.minute * Duration.secondsPerMinute) %
        Duration.secondsPerDay;
    onStep = onTime ~/ 300;
    offStep = offTime ~/ 300;
    debugPrint(onTime.toString());
    debugPrint(offTime.toString());
    super.initState();
  }

  void _updateLabels(int init, int end, int laps) {
    setState(() {
      onStep = init;
      offStep = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          DoubleCircularSlider(
            288,
            onStep,
            offStep,
            height: 260.0,
            width: 260.0,
            primarySectors: 8,
            secondarySectors: 24,
            baseColor: isDark ? Colors.white12 : Colors.black12,
            selectionColor: Theme.of(context).accentColor.withOpacity(0.3),
            handlerColor: Theme.of(context).accentColor,
            handlerOutterRadius: 12.0,
            onSelectionChange: _updateLabels,
            onSelectionEnd: widget.onSelectionEnd,
            sliderStrokeWidth: 12.0,
            child: Padding(
                padding: const EdgeInsets.all(42.0),
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Text>[
                        const Text(
                          'uptime',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text('${_formatIntervalTime(onStep, offStep)}',
                            style: TextStyle(fontSize: 34.0))
                      ]),
                )),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _drawEnds('from', onStep),
                SizedBox(
                    width: 2,
                    height: 24,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: isDark ? Colors.white38 : Colors.black12,
                            borderRadius:
                                BorderRadius.all(Radius.circular(2))))),
                _drawEnds('to', offStep),
              ]),
          Padding(padding: EdgeInsets.only(bottom: 20))
        ],
      ),
    );
  }

  Widget _drawEnds(String pre, int time) {
    return Column(
      children: <Widget>[
        Text(pre,
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.grey)),
        Container(
          padding: EdgeInsets.all(5),
          // color: Colors.green,
          child: Text(
            '${_formatTime(time).padLeft(2, '0')}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _formatTime(int time) {
    if (time == 0 || time == null) {
      return '00:00';
    }
    int hours = time ~/ 12;
    int minutes = (time % 12) * 5;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  String _formatIntervalTime(int init, int end) {
    int duration = end > init ? end - init : 288 - init + end;
    int hours = duration ~/ 12;
    int minutes = (duration % 12) * 5;
    return '${hours}h${minutes.toString().padLeft(2, '0')}m';
  }
}
