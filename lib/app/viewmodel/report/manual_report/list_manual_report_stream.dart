import 'package:dngmsp/app/model/report/iot_list_report.dart';
import 'package:dngmsp/app/service/report/manual_report/list_manual_report_service.dart';

class IotListManualReportStream {
  Future<List<IotListReport>> fetchIotListReports(String type) async {
    return await IotListManualReportService().fetchIotListReports(type);
  }
}