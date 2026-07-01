import 'dart:io';
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
const Duration _localNotificationDedupeWindow = Duration(minutes: 5);
final Map<String, int> _recentLocalNotificationKeys = <String, int>{};

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  if (_hasRemoteNotificationPayload(message)) {
    debugPrint(
      'IOT FCM background notification handled by system tray; '
      'skip local duplicate.',
    );
    return;
  }

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
    alert: false,
    badge: false,
    sound: false,
  );

  await debugIotNotificationState('permission-request');
}

Future<void> showIotLocalNotification(RemoteMessage message) async {
  try {
    await initializeIotLocalNotifications();

    final data = message.data;
    debugPrint('IOT FCM data: $data');
    debugPrint(
      'IOT FCM notification: '
      '${message.notification?.title} - ${message.notification?.body}',
    );

    final notificationType = _messageValue(data, 'messageType');
    debugPrint('IOT FCM messageType: $notificationType');
    if (notificationType.isEmpty) {
      debugPrint('IOT FCM ignored: missing data.messageType');
      return;
    }

    if (!_isDisplayableNotification(message, notificationType)) {
      debugPrint(
        'IOT FCM ignored: $notificationType payload is not a display '
        'notification.',
      );
      return;
    }

    final notificationKey = _localNotificationKey(message, notificationType);
    if (!_markLocalNotificationAsShown(notificationKey)) {
      debugPrint('IOT FCM ignored: duplicate notification $notificationKey');
      return;
    }

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

      default:
        debugPrint(
          'IOT FCM ignored: unsupported messageType $notificationType',
        );
    }
  } catch (e, s) {
    debugPrint('IOT show notification error: $e');
    debugPrintStack(stackTrace: s);
  }
}

Future<void> debugIotNotificationState([String source = '']) async {
  try {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    String? apnsToken;
    if (Platform.isIOS || Platform.isMacOS) {
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    }

    final label = source.isEmpty ? '' : ' [$source]';
    debugPrint(
      'IOT notification state$label: '
      'authorization=${settings.authorizationStatus.name}, '
      'alert=${settings.alert.name}, '
      'badge=${settings.badge.name}, '
      'sound=${settings.sound.name}, '
      'apnsToken=${_maskedToken(apnsToken)}, '
      'fcmToken=${_maskedToken(fcmToken)}',
    );
  } catch (e, s) {
    debugPrint('IOT notification state error: $e');
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

String _maskedToken(String? token) {
  if (token == null || token.isEmpty) return '<empty>';
  if (token.length <= 12) return token;
  return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
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

bool _isDisplayableNotification(
  RemoteMessage message,
  String notificationType,
) {
  switch (notificationType) {
    case 'IM':
      return _messageValue(message.data, 'title').isNotEmpty;
    case 'AR':
      return (_notificationTitle(message) ?? '').isNotEmpty;
    default:
      return true;
  }
}

String _localNotificationKey(RemoteMessage message, String notificationType) {
  final data = message.data;
  switch (notificationType) {
    case 'IM':
      return [
        'IM',
        _messageValue(data, 'notificationId'),
        _messageValue(data, 'originalId'),
        _messageValue(data, 'originalCreator'),
        _messageValue(data, 'id'),
        _messageValue(data, 'time'),
      ].join(':');
    case 'AR':
      return [
        'AR',
        _messageValue(data, 'id'),
        _messageValue(data, 'reportType'),
        _messageValue(data, 'time'),
      ].join(':');
    default:
      final messageId = message.messageId;
      if (messageId != null && messageId.isNotEmpty) return 'fcm:$messageId';
      return '$notificationType:${DateTime.now().microsecondsSinceEpoch}';
  }
}

bool _markLocalNotificationAsShown(String key) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final windowMs = _localNotificationDedupeWindow.inMilliseconds;
  _recentLocalNotificationKeys.removeWhere(
    (_, shownAt) => now - shownAt > windowMs,
  );

  final shownAt = _recentLocalNotificationKeys[key];
  if (shownAt != null && now - shownAt <= windowMs) return false;

  _recentLocalNotificationKeys[key] = now;
  return true;
}

Future<void> _createAndroidNotificationChannel() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(notificationChannel);
}

bool _hasRemoteNotificationPayload(RemoteMessage message) {
  return message.notification != null;
}
