import 'package:intl/intl.dart';

String dateTimeToString(DateTime datetime) {
  final DateFormat df = new DateFormat('yyyy-MM-dd HH:mm:ss');
  return df.format(datetime);
}

String msTimeToString(int ms) {
  final DateFormat df = new DateFormat('yyyy-MM-dd HH:mm:ss');
  return df.format(new DateTime.fromMillisecondsSinceEpoch(ms));
}

String msTimeToFormattedString(int ms, String format) {
  final DateFormat df = new DateFormat(format);
  return df.format(new DateTime.fromMillisecondsSinceEpoch(ms));
}

/* Converts cron day number to superscript ordinals.
* Ex: 1 -> 1st. */
String monthDayOrdinal(int cronDay) {
  if (cronDay == 1 || cronDay == 21 || cronDay == 31) {
    return '$cronDayˢᵗ';
  } else if (cronDay == 2 || cronDay == 22) {
    return '$cronDayⁿᵈ';
  } else {
    return '$cronDayᵗʰ';
  }
}

// List getRecordStatistics(var rmap) {
//   var minY = rmap[0]['measurement'];
//   var maxY = minY;
//   var minX = rmap[0]['time'];
//   var maxX = rmap[rmap.length - 1]['time'];
//   for (int i = 1; i < rmap.length; i++) {
//     var m = rmap[i]['measurement'];
//     if (m > maxY) maxY = m;
//     else if (m < minY) minY = m;
//   }
//   return [minY, maxY, minX, maxX];
// }

double msSinceEpochToHours(int time) {
  DateTime datetime = DateTime.fromMillisecondsSinceEpoch(time);
  // return datetime.minute.toDouble() + datetime.second.toDouble() / 60.0;
  return datetime.hour.toDouble() +
      datetime.minute.toDouble() / 60.0 +
      datetime.second.toDouble() / 3600.0;
}
