import 'package:flutter/material.dart';

class EmptyIndicator extends StatelessWidget {
  EmptyIndicator({this.description = 'Nothing here yet!'});
  final String description;
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          Icon(Icons.now_widgets_outlined, color: Colors.grey),
          Text(
            description,
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          )
        ]));
  }
}
