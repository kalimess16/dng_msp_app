import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotAppBar {
  AppBar build(BuildContext context, bool backHomePage, String title) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: IOT_BG_COLOR,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: Colors.white,
        onPressed: () => backIotPages(context, backHomePage),
      ),
      centerTitle: true,
      titleSpacing: 0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: IOT_FG_COLOR,
            fontWeight: FontWeight.bold,
            fontSize: SP_COMMON_FONT_SIZE.sp,
          ),
        ),
      ),
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
