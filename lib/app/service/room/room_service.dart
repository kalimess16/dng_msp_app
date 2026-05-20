import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/report/data_report.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotDataReport> parseIotServerRoom(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotDataReport.fromJson(json)).toList();
}

class IotServerRoomService {
  Future<List<IotDataReport>> fetchIotServerRoom() async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(
          Uri.parse(IOT_REQUEST_URL + '1~IPCAM'),
          headers: {
            "Authorization": "Bearer " + wsToken,
            "Vendor": codec.encode(IOT_APP_VERSION)
          },
          body: jsonEncode({"reportDate": "X", "reportCode": "X"}))
      .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
            code: response.statusCode, error: response.headers['iot-upgrade'] ?? 'N');
      return compute(parseIotServerRoom, response.body);
    }
    on IotException catch(e) {
      throw e;
    }
    catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException')) throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }

}