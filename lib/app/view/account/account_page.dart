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
          body: FutureBuilder(
              future: IotSharedPreferences().get(),
              builder: ((context, snapshot) {
                if (snapshot.hasData) {
                  List<String> prefs = snapshot.data as List<String>;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      child: Center(
                          child: Text(prefs[1],
                              style: TextStyle(
                                  color: IOT_BG_COLOR,
                                  fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                                  fontWeight: FontWeight.bold))),
                      padding: const EdgeInsets.all(20),
                    ),
                    Padding(
                      child: Text('Tài khoản ',
                          style: TextStyle(fontSize: SP_LARGER_COMMON_FONT_SIZE.sp)),
                      padding: const EdgeInsets.all(10),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12)),
                      child: Row(children: [
                        Text(
                          prefs[2],
                          style: TextStyle(
                              fontSize: SP_LARGER_COMMON_FONT_SIZE.sp, fontWeight: FontWeight.bold),
                        )
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
                      height: 70,
                      child: ElevatedButton(
                        child: Text('Đăng xuất',
                            style: TextStyle(
                                fontSize: SP_COMMON_FONT_SIZE.sp, fontWeight: FontWeight.bold)),
                        onPressed: () async => await _logout(context),
                      ),
                      width: double.infinity,
                    )
                  ]);
                }
                if (snapshot.hasError) return IotExceptionPage(exception: snapshot.error);
                return IotCircularProgressWidget();
              })),
          bottomNavigationBar: IotBottomNavigatorBar(),
        ),
        onWillPop: () => IotAppBar().backIotPages(context, true));
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
                        })
                  ]),
              onWillPop: () async => false);
        });

    if (_status) {
      IotSharedPreferences().clear();
      Navigator.pushNamedAndRemoveUntil(
          context, IotRoutes.LOGIN_PAGE, (route) => false);
    }
  }
}
