import 'dart:io';

import 'package:path_provider/path_provider.dart';

class IotBackgroundInternalMessage {
  final String _jsonFilename = 'bg_messages.iot';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_jsonFilename');
  }

  Future<void> appendImNotificationId(int notificationId) async {
    final file = await _localFile;
    List<String> _list = await readImNotificationIds();
    if (!_list.contains('$notificationId'))
      file.writeAsStringSync('$notificationId;', mode: FileMode.append);
  }

  Future<List<String>> readImNotificationIds() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];
      final String content = await file.readAsString();
      return content.split(';');
    } catch (e, s) {
      print(s);
      return [];
    }
  }

  void deleteJsonFile() async {
    final file = await _localFile;
    if (await file.exists()) file.deleteSync();
  }
}
