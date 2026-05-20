import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dngmsp/app/model/account/account.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/login_strings.dart';
import 'package:dngmsp/app/service/account/account_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        _loginIotController.sink
            .add(await _loginWithGoogle(_auth, _googleSignIn));
        break;
      case 'APPLE':
        _loginIotController.sink
            .add(await _loginWithApple(_auth, _googleSignIn));
        break;
    }
  }

  Future<String> _loginWithGoogle(
      FirebaseAuth _auth, GoogleSignIn _googleSignIn) async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      User? _user = (await _auth.signInWithCredential(credential)).user;
      if (_user == null) return LOGIN_FAIL_KEY;
      return await _authenticationIot(_googleSignIn, _user.email!, _user.uid);
    } catch (ex, s) {
      print(s);
    }
    return LOGIN_FAIL_KEY;
  }

  Future<String> _loginWithApple(
      FirebaseAuth _auth, GoogleSignIn _googleSignIn) async {
    try {
      final appCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (appCredential.state != null && appCredential.email != null) {
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: appCredential.identityToken,
          accessToken: appCredential.authorizationCode,
        );
        User? _user = (await _auth.signInWithCredential(credential)).user;
        if (_user == null) return LOGIN_FAIL_KEY;

        return await _authenticationIot(_googleSignIn, _user.email!, _user.uid);
      }
    } catch (e) {
      print(e);
    }
    return LOGIN_FAIL_KEY;
  }

  Future<String> _authenticationIot(
      GoogleSignIn _googleSignIn, String gmail, String guid) async {
    if (!await IotSharedPreferences().clear()) {
      return LOGIN_FAIL_KEY;
    }

    late String _uuid, _os;
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _uuid = androidInfo.androidId ?? '';
      _os = "Android";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _uuid = iosInfo.identifierForVendor ?? '';
      _os = "IOS";
    }
    return await IotAccountService()
        .loginIot(gmail, guid, _uuid, _os)
        .timeout(Duration(seconds: 20))
        .then((response) async {
      var _isAuth = (response.statusCode == 200);
      if (_isAuth) {
        IotUser _user = IotUser.fromJson(jsonDecode(response.body));
        IotSharedPreferences()
            .set(_user.wsToken, _user.fullName, gmail, _user.username);
      }
      await _googleSignIn.signOut();
      if (response.body == LOGIN_VENDOR) return LOGIN_VENDOR;
      return (_isAuth ? LOGIN_SUCCESS_KEY : LOGIN_FAIL_KEY);
    }).catchError((e, s) {
      return LOGIN_FAIL_KEY;
    });
  }

  Future<bool> logout() async {
    return await IotAccountService().logout();
  }
}
