import 'dart:async';
import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/viewmodel/init_local_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class IotAccountService {
  static const _notificationTimeout = Duration(seconds: 8);
  static const _requestTimeout = Duration(seconds: 30);

  Future<http.Response> loginIot(
    String gmail,
    String guid,
    String uuid,
    String os,
  ) async {
    String fcmToken = '';
    try {
      await initializeIotLocalNotifications();
      await requestIotNotificationPermissions();
      fcmToken = await FirebaseMessaging.instance
              .getToken()
              .timeout(_notificationTimeout) ??
          '';
    } catch (e, s) {
      debugPrint('IOT login: cannot get FCM token: $e');
      debugPrintStack(stackTrace: s);
    }

    Codec<String, String> codec = utf8.fuse(base64);
    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(IOT_REQUEST_URL + 'loginWithGmail'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Vendor': codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode(<String, String>{
              'gmail': codec.encode(gmail),
              'guid': codec.encode(guid),
              'uuid': uuid,
              'fcmtoken': fcmToken,
              'os': codec.encode(os),
            }),
          )
          .timeout(_requestTimeout);
      final responseInfo = response.statusCode == 200
          ? 'success'
          : response.body;
      debugPrint(
        'IOT login response ${response.statusCode}: $responseInfo',
      );
      return response;
    } finally {
      client.close();
    }
  }

  Future<bool> logout() async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'logout_iot'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
          )
          .timeout(Duration(seconds: 25));
      return true;
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
