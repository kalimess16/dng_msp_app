import 'exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IotSharedPreferences {
  final String iotPrefsWsToken = 'dngWsToken';
  final String iotPrefsWsFullName = 'dngFullName';
  final String iotPrefsWsEmail = 'dngEmail';
  final String iotPrefsWsUsername = 'dngUsername';

  Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }

  void set(String wsToken, String fullName, String email, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(iotPrefsWsToken, wsToken);
      prefs.setString(iotPrefsWsFullName, fullName);
      prefs.setString(iotPrefsWsEmail, email);
      prefs.setString(iotPrefsWsUsername, username);
    } catch (exp) {
      throw IotException(code: 0);
    }
  }

  Future<List<String>> get() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.get(iotPrefsWsToken) == null || prefs.get(iotPrefsWsUsername) == null)
        return [];
      else
        return [
          prefs.get(iotPrefsWsToken) as String,
          prefs.get(iotPrefsWsFullName) as String,
          prefs.get(iotPrefsWsEmail) as String,
          prefs.get(iotPrefsWsUsername) as String
        ];
    } catch (exp) {
      throw IotException(code: 0);
    }
  }
}
