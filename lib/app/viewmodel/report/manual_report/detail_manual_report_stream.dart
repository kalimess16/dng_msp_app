import 'package:dngmsp/app/service/report/manual_report/detail_manual_report_service.dart';
import 'package:dngmsp/app/viewmodel/report/detail_content_report_stream.dart';
import 'package:flutter/material.dart';

class IotDetailManualReportStream extends IotDetailContentReportsStream {
  final String reportType;
  final Map<String, dynamic> mapSpecReportParameters;

  IotDetailManualReportStream({required this.reportType, required this.mapSpecReportParameters});

  Future<IotDetailManualReportStream> fetchIotDetailReports(
      BuildContext context) async {
    return await IotDetailManualReportService()
        .fetchDetailReport(reportType, mapSpecReportParameters)
        .then((detailReports) {
      makeDataReport(detailReports);
      resizeCustomCellWidth(context);
      return this;
    });
  }

}
