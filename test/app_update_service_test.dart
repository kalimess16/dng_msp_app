import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/service/update/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('IotAppUpdateService.isVersionOutdated', () {
    final service = IotAppUpdateService();

    test('flags installed version as outdated when store version is higher', () {
      expect(
        service.isVersionOutdated(
          installedVersion: '1.0.0',
          storeVersion: '1.0.1',
        ),
        isTrue,
      );
    });

    test('does not flag when installed version matches store version', () {
      expect(
        service.isVersionOutdated(
          installedVersion: '1.0.0',
          storeVersion: '1.0.0',
        ),
        isFalse,
      );
    });

    test('does not flag when installed version is newer than store version', () {
      expect(
        service.isVersionOutdated(
          installedVersion: '1.2.0',
          storeVersion: '1.1.9',
        ),
        isFalse,
      );
    });

    test('compares version segments numerically, not lexicographically', () {
      expect(
        service.isVersionOutdated(
          installedVersion: '1.9.0',
          storeVersion: '1.10.0',
        ),
        isTrue,
      );
    });

    test('treats missing trailing segments as zero', () {
      expect(
        service.isVersionOutdated(installedVersion: '1.0', storeVersion: '1.0.1'),
        isTrue,
      );
      expect(
        service.isVersionOutdated(installedVersion: '1.0.0', storeVersion: '1.0'),
        isFalse,
      );
    });
  });

  group('IotAppUpdateService.fetchLatestAppStoreVersion', () {
    test(
      'looks up the real App Store listing and returns a version string',
      () async {
        final version = await IotAppUpdateService().fetchLatestAppStoreVersion();
        expect(version, isNotNull);
        expect(version, matches(RegExp(r'^\d+(\.\d+)*$')));
      },
      skip: !const bool.fromEnvironment('RUN_APP_STORE_LOOKUP_NETWORK_TEST'),
    );

    test('IOT_APP_STORE_URL points at the published listing', () {
      expect(
        IOT_APP_STORE_URL,
        'https://apps.apple.com/vn/app/iot-danang/id$IOT_APP_STORE_ITUNES_ID',
      );
    });

    test(
      'IOT_APP_STORE_URL actually resolves on the App Store (not a 404)',
      () async {
        final response = await http
            .get(Uri.parse(IOT_APP_STORE_URL))
            .timeout(const Duration(seconds: 8));
        expect(response.statusCode, 200);
      },
      skip: !const bool.fromEnvironment('RUN_APP_STORE_LOOKUP_NETWORK_TEST'),
    );
  });

  group('IotAppUpdateService.fetchLatestAndroidApkVersion', () {
    test(
      'looks up the real internal download page and returns the APK version',
      () async {
        final version = await IotAppUpdateService()
            .fetchLatestAndroidApkVersion();
        expect(version, isNotNull);
        expect(version, matches(RegExp(r'^\d+(\.\d+)*$')));
      },
      skip: !const bool.fromEnvironment(
        'RUN_ANDROID_UPDATE_PAGE_NETWORK_TEST',
      ),
    );
  });
}
