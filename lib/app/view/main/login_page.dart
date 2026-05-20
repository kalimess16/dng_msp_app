import 'dart:io';

import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/resource/string/login_strings.dart';
import 'package:dngmsp/app/viewmodel/account/account_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class IotLoginPage extends StatefulWidget {
  @override
  _IotLoginPageState createState() => _IotLoginPageState();
}

class _IotLoginPageState extends State<IotLoginPage> {
  final _loginIotViewModel = IotAccountStream();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
            body: StreamBuilder(
                stream: _loginIotViewModel.loginIotStream,
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.data != null &&
                      snapshot.data == LOGIN_SUCCESS_KEY) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pop();
                      Navigator.pushNamedAndRemoveUntil(
                          context, IotRoutes.HOME_PAGE, (route) => false);
                    });
                  }

                  var _wait = (snapshot.data != null &&
                      snapshot.data == LOGIN_AUTH_KEY);
                  var _fail = (snapshot.data != null &&
                      snapshot.data == LOGIN_FAIL_KEY);
                  var _vendor =
                      (snapshot.data != null && snapshot.data == LOGIN_VENDOR);
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(
                        width: 1.sw,
                        height: 1.sh,
                        alignment: Alignment.center,
                        decoration: _buildBoxDecoration(),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              _buildTitle(),
                              const SizedBox(height: 50),
                              (_wait
                                  ? CircularProgressIndicator(
                                      color: IOT_FG_COLOR)
                                  : _signInGroupButton()),
                              Flexible(
                                child: _showFailLoginMessage(_vendor, _fail),
                                fit: FlexFit.loose,
                              )
                            ])),
                  );
                }),
            bottomNavigationBar: _bottomNavBar()),
        onWillPop: () async => await _onWillIotPop(context));
  }

  Future<bool> _onWillIotPop(BuildContext context) async {
    Navigator.of(context).pop();
    SystemNavigator.pop();
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    return false;
  }

  @override
  void dispose() {
    _loginIotViewModel.dispose();
    super.dispose();
  }

  Widget _signInGroupButton() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          _signInGoogleButton(),
          Divider(),
          (Platform.isIOS ? _signInWithAppleButton() : SizedBox(height: 5))
        ]);
  }

  BoxDecoration _buildBoxDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
          colors: [Colors.white, IOT_BG_COLOR],
          begin: const FractionalOffset(-0.8, 0.0),
          end: const FractionalOffset(0.1, 0.5),
          stops: [0.0, 2.0],
          tileMode: TileMode.clamp),
    );
  }

  Widget _buildTitle() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image.asset(
        IOT_IMAGE,
        height: 0.20.sh,
      ),
      Divider(),
      Text(IOT_DESCRIPTION,
          style: TextStyle(
            fontSize: 45.sp,
            fontWeight: FontWeight.bold,
            color: IOT_FG_COLOR,
          ))
    ]);
  }

  Widget _signInGoogleButton() {
    return Container(
      constraints: BoxConstraints(minHeight: 50, maxWidth: 350),
      color: Colors.white,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Image.asset(
          LOGIN_WITH_GOOGLE_ICON,
          height: 30,
          width: 30,
        ),
        TextButton(
          onPressed: () => _loginIotViewModel.loginIot('GOOGLE'),
          child: const FittedBox(
            fit: BoxFit.contain,
            child: Text(
              LOGIN_WITH_GOOGLE_TITLE,
              textScaleFactor: 1.5,
              style: TextStyle(color: IOT_BG_COLOR),
            ),
          ),
        )
      ]),
    );
  }

  Widget _signInWithAppleButton() {
    return Container(
      constraints: const BoxConstraints(minHeight: 50, maxWidth: 350),
      color: Colors.white,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Image.asset(
          LOGIN_WITH_APPLE_ICON,
          height: 30,
          width: 30,
        ),
        TextButton(
          onPressed: () => _loginIotViewModel.loginIot('APPLE'),
          child: const FittedBox(
            fit: BoxFit.contain,
            child: Text(
              LOGIN_WITH_APPLE_TITLE,
              textScaleFactor: 1.5,
              style: TextStyle(color: IOT_BG_COLOR),
            ),
          ),
        )
      ]),
    );
  }

  Widget _showFailLoginMessage(bool isVendor, bool isFail) {
    if (isVendor)
      return ElevatedButton(
          child: Text(
            'NÂNG CẤP PHIÊN BẢN MỚI',
            softWrap: true,
            style: TextStyle(fontSize: 48.sp, color: IOT_FG_COLOR),
          ),
          onPressed: () async {
            if (await canLaunch(IOT_UPGRADE_APP_URL)) {
              await launch(IOT_UPGRADE_APP_URL);
            } else
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không nâng cấp được IOT !!')));
          });
    if (isFail)
      return Padding(
        child: Text('LỖI XÁC THỰC',
            style: TextStyle(
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            )),
        padding: EdgeInsets.only(top: 10),
      );
    return SizedBox();
  }

  Widget _bottomNavBar() {
    return Container(
        constraints: const BoxConstraints(maxHeight: 40, minHeight: 20),
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.only(right: 15, bottom: 5),
        color: IOT_BG_COLOR,
        child: Text(IOT_AUTHOR,
            style: TextStyle(color: Colors.white, fontSize: 30.sp)));
  }
}
