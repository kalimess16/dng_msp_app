import 'dart:async';

import 'package:dngmsp/app/model/im/position.dart';
import 'package:dngmsp/app/service/im/compose/position_service.dart';

class IotPositionStream {
  List<IotPosition> positions = [];

  var _positionController = StreamController<List<IotPosition>>.broadcast();
  Stream<List<IotPosition>> get positionStream => _positionController.stream;
  void dispose() => _positionController.close();

  Future<List<IotPosition>> initPositions() async {
    positions.clear();
    positions.addAll(await IotPositionService().fetchIotPosition('N'));
    positions.insert(0, IotPosition(id: 'ALL', name: 'VBSP Đà Nẵng', countMembers: 0, selected: false));

    return positions;
  }

  Future<List<String>> fetchGroupMembers(String groupId) async {
    return await IotPositionService().fetchGroupMembers(groupId);
  }

  void setSelectedPosition(String id, bool isSelected) {
    //positions[index].selected = isSelected;
    positions.firstWhere((element) => element.id == id).selected = true;
    _positionController.sink.add(positions);
  }

  void unSelectedAllPosition() {
    bool _isExists = false;
    positions.forEach((element) {
      if (element.id == 'ALL') {
        _isExists = true;
        return;
      }
    });
    if (_isExists)
      positions.firstWhere((element) => element.id == 'ALL').selected = false;
    _positionController.sink.add(positions);
  }

  void unSelectedExceptAllPositions() {
    positions.forEach((element) {
      if (element.id != 'ALL')    element.selected = false;
    });
    _positionController.sink.add(positions);
  }

  Future<List<IotPosition>> initSearchingPositions() async {
    positions.clear();
    positions.addAll(await IotPositionService().fetchIotPosition('Y'));
    // delete group
    positions.removeWhere((element) => element.shortName != null);
    return positions;
  }
}
