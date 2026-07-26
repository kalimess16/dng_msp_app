import 'dart:io';

import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/resource/var/app_static_variable.dart';
import 'package:dngmsp/app/service/update/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkIotAppUpdate(BuildContext context) async {
  if (IotStaticVariable.iotUpdateCheckClaimed) return;
  if (!Platform.isIOS && !Platform.isAndroid) return;
  IotStaticVariable.iotUpdateCheckClaimed = true;

  final service = IotAppUpdateService();
  final latestVersion = Platform.isIOS
      ? await service.fetchLatestAppStoreVersion()
      : await service.fetchLatestAndroidApkVersion();

  if (latestVersion == null) {
    IotStaticVariable.iotUpdateCheckClaimed = false;
    return;
  }

  final packageInfo = await PackageInfo.fromPlatform();
  final isOutdated = service.isVersionOutdated(
    installedVersion: packageInfo.version,
    storeVersion: latestVersion,
  );
  if (!isOutdated) {
    IotStaticVariable.iotUpdateCheckClaimed = false;
    return;
  }

  if (!context.mounted) return;

  final updateUrl = Platform.isIOS ? IOT_APP_STORE_URL : IOT_UPGRADE_APP_URL;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Có phiên bản mới'),
        content: const Text(
          'IOT đã có phiên bản mới. Vui lòng cập nhật để tiếp tục sử dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await launchUrl(
                Uri.parse(updateUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Cập nhật ngay'),
          ),
        ],
      ),
    ),
  );
}
