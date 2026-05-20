import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class IotExceptionPage extends StatelessWidget {
  final dynamic exception;
  final bool? isBackHome;
  IotExceptionPage({required this.exception, this.isBackHome});

  @override
  Widget build(BuildContext context) {
    if (exception is IotException) {
      IotException error = exception;
      switch (error.code) {
        case -2:
          return _exceptionWidget(
              context, 'KHÔNG CÓ SỐ LIỆU', Icons.info_outline, Colors.blueGrey);
        case 403:
          return _unAuthorizationException(context, error.error);
        case 408:
          return _exceptionWidget(context, 'KẾT NỐI KHÔNG ỔN ĐỊNH',
              Icons.access_time_filled, Colors.orange);
        case -1:
        case 101:
          return _exceptionWidget(context, 'KHÔNG KẾT NỐI ĐƯỢC MÁY CHỦ',
              Icons.network_check, Colors.red);
      }
    }
    return _exceptionWidget(
        context, 'LỖI PHÁT SINH', Icons.error_outline, Colors.red);
  }

  Widget _unAuthorizationException(BuildContext context, String? isUpgrade) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (isUpgrade ?? 'N') == 'N'
                ? Text(
                    'TÀI KHOẢN CỦA BẠN ĐÃ ĐƯỢC ĐĂNG NHẬP VÀO THIẾT BỊ KHÁC. IOT SẼ NGỪNG HOẠT ĐỘNG TRÊN THIẾT BỊ NÀY.',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: SP_COMMON_FONT_SIZE.sp,
                        fontWeight: FontWeight.bold),
                  )
                : Text(
                    'IOT CẦN ĐƯỢC CẬP NHẬT PHIÊN BẢN MỚI NHẤT.',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: SP_COMMON_FONT_SIZE.sp,
                        fontWeight: FontWeight.bold),
                  ),
            (isUpgrade ?? 'N') == 'N'
                ? Container(
                    width: double.infinity,
                    child: ElevatedButton(
                        child: Text(
                          'ĐĂNG NHẬP LẠI',
                          style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                        ),
                        onPressed: () {
                          IotSharedPreferences().clear();
                          Navigator.pushNamedAndRemoveUntil(
                              context, IotRoutes.LOGIN_PAGE, (route) => false);
                        }))
                : Container(
                    width: double.infinity,
                    child: ElevatedButton(
                        child: Text(
                          'CẬP NHẬT',
                          style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                        ),
                        onPressed: () async {
                          IotSharedPreferences().clear();
                          if (await canLaunch(IOT_UPGRADE_APP_URL)) {
                            await launch(IOT_UPGRADE_APP_URL);
                          } else
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Không nâng cấp được IOT !!')));
                        }),
                  )
          ]),
    );
  }

  Widget _exceptionWidget(
      BuildContext context, String errorMessage, IconData icons, Color color) {
    return Container(
        padding: EdgeInsets.all(20),
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icons,
                size: 36,
                color: color,
              ),
              Flexible(
                child: Padding(
                  child: Text(
                    errorMessage,
                    softWrap: true,
                    style: TextStyle(
                        fontSize: SP_COMMON_FONT_SIZE.sp, color: color),
                  ),
                  padding: const EdgeInsets.only(left: 10, right: 10),
                ),
                fit: FlexFit.loose,
              ),
              OutlinedButton(
                  child: Text(
                    'Đóng',
                    style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                  ),
                  onPressed: () {
                    if (isBackHome ?? false)
                      Navigator.popUntil(
                          context, ModalRoute.withName(IotRoutes.HOME_PAGE));
                    else
                      Navigator.of(context).pop();
                  }),
            ]));
  }
}
