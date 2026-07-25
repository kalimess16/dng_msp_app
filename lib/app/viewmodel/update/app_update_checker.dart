import 'dart:io';

import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/resource/var/app_static_variable.dart';
import 'package:dngmsp/app/service/update/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkIotAppStoreUpdate(BuildContext context) async {
  if (IotStaticVariable.iotUpdateCheckClaimed || !Platform.isIOS) return;
  IotStaticVariable.iotUpdateCheckClaimed = true;

  final storeVersion = await IotAppUpdateService()
      .fetchLatestAppStoreVersion();
  if (storeVersion == null) {
    IotStaticVariable.iotUpdateCheckClaimed = false;
    return;
  }

  final packageInfo = await PackageInfo.fromPlatform();
  final isOutdated = IotAppUpdateService().isVersionOutdated(
    installedVersion: packageInfo.version,
    storeVersion: storeVersion,
  );
  if (!isOutdated) {
    IotStaticVariable.iotUpdateCheckClaimed = false;
    return;
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Có phiên bản mới'),
        content: const Text(
          'IOT đã có phiên bản mới trên App Store. Vui lòng cập nhật để tiếp tục sử dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await launchUrl(
                Uri.parse(IOT_APP_STORE_URL),
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
