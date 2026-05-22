import 'dart:convert';
import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:http/http.dart' as http;

class IotForwardMessageService {
  Future<bool> uploadForwardMessage(
    String wsToken,
    int originalId,
    String originalCreator,
    int messageId,
    String messageCreator,
    String receivers,
    String forwardContent,
  ) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'uploadForwardMessage'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({
              'originalId': '$originalId',
              'originalCreator': originalCreator,
              'messageId': '$messageId',
              'messageCreator': messageCreator,
              'receivers': receivers,
              'forwardContent': forwardContent,
            }),
          )
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      return (response.statusCode == 200 && response.body == 'SUCCESS');
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
