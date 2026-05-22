import 'package:dngmsp/app/model/report/iot_list_report.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/view/report/manual_report/manual_report_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/report/manual_report/list_manual_report_stream.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotListManualReportsPage extends StatefulWidget {
  final String type;
  final String title;
  IotListManualReportsPage({required this.type, required this.title});

  @override
  _IotListManualReportsPageState createState() =>
      _IotListManualReportsPageState();
}

class _IotListManualReportsPageState extends State<IotListManualReportsPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, true, widget.title),
        body: _buildBodyPage(),
        backgroundColor: const Color(0xFFF4F8F5),
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, true),
    );
  }

  Widget _buildBodyPage() {
    return FutureBuilder<List<IotListReport>>(
      future: IotListManualReportStream().fetchIotListReports(widget.type),
      builder: (context, snapshot) {
        if (snapshot.hasData)
          return _buildListView(snapshot.data as List<IotListReport>);
        else if (snapshot.hasError)
          return IotExceptionPage(exception: snapshot.error);
        else
          return IotCircularProgressWidget();
      },
    );
  }

  Widget _buildListView(List<IotListReport> data) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: IOT_BG_COLOR.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: IOT_BG_COLOR,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${data[index].title} ",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: SP_COMMON_FONT_SIZE.sp,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => IotManualReportPage(
                      reportCode: data[index].code,
                      reportTitle: data[index].title,
                      reportNote: data[index].note,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
