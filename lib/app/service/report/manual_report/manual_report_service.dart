import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/report/manual_report.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotManualReport> parseIotReports(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotManualReport.fromJson(json)).toList();
}

class IotManualReportService {
  Future<List<IotManualReport>> fetchIotReports(String reportCode) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'specCompactReports'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({"reportCode": reportCode}),
          )
          .timeout(Duration(seconds: 30));
      if (response.statusCode != 200)
        throw IotException(
          error: response.headers['iot-upgrade'] ?? 'N',
          code: response.statusCode,
        );
      if (response.body == 'null') return [];
      return compute(parseIotReports, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
