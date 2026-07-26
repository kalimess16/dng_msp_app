import 'dart:io';

import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/resource/string/login_strings.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/viewmodel/account/account_stream.dart';
import 'package:dngmsp/app/viewmodel/update/app_update_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _loginGradientTop = Color(0xFFC9DFD0);
const _loginGradientMid = Color(0xFF79B98A);
const _loginGradientBottom = Color(0xFF23884D);
const _loginSurfaceColor = Color(0xFFEDF5F0);
const _loginSurfaceBorderColor = Color(0xFFD4E5DA);
const _loginButtonColor = Color(0xFFEAF3EE);
const _loginButtonBorderColor = Color(0xFFB7D4C1);
const _loginTextColor = Color(0xFF064829);
const _loginMutedTextColor = Color(0xFF587465);
const _loginAccentColor = Color(0xFF8FBF35);
const _loginWarningBgColor = Color(0xFFFFF7E4);
const _loginWarningBorderColor = Color(0xFFE5C76A);
const _loginWarningTextColor = Color(0xFF7A4A00);

class IotLoginPage extends StatefulWidget {
  @override
  _IotLoginPageState createState() => _IotLoginPageState();
}

class _IotLoginPageState extends State<IotLoginPage> {
  final _loginIotViewModel = IotAccountStream();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkIotAppUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemTextScale = MediaQuery.textScalerOf(context).scale(1);
    final textScale = systemTextScale > 1.25 ? 1.25 : systemTextScale;

    return IotPopScope(
      child: MediaQuery(
        data: mediaQuery.copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: _loginGradientBottom,
          body: StreamBuilder(
            stream: _loginIotViewModel.loginIotStream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              final loginStatus = snapshot.data;
              if (loginStatus == LOGIN_SUCCESS_KEY) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    IotRoutes.HOME_PAGE,
                    (route) => false,
                  );
                });
              }

              return SizedBox.expand(
                child: Container(
                  decoration: _buildBoxDecoration(),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final minContentHeight = (constraints.maxHeight - 96)
                            .clamp(0.0, double.infinity)
                            .toDouble();

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                28,
                                20,
                                72,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: minContentHeight,
                                ),
                                child: Center(
                                  child: _buildLoginCard(
                                    isWaiting: loginStatus == LOGIN_AUTH_KEY,
                                    loginStatus: loginStatus,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 15,
                              right: 15,
                              bottom: 8,
                              child: _buildFooter(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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

  BoxDecoration _buildBoxDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [_loginGradientTop, _loginGradientMid, _loginGradientBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.54, 1.0],
        tileMode: TileMode.clamp,
      ),
    );
  }

  Widget _buildLoginCard({
    required bool isWaiting,
    required String? loginStatus,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: _loginSurfaceColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _loginSurfaceBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: 28),
          isWaiting ? _buildWaitingState() : _signInGroupButton(),
          _showLoginMessage(loginStatus),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: Image.asset(
            IOT_IMAGE,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            IOT_APP_NAME,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _loginTextColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            IOT_DESCRIPTION,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _loginMutedTextColor,
            ),
          ),
        ),
        Container(
          width: 46,
          height: 3,
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            color: _loginAccentColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _loginButtonColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _loginButtonBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: IOT_BG_COLOR,
              strokeWidth: 2.6,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Đang xác thực...',
                maxLines: 1,
                style: const TextStyle(
                  color: _loginTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signInGroupButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _signInGoogleButton(),
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          _signInWithAppleButton(),
        ],
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _loginButtonColor,
            foregroundColor: _loginTextColor,
            elevation: 0,
            side: const BorderSide(color: _loginButtonBorderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(iconPath, height: 26, width: 26),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: const TextStyle(
                        color: _loginTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _showLoginMessage(String? loginStatus) {
    switch (loginStatus) {
      case LOGIN_VENDOR:
        return _buildUpgradeMessage();
      case LOGIN_NETWORK_ERROR_KEY:
        return _buildStatusMessage(
          icon: Icons.wifi_off_outlined,
          title: 'Không kết nối được',
          message: 'Kiểm tra mạng, Google Play Services hoặc server IOT.',
        );
      case LOGIN_FIREBASE_ERROR_KEY:
        return _buildStatusMessage(
          icon: Icons.gpp_bad_outlined,
          title: 'Firebase chưa xác thực được',
          message: 'Kiểm tra Google provider, SHA và google-services.json.',
        );
      case LOGIN_BACKEND_ERROR_KEY:
        return _buildStatusMessage(
          icon: Icons.person_off_outlined,
          title: 'Server IOT từ chối đăng nhập',
          message: 'Firebase đã xác thực, nhưng tài khoản chưa được cấp quyền.',
        );
      case LOGIN_TOKEN_SAVE_ERROR_KEY:
        return _buildStatusMessage(
          icon: Icons.save_outlined,
          title: 'Không lưu được phiên đăng nhập',
          message: 'Thử đăng nhập lại hoặc xóa dữ liệu ứng dụng.',
        );
      case LOGIN_FAIL_KEY:
        return _buildStatusMessage(
          icon: Icons.error_outline,
          title: 'Không đăng nhập được',
          message: 'Chọn đúng tài khoản Google đã được cấp quyền.',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _loginWarningBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _loginWarningBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _loginWarningTextColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: const TextStyle(
                    color: _loginWarningTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  softWrap: true,
                  style: const TextStyle(
                    color: _loginWarningTextColor,
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _loginWarningBgColor,
              foregroundColor: _loginWarningTextColor,
              elevation: 0,
              side: const BorderSide(color: _loginWarningBorderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Nâng cấp phiên bản mới',
                  maxLines: 1,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            onPressed: () async {
              final url = Uri.parse(
                Platform.isIOS ? IOT_APP_STORE_URL : IOT_UPGRADE_APP_URL,
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không nâng cấp được IOT')),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          IOT_AUTHOR,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
