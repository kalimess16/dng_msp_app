import 'package:dngmsp/app/model/report/iot_list_report.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/view/report/manual_report/manual_report_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/report/manual_report/list_manual_report_stream.dart';

import 'package:flutter/material.dart';

class IotListManualReportsPage extends StatefulWidget {
  final String type;
  final String title;
  IotListManualReportsPage({required this.type, required this.title});

  @override
  _IotListManualReportsPageState createState() =>
      _IotListManualReportsPageState();
}

class _IotListManualReportsPageState extends State<IotListManualReportsPage> {
  late final Future<List<IotListReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = IotListManualReportStream().fetchIotListReports(
      widget.type,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IotPopScope(
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
      future: _reportsFuture,
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
    final metrics = IotManualReportMenuMetrics.fromViewport(
      MediaQuery.sizeOf(context),
    );

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, metrics.listTopPadding, 12, 20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: metrics.itemSpacing),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: metrics.verticalPadding,
                ),
                child: Row(
                  children: [
                    Container(
                      width: metrics.iconExtent,
                      height: metrics.iconExtent,
                      decoration: BoxDecoration(
                        color: IOT_BG_COLOR.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: IOT_BG_COLOR,
                        size: metrics.iconSize,
                      ),
                    ),
                    SizedBox(width: metrics.contentSpacing),
                    Expanded(
                      child: Text(
                        "${data[index].title} ",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: metrics.fontSize,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black38,
                      size: metrics.chevronSize,
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

@visibleForTesting
class IotManualReportMenuMetrics {
  final double fontSize;
  final double listTopPadding;
  final double itemSpacing;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconExtent;
  final double iconSize;
  final double contentSpacing;
  final double chevronSize;

  const IotManualReportMenuMetrics({
    required this.fontSize,
    required this.listTopPadding,
    required this.itemSpacing,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconExtent,
    required this.iconSize,
    required this.contentSpacing,
    required this.chevronSize,
  });

  factory IotManualReportMenuMetrics.fromViewport(Size viewport) {
    final isLandscape = viewport.width > viewport.height;
    final maxFontSize = isLandscape ? 16.0 : 18.0;
    final fontSize = (viewport.shortestSide * 0.04)
        .clamp(14.0, maxFontSize)
        .toDouble();

    return IotManualReportMenuMetrics(
      fontSize: fontSize,
      listTopPadding: isLandscape ? 8 : 12,
      itemSpacing: isLandscape ? 8 : 10,
      horizontalPadding: isLandscape ? 12 : 14,
      verticalPadding: isLandscape ? 8 : 14,
      iconExtent: isLandscape ? 36 : 42,
      iconSize: isLandscape ? 22 : 24,
      contentSpacing: isLandscape ? 10 : 12,
      chevronSize: isLandscape ? 22 : 24,
    );
  }
}
