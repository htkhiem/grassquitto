// DIP
import 'package:injectable/injectable.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// https://www.freecodecamp.org/news/local-notifications-in-flutter/

const channel_id = '1';
const appName = 'Grassquitto';

@singleton
class NotificationService {
  // Plugin service entity
  final FlutterLocalNotificationsPlugin servicePlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize notification icon for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('grassquitto');

    // Initialize settings entity
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: null, macOS: null);

    await servicePlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  // Callback for when notification is selected (optional)
  Future selectNotification(String payload) async {
    if (payload != null) {
    }
  }

  Future<void> displayBasicNotification(
      String messageContent, String detailedContent) async {
    await servicePlugin.show(
        1,
        appName,
        messageContent,
        const NotificationDetails(
            android: AndroidNotificationDetails(
                channel_id, appName, 'Sensor data warning')),
        payload: detailedContent);
  }
}
