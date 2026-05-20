import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/report/auto_report.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotAutoReport> parseIotListAutoReport(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotAutoReport.fromJson(json)).toList();
}

class IotListAutoReportService {
  Future<List<IotAutoReport>> fetchAutoReports(int startTime) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'listAutoReports?startTime=$startTime'), headers: {
        "Authorization": "Bearer " + wsToken,
        "Vendor": codec.encode(IOT_APP_VERSION)
      }).timeout(Duration(seconds: 45));
      if (response.statusCode != 200)
        throw IotException(code: response.statusCode, error: response.headers['iot-upgrade'] ?? 'N');
      if (response.body == 'null') return [];
      return compute(parseIotListAutoReport, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException')) throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }

  Future<bool> readAutoReport(int id, String type) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'readAutoReport'),
              headers: {
                "Authorization": "Bearer " + wsToken,
                "Vendor": codec.encode(IOT_APP_VERSION)
              },
              body: jsonEncode({'id': '$id', 'type': type}))
          .timeout(Duration(seconds: 45));
      if (response.statusCode != 200)
        throw IotException(code: response.statusCode, error: response.headers['iot-upgrade'] ?? 'N');
      return (response.body == 'SUCCESS');
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException')) throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }

  Future<int> countUnreadAutoReports() async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(Uri.parse(IOT_REQUEST_URL + 'countUnreadAutoReports'),
          headers: {
            "Authorization": "Bearer " + wsToken,
            "Vendor": codec.encode(IOT_APP_VERSION)
          }).timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(code: response.statusCode, error: response.headers['iot-upgrade'] ?? 'N');

      return (int.tryParse(response.body) ?? 0);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException')) throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }
}
