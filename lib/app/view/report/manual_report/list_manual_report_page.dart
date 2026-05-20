import 'package:dngmsp/app/model/report/iot_list_report.dart';
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
  _IotListManualReportsPageState createState() => _IotListManualReportsPageState();
}

class _IotListManualReportsPageState extends State<IotListManualReportsPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: IotAppBar().build(context, true, widget.title),
          body: _buildBodyPage(),
          bottomNavigationBar: IotBottomNavigatorBar(),
        ),
        onWillPop: () => IotAppBar().backIotPages(context, true));
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
        });
  }

  Widget _buildListView(List<IotListReport> data) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          return InkWell(
            child: Container(
              constraints: BoxConstraints(minHeight: 0.067.sh, maxHeight: 0.12.sh),
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(children: [
                Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      "${data[index].title} ",
                      style: TextStyle(
                        fontSize: SP_COMMON_FONT_SIZE.sp,
                      ),
                    ))
              ]),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12))),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => IotManualReportPage(
                            reportCode: data[index].code,
                            reportTitle: data[index].title,
                            reportNote: data[index].note,
                          )));
            },
          );
        });
  }
}
