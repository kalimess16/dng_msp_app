import 'package:dngmsp/app/model/im/position.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/viewmodel/im/compose/position_stream.dart';
import 'list_postions_page.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotPositionButton extends StatelessWidget {
  final IotPositionStream positionStream;

  IotPositionButton(this.positionStream);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: positionStream.positionStream,
        builder: (BuildContext context, AsyncSnapshot<List<IotPosition>> snapshot) {
          if (snapshot.data == null) return _buildPositionButton(context);
          var _positions = (snapshot.data as List<IotPosition>)
              .where((element) => element.selected ?? false)
              .toList();
          if (_positions.isEmpty) return _buildPositionButton(context);
          String _names = _positions[0].name;
          if (_positions.length >= 2)
            _names = _names + ' + ' + '${_positions.length - 1} người ...';
          return Container(
              height: 0.12.sh,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 10, top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gửi đến ",
                    style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                  ),
                  Flexible(
                      child: Center(
                        child: TextButton(
                            child: Text(
                              _names,
                              style: TextStyle(
                                  fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
                                  fontWeight: FontWeight.bold,
                                  color: IOT_BG_COLOR),
                            ),
                            onPressed: () async => await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        IotListPositionsPage(positionStream)))),
                      ),
                      fit: FlexFit.loose)
                ],
              ));
        });
  }

  Widget _buildPositionButton(context) {
    return Row(children: [
      Expanded(child: SizedBox()),
      TextButton(
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            const Icon(
              Icons.group,
              size: 32,
              color: IOT_BG_COLOR,
            ),
            Text(
              "Người nhận",
              style: TextStyle(
                  color: IOT_BG_COLOR,
                  fontSize: SP_COMMON_FONT_SIZE.sp,
                  fontWeight: FontWeight.bold),
            ),
          ]),
          onPressed: () async {
            if (positionStream.positions.isEmpty)
              await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return SimpleDialog(
                        contentPadding: EdgeInsets.zero,
                        titlePadding: EdgeInsets.zero,
                        children: [
                          FutureBuilder<List<IotPosition>>(
                              future: positionStream.initPositions(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) Navigator.of(context).pop();
                                if (snapshot.hasError)
                                  return IotExceptionPage(exception: snapshot.error);
                                else
                                  return Container(
                                      child: IotCircularProgressWidget(),
                                      width: 120,
                                      height: 120,
                                      color: Colors.black26);
                              })
                        ]);
                  });
            if (positionStream.positions.isNotEmpty)
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => IotListPositionsPage(positionStream)));
          })
    ]);
  }
}
