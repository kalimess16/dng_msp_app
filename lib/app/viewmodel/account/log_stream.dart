
import 'package:dngmsp/app/model/account/log.dart';
import 'package:dngmsp/app/service/account/log_service.dart';

class IotAccountLogStream {
  Future<List<IotAccountLog>> fetchIotUserLogs() async {
    return await IotAccountLogService().fetchIotUserLogs();
  }
}