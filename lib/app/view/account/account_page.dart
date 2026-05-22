import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/account/account_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, true, 'TÀI KHOẢN ĐĂNG NHẬP'),
        backgroundColor: const Color(0xFFF4F8F5),
        body: FutureBuilder(
          future: IotSharedPreferences().get(),
          builder: ((context, snapshot) {
            if (snapshot.hasData) {
              List<String> prefs = snapshot.data as List<String>;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: IOT_BG_COLOR.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: IOT_BG_COLOR,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    prefs[1],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: IOT_BG_COLOR,
                      fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _accountTile('Tài khoản', prefs[2]),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: SP_COMMON_FONT_SIZE.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async => await _logout(context),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError)
              return IotExceptionPage(exception: snapshot.error);
            return IotCircularProgressWidget();
          }),
        ),
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, true),
    );
  }

  Widget _accountTile(String label, String value) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.black54,
                fontSize: SP_SMALL_COMMON_FONT_SIZE.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    bool _status = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          child: SimpleDialog(
            contentPadding: EdgeInsets.zero,
            titlePadding: EdgeInsets.zero,
            children: [
              FutureBuilder<bool>(
                future: IotAccountStream().logout(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Navigator.of(context).pop();
                    _status = snapshot.data as bool;
                  } else if (snapshot.hasError)
                    return IotExceptionPage(exception: snapshot.error);

                  return Container(
                    child: IotCircularProgressWidget(),
                    width: 120,
                    height: 120,
                    color: Colors.black12,
                  );
                },
              ),
            ],
          ),
          onWillPop: () async => false,
        );
      },
    );

    if (_status) {
      IotSharedPreferences().clear();
      Navigator.pushNamedAndRemoveUntil(
        context,
        IotRoutes.LOGIN_PAGE,
        (route) => false,
      );
    }
  }
}
