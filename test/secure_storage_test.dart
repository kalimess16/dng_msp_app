import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/secure_storage.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureStore implements IotSecureStore {
  final Map<String, String> values = <String, String>{};
  bool failWrites = false;

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }

  @override
  Future<Map<String, String>> readAll(List<String> keys) async {
    return <String, String>{
      for (final key in keys)
        if (values[key] case final value?) key: value,
    };
  }

  @override
  Future<void> writeAll(Map<String, String> newValues) async {
    if (failWrites) throw StateError('write failed');
    values.addAll(newValues);
  }
}

void main() {
  group('IotSharedPreferences secure facade', () {
    test('stores and restores the complete credential set', () async {
      final storage = _FakeSecureStore();
      final preferences = IotSharedPreferences(storage: storage);

      expect(
        await preferences.set('token', 'Full Name', 'user@internal', 'user'),
        isTrue,
      );
      expect(await preferences.get(), <String>[
        'token',
        'Full Name',
        'user@internal',
        'user',
      ]);
    });

    test('fails closed when credentials are incomplete', () async {
      final storage = _FakeSecureStore()
        ..values[IotSharedPreferences.iotPrefsWsToken] = 'token';
      final preferences = IotSharedPreferences(storage: storage);

      expect(await preferences.get(), isEmpty);
    });

    test('clears all credential fields', () async {
      final storage = _FakeSecureStore();
      final preferences = IotSharedPreferences(storage: storage);
      await preferences.set('token', 'Full Name', 'user@internal', 'user');

      expect(await preferences.clear(), isTrue);
      expect(await preferences.get(), isEmpty);
      expect(storage.values, isEmpty);
    });

    test('does not report a failed secure write as successful', () async {
      final storage = _FakeSecureStore()..failWrites = true;
      final preferences = IotSharedPreferences(storage: storage);

      await expectLater(
        preferences.set('token', 'Full Name', 'user@internal', 'user'),
        throwsA(isA<IotException>()),
      );
    });
  });
}
