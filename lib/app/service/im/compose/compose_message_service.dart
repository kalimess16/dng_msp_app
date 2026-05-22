import 'dart:convert';
import 'dart:io';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

List<IotInternalMessage> parseIotInternalMessage(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotInternalMessage.fromJson(json)).toList();
}

class IotComposeMessageService {
  Future<bool> uploadMessage(
    String wsToken,
    int originalId,
    String receivers,
    String content,
    List<File> files,
  ) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(IOT_REQUEST_URL + 'uploadDocumentFiles'),
      );
      request.headers.addAll({
        "Authorization": "Bearer " + wsToken,
        "Vendor": codec.encode(IOT_APP_VERSION),
      });
      request.fields.addAll({
        'originalId': '$originalId',
        'receiver': receivers,
        'content': content,
      });
      files.forEach((element) async {
        String _mimeType = lookupMimeType(element.path) ?? '';
        if (_mimeType.isNotEmpty) {
          var _types = _mimeType.split('/');
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              element.path,
              contentType: MediaType(_types[0], _types[1]),
            ),
          );
        } else
          request.files.add(
            await http.MultipartFile.fromPath('files', element.path),
          );
      });
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200 && response.body == 'SUCCESS') return true;
      throw IotException(
        error: response.headers['iot-upgrade'] ?? 'N',
        code: response.statusCode,
      );
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<List<IotInternalMessage>> uploadMessageInList(
    String wsToken,
    int originalId,
    String receivers,
    String content,
    List<File> files,
  ) async {
    try {
      Codec<String, String> codec = utf8.fuse(base64);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(IOT_REQUEST_URL + 'uploadDocumentFilesInList'),
      );
      request.headers.addAll({
        "Authorization": "Bearer " + wsToken,
        "Vendor": codec.encode(IOT_APP_VERSION),
      });
      request.fields.addAll({
        'originalId': '$originalId',
        'receiver': receivers,
        'content': content,
      });
      files.forEach((element) async {
        String _mimeType = lookupMimeType(element.path) ?? '';
        if (_mimeType.isNotEmpty) {
          var _types = _mimeType.split('/');
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              element.path,
              contentType: MediaType(_types[0], _types[1]),
            ),
          );
        } else
          request.files.add(
            await http.MultipartFile.fromPath('files', element.path),
          );
      });
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode != 200)
        throw IotException(
          error: response.headers['iot-upgrade'] ?? 'N',
          code: response.statusCode,
        );
      return compute(parseIotInternalMessage, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
