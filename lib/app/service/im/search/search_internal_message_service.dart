import 'dart:convert';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<IotInternalMessage> parseIotInternalMessage(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotInternalMessage.fromJson(json)).toList();
}

class IotSearchInternalMessagesService {
  Future<List<IotInternalMessage>> fetchInternalMessages(
    String fromDate,
    String toDate,
    String senders,
    String messageContent,
    int startTime,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'searchInternalMessages'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({
              'fromDate': fromDate,
              'toDate': toDate,
              'senders': senders,
              'content': messageContent,
              'startTime': '$startTime',
            }),
          )
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null') return [];
      return compute(parseIotInternalMessage, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
