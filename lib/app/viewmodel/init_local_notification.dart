import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String iotNotificationChannelId = 'msp_alert_channel_id';
const String _androidNotificationIcon = 'ic_stat_name_msp';

// Create a [AndroidNotificationChannel] for heads up notifications
final AndroidNotificationChannel notificationChannel =
    AndroidNotificationChannel(
      iotNotificationChannelId,
      "iot_notification",
      description: "IOT Notifications",
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

// Initialize the [FlutterLocalNotificationsPlugin] package.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool _localNotificationsInitialized = false;
bool _localNotificationsResponseCallbackInitialized = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();
  await showIotLocalNotification(message);
}

Future<void> initializeIotLocalNotifications({
  DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
}) async {
  final hasCallback = onDidReceiveNotificationResponse != null;
  if (_localNotificationsInitialized &&
      (!hasCallback || _localNotificationsResponseCallbackInitialized)) {
    return;
  }

  const initializationSettingsAndroid = AndroidInitializationSettings(
    _androidNotificationIcon,
  );
  const initializationSettingsIOS = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );
  await _createAndroidNotificationChannel();

  _localNotificationsInitialized = true;
  if (hasCallback) _localNotificationsResponseCallbackInitialized = true;
}

Future<void> requestIotNotificationPermissions() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> showIotLocalNotification(RemoteMessage message) async {
  try {
    await initializeIotLocalNotifications();

    final data = message.data;
    final notificationType = _messageValue(data, 'messageType');
    if (notificationType.isEmpty) return;

    final notificationDetails = _notificationDetails();
    final notificationTitle = _notificationTitle(message);

    switch (notificationType) {
      case 'IM':
        final originalId = _messageIntValue(data, 'originalId');
        final originalCreator = _messageValue(data, 'originalCreator');
        final notificationId = _messageIntValue(data, 'notificationId');
        final groupName = _messageValue(data, 'groupName', ' ');

        await flutterLocalNotificationsPlugin.show(
          id: notificationId,
          title: notificationTitle ?? 'Thông báo mới',
          body: _notificationBody(message),
          notificationDetails: notificationDetails,
          payload:
              '$notificationType~$notificationId~$originalId~$originalCreator~$groupName',
        );
        break;

      case 'AR':
        final id = _messageIntValue(data, 'id');
        final type = _messageValue(data, 'reportType');
        final date = _messageValue(data, 'reportDate');
        final title = notificationTitle ?? 'Thông báo mới';
        await flutterLocalNotificationsPlugin.show(
          id: id,
          title: title,
          body: _notificationBody(message),
          notificationDetails: notificationDetails,
          payload: '$notificationType~$id~$type~$date~$title',
        );
        break;
    }
  } catch (e, s) {
    debugPrint('IOT show notification error: $e');
    debugPrintStack(stackTrace: s);
  }
}

NotificationDetails _notificationDetails() {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    notificationChannel.id,
    notificationChannel.name,
    channelDescription: notificationChannel.description,
    color: Colors.green,
    importance: Importance.max,
    priority: Priority.high,
    channelShowBadge: true,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.message,
    enableLights: true,
    ledColor: Colors.green,
    ledOnMs: 1000,
    ledOffMs: 500,
    ticker: 'IOT',
    icon: _androidNotificationIcon,
  );
  var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentBadge: true,
    presentSound: true,
  );
  return NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );
}

String _messageValue(
  Map<String, dynamic> data,
  String key, [
  String fallback = '',
]) {
  return data[key]?.toString() ?? fallback;
}

int _messageIntValue(Map<String, dynamic> data, String key) {
  return int.tryParse(_messageValue(data, key, '0')) ?? 0;
}

String? _notificationTitle(RemoteMessage message) {
  final dataTitle = message.data['title']?.toString();
  if (dataTitle != null && dataTitle.isNotEmpty) return dataTitle;
  return message.notification?.title;
}

String? _notificationBody(RemoteMessage message) {
  final dataBody = message.data['body']?.toString();
  if (dataBody != null && dataBody.isNotEmpty) return dataBody;
  return message.notification?.body;
}

Future<void> _createAndroidNotificationChannel() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(notificationChannel);
}
