import 'package:dngmsp/app/view/report/content_report_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/view/widget/note_report_widget.dart';
import 'package:dngmsp/app/viewmodel/report/manual_report/detail_manual_report_stream.dart';
import 'package:flutter/material.dart';

class IotDetailManualReportPage extends StatefulWidget {
  final String? messageType;
  final String? code;
  final String? type;
  final String? date;
  final String? title;
  final String? note;
  final Map<String, dynamic>? mapSpecReportParameters;

  IotDetailManualReportPage({
    this.messageType,
    this.code,
    this.type,
    this.date,
    this.title,
    this.note,
    this.mapSpecReportParameters,
  });

  @override
  State<IotDetailManualReportPage> createState() =>
      _IotDetailManualReportPageState();
}

class _IotDetailManualReportPageState extends State<IotDetailManualReportPage> {
  late final Future<IotDetailManualReportStream> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = IotDetailManualReportStream(
      reportType: widget.type!,
      mapSpecReportParameters: widget.mapSpecReportParameters!,
    ).fetchIotDetailReports();
  }

  @override
  Widget build(BuildContext context) {
    return IotPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, false, widget.title ?? ''),
        body: _buildReportsBodyPage(),
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, false),
    );
  }

  Widget _buildReportsBodyPage() {
    return FutureBuilder<IotDetailManualReportStream>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Stack(
            children: [
              IotContentReportPage().buildLazyTable(context, snapshot.data!),
              if (widget.note?.isNotEmpty ?? false)
                IotNoteReportPage(reportNote: widget.note!),
            ],
          );
        } else if (snapshot.hasError) {
          return IotExceptionPage(exception: snapshot.error);
        } else {
          return IotCircularProgressWidget();
        }
      },
    );
  }
}
