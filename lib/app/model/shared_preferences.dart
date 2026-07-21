import 'exception.dart';
import 'secure_storage.dart';

class IotSharedPreferences {
  static const String iotPrefsWsToken = 'dngWsToken';
  static const String iotPrefsWsFullName = 'dngFullName';
  static const String iotPrefsWsEmail = 'dngEmail';
  static const String iotPrefsWsUsername = 'dngUsername';

  static const List<String> _keys = <String>[
    iotPrefsWsToken,
    iotPrefsWsFullName,
    iotPrefsWsEmail,
    iotPrefsWsUsername,
  ];

  final IotSecureStore _storage;

  IotSharedPreferences({IotSecureStore? storage})
    : _storage = storage ?? IotPlatformSecureStorage();

  Future<bool> clear() async {
    try {
      await _storage.deleteAll(_keys);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> set(
    String wsToken,
    String fullName,
    String email,
    String username,
  ) async {
    try {
      await _storage.writeAll(<String, String>{
        iotPrefsWsToken: wsToken,
        iotPrefsWsFullName: fullName,
        iotPrefsWsEmail: email,
        iotPrefsWsUsername: username,
      });
      return true;
    } catch (exp) {
      throw IotException(code: 0);
    }
  }

  Future<List<String>> get() async {
    try {
      final values = await _storage.readAll(_keys);
      final token = values[iotPrefsWsToken];
      final fullName = values[iotPrefsWsFullName];
      final email = values[iotPrefsWsEmail];
      final username = values[iotPrefsWsUsername];

      if (token == null ||
          token.isEmpty ||
          fullName == null ||
          email == null ||
          username == null ||
          username.isEmpty) {
        return <String>[];
      }
      return <String>[token, fullName, email, username];
    } catch (_) {
      // Fail closed: unreadable credentials require a new login.
      return <String>[];
    }
  }
}
