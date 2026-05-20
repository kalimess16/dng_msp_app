import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotAppBar {

  AppBar build(BuildContext context, bool backHomePage, String title) {
    return AppBar(
      leading: BackButton(
          color: Colors.white,
          onPressed: () => backIotPages(context, backHomePage)),
      centerTitle: true,
      title: FittedBox(
          fit: BoxFit.contain,
          child: Text(title,
              style: TextStyle(
                  color: IOT_FG_COLOR,
                  fontWeight: FontWeight.bold,
                  fontSize: SP_COMMON_FONT_SIZE.sp)))
    );
  }

  Future<bool> backIotPages(BuildContext context, bool backHomePage) async {
    if (backHomePage)
      Navigator.popUntil(context, ModalRoute.withName(IotRoutes.HOME_PAGE));
    else
      Navigator.of(context).pop();
    return true;
  }
}
