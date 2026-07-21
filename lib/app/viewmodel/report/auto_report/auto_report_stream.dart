import 'package:dngmsp/app/service/report/auto_report/auto_report_service.dart';
import 'package:dngmsp/app/viewmodel/report/detail_content_report_stream.dart';

class IotAutoReportStream extends IotDetailContentReportsStream {
  final String reportType;
  final String reportDate;
  final int reportCode;

  IotAutoReportStream({
    required this.reportType,
    required this.reportDate,
    required this.reportCode,
  });

  Future<IotAutoReportStream> fetchIotMessages() async {
    return await IotAutoReportService()
        .fetchIotReports(reportType, reportDate, reportCode)
        .then((detailReports) {
          makeDataReport(detailReports);
          return this;
        });
  }
}
