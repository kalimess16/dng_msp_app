import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/position.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotPosition> parseIotPosition(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotPosition.fromJson(json)).toList();
}

class IotPositionService {
  Future<List<IotPosition>> fetchIotPosition(String takeAll) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'listPositions'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({"takeAll": takeAll}),
          )
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      return compute(parseIotPosition, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<List<String>> fetchGroupMembers(String groupId) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'groupMembers'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({'group_id': groupId}),
          )
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      final parsed = response.body
          .replaceAll('"', '')
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',');

      return parsed;
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
