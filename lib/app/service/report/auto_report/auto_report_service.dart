import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/report/data_report.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotDataReport> parseIotAutoReport(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotDataReport.fromJson(json)).toList();
}

class IotAutoReportService {
  Future<List<IotDataReport>> fetchIotReports(
    String reportType,
    String reportDate,
    int reportCode,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);

      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + reportType),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({
              "reportDate": reportDate,
              "reportCode": '$reportCode',
            }),
          )
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null' || response.body == '[]')
        throw IotException(code: -2);

      return compute(parseIotAutoReport, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
