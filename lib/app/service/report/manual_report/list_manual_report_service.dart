import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/report/iot_list_report.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotListReport> parseIotListReports(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotListReport.fromJson(json)).toList();
}

class IotListManualReportService {
  Future<List<IotListReport>> fetchIotListReports(String type) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'listCompactReports?type=$type'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
          )
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
          error: response.headers['iot-upgrade'] ?? 'N',
          code: response.statusCode,
        );
      return compute(parseIotListReports, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
