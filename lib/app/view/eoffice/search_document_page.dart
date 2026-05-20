import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/icon/app_icons.dart';
import 'package:dngmsp/app/view/eoffice/search_eoffice_page.dart';
import 'package:dngmsp/app/view/eoffice/search_mark_eoffice_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchDocumentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, false, 'Tìm văn bản'),
        body: Column(
          children: [
            Container(
                child: Text(
                  'Chọn tìm văn bản ',
                  style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                ),
                margin: EdgeInsets.all(20),
                alignment: Alignment.center),
            InkWell(
                child: Container(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(
                          IotAppIcons.search_doc,
                          color: IOT_BG_COLOR,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Văn bản chung',
                          style: TextStyle(
                              fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                              color: IOT_BG_COLOR),
                        )
                      ],
                    )),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            SearchEofficePage()))),
            InkWell(
                child: Container(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(
                          IotAppIcons.category,
                          color: IOT_BG_COLOR,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Văn bản tự phân loại',
                          style: TextStyle(
                              fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                              color: IOT_BG_COLOR),
                        )
                      ],
                    )),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            SearchMarkEofficePage()))),
          ],
        ),
        backgroundColor: Colors.white,
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, false),
    );
  }
}
