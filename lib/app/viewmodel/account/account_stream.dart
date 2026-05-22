import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dngmsp/app/model/account/account.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/login_strings.dart';
import 'package:dngmsp/app/service/account/account_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class IotAccountStream {
  var _loginIotController = StreamController<String>.broadcast();
  Stream<String> get loginIotStream => _loginIotController.stream;

  void dispose() => _loginIotController.close();

  void loginIot(String type) async {
    _loginIotController.sink.add(LOGIN_AUTH_KEY);
    FirebaseAuth _auth = FirebaseAuth.instance;
    GoogleSignIn _googleSignIn = GoogleSignIn();

    switch (type) {
      case 'GOOGLE':
        _loginIotController.sink.add(
          await _loginWithGoogle(_auth, _googleSignIn),
        );
        break;
      case 'APPLE':
        _loginIotController.sink.add(
          await _loginWithApple(_auth, _googleSignIn),
        );
        break;
      default:
        _loginIotController.sink.add(LOGIN_FAIL_KEY);
        break;
    }
  }

  Future<String> _loginWithGoogle(
    FirebaseAuth _auth,
    GoogleSignIn _googleSignIn,
  ) async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn
          .signIn();
      if (googleSignInAccount == null) return LOGIN_CANCELLED_KEY;
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      if (googleSignInAuthentication.accessToken == null &&
          googleSignInAuthentication.idToken == null) {
        debugPrint('IOT login: missing Google auth token');
        return LOGIN_FIREBASE_ERROR_KEY;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      User? _user = (await _auth.signInWithCredential(credential)).user;
      if (_user == null) return LOGIN_FAIL_KEY;
      return await _authenticationIot(_googleSignIn, _user.email!, _user.uid);
    } on FirebaseAuthException catch (ex, s) {
      debugPrint('IOT login FirebaseAuthException: ${ex.code} ${ex.message}');
      debugPrintStack(stackTrace: s);
      return ex.code == 'network-request-failed'
          ? LOGIN_NETWORK_ERROR_KEY
          : LOGIN_FIREBASE_ERROR_KEY;
    } on PlatformException catch (ex, s) {
      debugPrint('IOT login PlatformException: ${ex.code} ${ex.message}');
      debugPrintStack(stackTrace: s);
      final message = '${ex.code} ${ex.message}'.toLowerCase();
      if (message.contains('network_error') ||
          message.contains('apiexception: 7')) {
        return LOGIN_NETWORK_ERROR_KEY;
      }
      if (message.contains('sign_in_canceled') ||
          message.contains('apiexception: 12501')) {
        return LOGIN_CANCELLED_KEY;
      }
      return LOGIN_FIREBASE_ERROR_KEY;
    } catch (ex, s) {
      debugPrint('IOT login Google error: $ex');
      debugPrintStack(stackTrace: s);
      final errorMessage = ex.toString().toLowerCase();
      if (errorMessage.contains('network_error') ||
          errorMessage.contains('apiexception: 7')) {
        return LOGIN_NETWORK_ERROR_KEY;
      }
    }
    return LOGIN_FAIL_KEY;
  }

  Future<String> _loginWithApple(
    FirebaseAuth _auth,
    GoogleSignIn _googleSignIn,
  ) async {
    try {
      final appCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (appCredential.identityToken != null) {
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: appCredential.identityToken,
          accessToken: appCredential.authorizationCode,
        );
        User? _user = (await _auth.signInWithCredential(credential)).user;
        if (_user == null) return LOGIN_FAIL_KEY;
        final email = _user.email ?? appCredential.email;
        if (email == null) return LOGIN_FAIL_KEY;

        return await _authenticationIot(_googleSignIn, email, _user.uid);
      }
    } on FirebaseAuthException catch (e, s) {
      debugPrint(
        'IOT login Apple FirebaseAuthException: ${e.code} ${e.message}',
      );
      debugPrintStack(stackTrace: s);
      return LOGIN_FIREBASE_ERROR_KEY;
    } catch (e, s) {
      debugPrint('IOT login Apple error: $e');
      debugPrintStack(stackTrace: s);
    }
    return LOGIN_FAIL_KEY;
  }

  Future<String> _authenticationIot(
    GoogleSignIn _googleSignIn,
    String gmail,
    String guid,
  ) async {
    late String _uuid, _os;
    if (Platform.isAndroid) {
      _uuid = await const AndroidId().getId() ?? '';
      _os = "Android";
    } else if (Platform.isIOS) {
      var deviceInfo = DeviceInfoPlugin();
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _uuid = iosInfo.identifierForVendor ?? '';
      _os = "IOS";
    }

    try {
      final response = await IotAccountService()
          .loginIot(gmail, guid, _uuid, _os)
          .timeout(Duration(seconds: 20));

      await _googleSignIn.signOut();
      if (response.body == LOGIN_VENDOR) return LOGIN_VENDOR;
      if (response.statusCode != 200) {
        debugPrint(
          'IOT login backend rejected: ${response.statusCode} ${response.body}',
        );
        return LOGIN_BACKEND_ERROR_KEY;
      }

      try {
        IotUser _user = IotUser.fromJson(jsonDecode(response.body));
        if (!await IotSharedPreferences().clear()) {
          return LOGIN_TOKEN_SAVE_ERROR_KEY;
        }
        final saved = await IotSharedPreferences().set(
          _user.wsToken,
          _user.fullName,
          gmail,
          _user.username,
        );
        return saved ? LOGIN_SUCCESS_KEY : LOGIN_TOKEN_SAVE_ERROR_KEY;
      } catch (e, s) {
        debugPrint('IOT login cannot save session: $e');
        debugPrintStack(stackTrace: s);
        return LOGIN_TOKEN_SAVE_ERROR_KEY;
      }
    } catch (e, s) {
      debugPrint('IOT login backend/network error: $e');
      debugPrintStack(stackTrace: s);
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final message = e.toString().toLowerCase();
      if (e is TimeoutException ||
          message.contains('socketexception') ||
          message.contains('clientexception') ||
          message.contains('handshakeexception') ||
          message.contains('failed host lookup') ||
          message.contains('network')) {
        return LOGIN_NETWORK_ERROR_KEY;
      }
      return LOGIN_BACKEND_ERROR_KEY;
    }
  }

  Future<bool> logout() async {
    return await IotAccountService().logout();
  }
}
