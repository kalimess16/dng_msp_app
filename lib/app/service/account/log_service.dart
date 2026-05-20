import 'dart:convert';

import 'package:dngmsp/app/model/account/log.dart';
import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotAccountLog> parseIotAccountLogs(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotAccountLog.fromJson(json)).toList();
}

class IotAccountLogService {
  Future<List<IotAccountLog>> fetchIotUserLogs() async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(
          Uri.parse(IOT_REQUEST_URL + 'listUserLogs'),
          headers: {
            "Authorization": "Bearer " + wsToken,
            "Vendor": codec.encode(IOT_APP_VERSION)
          });
      if (response.statusCode != 200)
        throw IotException(
            code: response.statusCode, error: response.headers['iot-upgrade'] ?? 'N');
      return compute(parseIotAccountLogs, response.body);
    }
    on IotException catch(e) {
      throw e;
    }
    catch (e) {
      if (e.toString().contains('errno = 101'))
        throw IotException(code: 101);
      throw IotException(code: 0);
    }
  }

}