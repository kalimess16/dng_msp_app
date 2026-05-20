import 'package:dngmsp/app/view/report/content_report_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/view/widget/note_report_widget.dart';
import 'package:dngmsp/app/viewmodel/report/manual_report/detail_manual_report_stream.dart';
import 'package:flutter/material.dart';

class IotDetailManualReportPage extends StatelessWidget {
  final String? messageType;
  final String? code;
  final String? type;
  final String? date;
  final String? title;
  final String? note;
  final Map<String, dynamic>? mapSpecReportParameters;

  IotDetailManualReportPage({
    this.messageType, this.code, this.type, this.date, this.title, this.note, this.mapSpecReportParameters});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: IotAppBar().build(context, false, this.title?? ''),
          body: _buildReportsBodyPage(context),
          bottomNavigationBar: IotBottomNavigatorBar(),
        ),
        onWillPop: () => IotAppBar().backIotPages(context, false));
  }

  Widget _buildReportsBodyPage(BuildContext context) {
    return FutureBuilder<IotDetailManualReportStream>(
        future: IotDetailManualReportStream(
            reportType: type!,
            mapSpecReportParameters: mapSpecReportParameters!)
            .fetchIotDetailReports(context),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Stack(children: [
              IotContentReportPage().buildLazyTable(context, snapshot.data),
              (note != null && note!.length > 0
                  ? IotNoteReportPage(reportNote: note!)
                  : Text(""))
            ]);
          } else if (snapshot.hasError) {
            return IotExceptionPage(exception: snapshot.error);
          } else
            return IotCircularProgressWidget();
        });
  }

}
