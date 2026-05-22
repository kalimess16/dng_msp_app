import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/report/data_report.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotDataReport> parseIotDetailReport(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotDataReport.fromJson(json)).toList();
}

class IotDetailManualReportService {
  Future<List<IotDataReport>> fetchDetailReport(
    String reportCode,
    Map<String, dynamic> mapReportParameters,
  ) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      var _map = mapReportParameters;
      _map.updateAll((key, value) => (value ?? ''));
      _map.putIfAbsent("reportCode", () => reportCode);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + "detailCompactReports"),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode(_map),
          )
          .timeout(Duration(seconds: 35));
      if (response.statusCode != 200)
        throw IotException(
          error: response.headers['iot-upgrade'] ?? 'N',
          code: response.statusCode,
        );
      if (response.body == 'null' || response.body == '[]')
        throw IotException(code: -2);
      return compute(parseIotDetailReport, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
