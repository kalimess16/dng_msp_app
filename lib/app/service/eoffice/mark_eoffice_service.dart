import 'dart:convert';

import 'package:dngmsp/app/model/eoffice/mark_eoffice.dart';
import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/service/im/reply/reply_internal_message_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<MarkEoffice> parseMarkEofficeList(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => MarkEoffice.fromJson(json)).toList();
}

class MarkEofficeService {
  Future<List<String>> fetchMarkEofficeAgencies() async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(
          Uri.parse(IOT_REQUEST_URL + 'fetchMarkEofficeAgency'),
          headers: {
            "Authorization": "Bearer " + wsToken,
            "Vendor": codec.encode(IOT_APP_VERSION)
          }).timeout(Duration(seconds: 25));
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

  Future<MarkEoffice> fetchMarkEoffice(int eOfficeId, int messageId,
      String messageCreator, int messageFileOrder) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'fetchMarkEoffice'),
              headers: {
                "Authorization": "Bearer " + wsToken,
                "Vendor": codec.encode(IOT_APP_VERSION)
              },
              body: jsonEncode({
                'eOfficeId': '$eOfficeId',
                'messageCreator': messageCreator,
                'messageId': '$messageId',
                'messageFileOrder': '$messageFileOrder'
              }))
          .timeout(Duration(seconds: 30));
      if (response.statusCode != 200)
        throw IotException(
            error: response.headers['iot-upgrade'] ?? 'N',
            code: response.statusCode);
      if (response.body == 'null') return MarkEoffice(0, '', '', '', '', '', 0, 'N', 0);
      return MarkEoffice.fromJson(jsonDecode(response.body));
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException'))
        throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }

  Future<bool> saveMarkEoffice(
      int eOfficeId,
      int messageId,
      String messageCreator,
      int messageFileOrder,
      String eOfficeTitle,
      String agencyName,
      String eOfficeDate,
      String eOfficeNote) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'saveMarkEoffice'),
              headers: {
                "Authorization": "Bearer " + wsToken,
                "Vendor": codec.encode(IOT_APP_VERSION)
              },
              body: jsonEncode({
                'eOfficeId': '$eOfficeId',
                'messageId': '$messageId',
                'messageCreator': messageCreator,
                'messageFileOrder': '$messageFileOrder',
                'eTitle': eOfficeTitle,
                'agencyName': agencyName,
                'eDate': eOfficeDate,
                'eNote': eOfficeNote
              }))
          .timeout(Duration(seconds: 30));
      if (response.statusCode != 200)
        throw IotException(
            error: response.headers['iot-upgrade'] ?? 'N',
            code: response.statusCode);
      return response.body == 'SUCCESS';
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException'))
        throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }

  Future<List<MarkEoffice>> searchMarkEoffices(String fromDate,
      String toDate, String keyword, String findInNote, int agency, int startId, int statusPage) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      late String wsToken;
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(Uri.parse(IOT_REQUEST_URL + 'searchSelfMarkEoffice'),
          headers: {
            "Authorization": "Bearer " + wsToken,
            "Vendor": codec.encode(IOT_APP_VERSION)
          },
          body: jsonEncode({
            'fromDate': fromDate,
            'toDate': toDate,
            'keyword': keyword,
            'innote': findInNote,
            'office': '$agency',
            'startId': '$startId',
            'statusPage': '$statusPage',
          }))
          .timeout(Duration(seconds: 30));
      if (response.statusCode != 200)
        throw IotException(
            error: response.headers['iot-upgrade'] ?? 'N',
            code: response.statusCode);
      if (response.body == 'null') return [];
      return compute(parseMarkEofficeList, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      if (e.toString().contains('errno = 101')) throw IotException(code: 101);
      if (e.toString().startsWith('TimeoutException'))
        throw IotException(code: 408);
      throw IotException(code: 0);
    }
  }


  Future<IotDownloadFile> downloadDataFiles(String markDocId) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(
          Uri.parse(IOT_REQUEST_URL + 'downloadMarkEofficeFile'),
          headers: {"Authorization": "Bearer " + wsToken, "Vendor": codec.encode(IOT_APP_VERSION)},
          body: jsonEncode({
            'markDoc': '$markDocId'
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
