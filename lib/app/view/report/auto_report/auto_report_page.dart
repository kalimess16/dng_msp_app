import 'package:dngmsp/app/view/report/content_report_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/auto_report_stream.dart';
import 'package:flutter/material.dart';

class IotAutoReportPage extends StatelessWidget {
  final int code;
  final String type;
  final String date;
  final String? title;

  IotAutoReportPage(
      {required this.code, required this.type, required this.date, this.title});

  @override
  Widget build(BuildContext context) {
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 1;
    return IotPopScope(
        child: Scaffold(
            appBar: IotAppBar().build(context, false, title ?? 'BẢNG SỐ LIỆU'),
            body: _buildMessages(context),
            bottomNavigationBar: IotBottomNavigatorBar()),
        onWillPop: () => IotAppBar().backIotPages(context, false));
  }

  Widget _buildMessages(BuildContext context) {
    return FutureBuilder<IotAutoReportStream>(
        future: IotAutoReportStream(
                reportType: type, reportDate: date, reportCode: code)
            .fetchIotMessages(context),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return IotContentReportPage()
                .buildLazyTable(context, snapshot.data);
          else if (snapshot.hasError)
            return IotExceptionPage(exception: snapshot.error);
          else
            return IotCircularProgressWidget();
        });
  }
}
