import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Create a [AndroidNotificationChannel] for heads up notifications
final AndroidNotificationChannel notificationChannel =
    AndroidNotificationChannel(
  "msp_channel_id",
  "iot_notification",
  "IOT Notifications",
  importance: Importance.max,
  enableVibration: true,
  playSound: true,
);

// Initialize the [FlutterLocalNotificationsPlugin] package.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      notificationChannel.id,
      notificationChannel.name,
      notificationChannel.description,
      color: Colors.green,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'IOT');
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  String _notificationType = message.data['messageType'];
  String? _notificationTitle = message.data['title'];
  //print("ON BACKGROUND ${message.data}");
  switch (_notificationType) {
    case 'IM':
      // nguoi gui truc tiep thi ko hien thi notification
      late final String _username;
      await IotSharedPreferences().get().then((prefs) => _username = prefs[3]);
      if (message.data['creator'] == _username) return;

      int _originalId = int.tryParse(message.data['originalId']) ?? 0;
      String _originalCreator = message.data['originalCreator'];
      int _notificationId =
          int.tryParse(message.data['notificationId'] ?? '0') ?? 0;
      String _groupName = message.data['groupName'];
      if (_notificationTitle != null)
        await flutterLocalNotificationsPlugin.show(
            _notificationId, _notificationTitle, null, platformChannelSpecifics,
            payload:
                '$_notificationType~$_notificationId~$_originalId~$_originalCreator~$_groupName');
      else
        await flutterLocalNotificationsPlugin.cancel(_notificationId);
      break;

    case 'AR':
      int _id = int.tryParse(message.data['id']) ?? 0;
      String _type = message.data['reportType'];
      String _date = message.data['reportDate'];
      String _title = message.data['title'] ?? '';
      await flutterLocalNotificationsPlugin.show(
          _id, _notificationTitle, null, platformChannelSpecifics,
          payload: '$_notificationType~$_id~$_type~$_date~$_title');
      break;
  }
}
