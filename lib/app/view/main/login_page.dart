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
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.data != null && snapshot.data == LOGIN_SUCCESS_KEY) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  IotRoutes.HOME_PAGE,
                  (route) => false,
                );
              });
            }

            var _wait =
                (snapshot.data != null && snapshot.data == LOGIN_AUTH_KEY);
            var _fail =
                (snapshot.data != null && snapshot.data == LOGIN_FAIL_KEY);
            var _vendor =
                (snapshot.data != null && snapshot.data == LOGIN_VENDOR);
            return Container(
              width: 1.sw,
              height: 1.sh,
              decoration: _buildBoxDecoration(),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 64,
                        ),
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: IOT_BG_COLOR.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTitle(),
                                const SizedBox(height: 30),
                                (_wait
                                    ? SizedBox(
                                        height: 52,
                                        child: CircularProgressIndicator(
                                          color: IOT_BG_COLOR,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : _signInGroupButton()),
                                _showFailLoginMessage(_vendor, _fail),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _bottomNavBar(),
      ),
      onWillPop: () async => await _onWillIotPop(context),
    );
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _signInGoogleButton(),
        const SizedBox(height: 12),
        (Platform.isIOS ? _signInWithAppleButton() : SizedBox(height: 5)),
      ],
    );
  }

  BoxDecoration _buildBoxDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.white, IOT_BG_COLOR],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 1.0],
        tileMode: TileMode.clamp,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 0.16.sh,
          constraints: const BoxConstraints(maxHeight: 150, maxWidth: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: IOT_BG_COLOR.withValues(alpha: 0.10)),
          ),
          child: Image.asset(IOT_IMAGE, fit: BoxFit.contain),
        ),
        const SizedBox(height: 20),
        Text(
          IOT_DESCRIPTION,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 45.sp,
            fontWeight: FontWeight.bold,
            color: IOT_BG_COLOR,
          ),
        ),
        Container(
          width: 72,
          height: 4,
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            color: IOT_FG_COLOR,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _signInGoogleButton() {
    return _signInButton(
      iconPath: LOGIN_WITH_GOOGLE_ICON,
      title: LOGIN_WITH_GOOGLE_TITLE,
      onPressed: () => _loginIotViewModel.loginIot('GOOGLE'),
    );
  }

  Widget _signInWithAppleButton() {
    return _signInButton(
      iconPath: LOGIN_WITH_APPLE_ICON,
      title: LOGIN_WITH_APPLE_TITLE,
      onPressed: () => _loginIotViewModel.loginIot('APPLE'),
    );
  }

  Widget _signInButton({
    required String iconPath,
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: IOT_BG_COLOR,
          elevation: 0,
          side: BorderSide(color: IOT_BG_COLOR.withValues(alpha: 0.16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 28, width: 28),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: IOT_BG_COLOR,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showFailLoginMessage(bool isVendor, bool isFail) {
    if (isVendor)
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: ElevatedButton(
          child: Text(
            'NÂNG CẤP PHIÊN BẢN MỚI',
            softWrap: true,
            style: TextStyle(fontSize: 48.sp, color: IOT_FG_COLOR),
          ),
          onPressed: () async {
            final url = Uri.parse(IOT_UPGRADE_APP_URL);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Không nâng cấp được IOT !!')),
              );
          },
        ),
      );
    if (isFail)
      return Padding(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
          ),
          child: Text(
            'LỖI XÁC THỰC',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38.sp,
              fontWeight: FontWeight.bold,
              color: IOT_BG_COLOR,
            ),
          ),
        ),
        padding: EdgeInsets.only(top: 18),
      );
    return SizedBox();
  }

  Widget _bottomNavBar() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 42, minHeight: 28),
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.only(right: 15, bottom: 8, top: 8),
      color: IOT_BG_COLOR,
      child: Text(
        IOT_AUTHOR,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 28.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
