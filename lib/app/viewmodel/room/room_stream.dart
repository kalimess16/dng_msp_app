
import 'package:dngmsp/app/model/report/data_report.dart';
import 'package:dngmsp/app/service/room/room_service.dart';

class IotServerRoomStream {
  Future<List<IotDataReport>> fetchIotServerRoom() async {
    return await IotServerRoomService().fetchIotServerRoom();
  }
}