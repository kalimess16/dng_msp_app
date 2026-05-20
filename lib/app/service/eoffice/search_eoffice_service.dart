import 'dart:convert';

import 'package:dngmsp/app/model/eoffice/eoffice.dart';
import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/service/im/reply/reply_internal_message_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<Eoffice> parseEofficeList(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => Eoffice.fromJson(json)).toList();
}

class SearchEofficeService {
  Future<List<String>> fetchEofficeAgencies(int type) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'fetchEofficeAgency?type=$type'),
              headers: {
                "Authorization": "Bearer " + wsToken,
                "Vendor": codec.encode(IOT_APP_VERSION)
              },
              body: jsonEncode({
                'type': '$type',
              }))
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
            error: response.headers['iot-upgrade'] ?? 'N',
            code: response.statusCode);
      if (response.body == 'null') return [];
      return response.body.split('#');
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException'))
        throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }

  Future<List<Eoffice>> fetchEoffices(int type, int agency, String fromDate,
      String toDate, String keyword, int startId, int statusPage) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'searchEofficeApproval'),
              headers: {
                "Authorization": "Bearer " + wsToken,
                "Vendor": codec.encode(IOT_APP_VERSION)
              },
              body: jsonEncode({
                'type': '$type',
                'office': '$agency',
                'fromDate': fromDate,
                'toDate': toDate,
                'keyword': keyword,
                'startId': '$startId',
                'statusPage': '$statusPage',
              }))
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
            error: response.headers['iot-upgrade'] ?? 'N',
            code: response.statusCode);
      if (response.body == 'null') return [];
      return compute(parseEofficeList, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException'))
        throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }

  Future<IotDownloadFile> downloadDataFiles(int docId) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(
          Uri.parse(IOT_REQUEST_URL + 'downloadEofficeApprovalFile'),
          headers: {"Authorization": "Bearer " + wsToken, "Vendor": codec.encode(IOT_APP_VERSION)},
          body: jsonEncode({
            'docId': '$docId'
          }));
      if (response.statusCode != 200)
        throw IotException(code: response.statusCode, error: response.headers['iot-upgrade'] ?? 'N');
      return compute(parseIotDownloadDataFile, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      throw IotException(code: 0);
    }
  }
}
