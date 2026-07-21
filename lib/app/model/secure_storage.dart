import 'package:flutter/services.dart';

abstract interface class IotSecureStore {
  Future<void> writeAll(Map<String, String> values);

  Future<Map<String, String>> readAll(List<String> keys);

  Future<void> deleteAll(List<String> keys);
}

class IotPlatformSecureStorage implements IotSecureStore {
  static const MethodChannel _channel = MethodChannel(
    'org.vbspdng.msp/secure_storage',
  );

  @override
  Future<void> writeAll(Map<String, String> values) async {
    await _channel.invokeMethod<void>('writeAll', <String, Object>{
      'values': values,
    });
  }

  @override
  Future<Map<String, String>> readAll(List<String> keys) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'readAll',
      <String, Object>{'keys': keys},
    );

    if (result == null) return <String, String>{};
    return <String, String>{
      for (final entry in result.entries)
        if (entry.value is String) entry.key: entry.value! as String,
    };
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    await _channel.invokeMethod<void>('deleteAll', <String, Object>{
      'keys': keys,
    });
  }
}
