
import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class IotAccountService {
  Future<http.Response> loginIot(String gmail, String guid, String uuid, String os) async {
    late String fcmToken;
    await FirebaseMessaging.instance.getToken().then((String? token) {
      assert(token != null);
      fcmToken = token!;
    });
      Codec<String, String> codec = utf8.fuse(base64);
    http.Response r = await http
          .post(Uri.parse(IOT_REQUEST_URL + 'loginWithGmail'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            "Vendor": codec.encode(IOT_APP_VERSION)
          },
          body: jsonEncode(<String, String>{
            'gmail': codec.encode(gmail),
            'guid': codec.encode(guid),
            'uuid': uuid,
            'fcmtoken': fcmToken,
            'os': codec.encode(os)
          }));
    print('HỂ ${r.body}');
    return r;
  }

  Future<bool> logout() async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'logout_iot'),
          headers: {
            "Authorization": "Bearer " + wsToken,
            "Vendor": codec.encode(IOT_APP_VERSION)
          })
          .timeout(Duration(seconds: 25));
      return true;
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException')) throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }
}