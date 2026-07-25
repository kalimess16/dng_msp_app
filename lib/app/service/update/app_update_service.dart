import 'dart:convert';

import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:http/http.dart' as http;

class IotAppUpdateService {
  static final Uri _lookupUri = Uri.parse(
    'https://itunes.apple.com/lookup?id=$IOT_APP_STORE_ITUNES_ID&country=vn',
  );

  Future<String?> fetchLatestAppStoreVersion() async {
    try {
      final response = await http
          .get(_lookupUri)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final results = body['results'];
      if (results is! List || results.isEmpty) return null;
      final first = results.first;
      if (first is! Map<String, dynamic>) return null;

      final version = first['version'];
      return version is String && version.isNotEmpty ? version : null;
    } catch (_) {
      return null;
    }
  }

  bool isVersionOutdated({
    required String installedVersion,
    required String storeVersion,
  }) {
    List<int> parse(String value) =>
        value.split('.').map((part) => int.tryParse(part) ?? 0).toList();

    final installed = parse(installedVersion);
    final store = parse(storeVersion);
    final length = installed.length > store.length
        ? installed.length
        : store.length;

    for (var index = 0; index < length; index++) {
      final installedPart = index < installed.length ? installed[index] : 0;
      final storePart = index < store.length ? store[index] : 0;
      if (storePart > installedPart) return true;
      if (storePart < installedPart) return false;
    }
    return false;
  }
}
