import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/im/compose/position_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ignore: must_be_immutable
class IotShortNameCircular extends StatelessWidget {
  final String type;
  final String creatorName;
  double? heightCircular;
  double? weightCircular;
  double? fontSizeCircular;
  String? groupId;
  int? countMembers;

  IotShortNameCircular(
      {required this.type,
      required this.creatorName,
      this.heightCircular,
      this.weightCircular,
      this.fontSizeCircular,
      this.groupId,
      this.countMembers});

  @override
  Widget build(BuildContext context) {
    if (type == 'P') return _person();
    return _group(context);
  }

  Widget _person() {
    var _names = creatorName.split(' ');
    var _shortName = '';
    for (var i = 0; i < _names.length; i++) {
      if (i == _names.length - 1)
        _shortName += ' ' + _names[i];
      else
        _shortName += _names[i].substring(0, 1);
    }
    var _splitNames = _shortName.split(' ');
    return Container(
        height: (heightCircular ?? 0.06).sh,
        width: (weightCircular ?? 0.06).sh,
        decoration: BoxDecoration(shape: BoxShape.circle, color: IOT_BG_COLOR),
        child: Padding(
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: Container(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                  child: Text(_splitNames[0],
                      textAlign: TextAlign.center,
                      style: TextStyle(color: IOT_BG_COLOR, fontSize: (fontSizeCircular ?? 24).sp)),
                  fit: FlexFit.loose),
              Flexible(
                child: Text(
                  _splitNames[1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: IOT_BG_COLOR,
                      fontSize: ((fontSizeCircular ?? 24) + 2).sp,
                      fontWeight: FontWeight.bold),
                ),
                fit: FlexFit.loose,
              ),
              const SizedBox(
                height: 4,
              )
            ])),
            alignment: Alignment.center,
          ),
          padding: const EdgeInsets.all(4),
        ));
  }

  Widget _group(BuildContext context) {
    var _splitNames = creatorName.split(' ');
    return GestureDetector(
        child: Container(
            height: (heightCircular ?? 0.06).sh,
            width: (weightCircular ?? 0.06).sh,
            decoration: BoxDecoration(shape: BoxShape.circle, color: IOT_BG_COLOR),
            child: Padding(
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: IOT_FG_COLOR),
                child: Container(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Flexible(
                      child: Text(_splitNames[0],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: IOT_BG_COLOR.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 38.sp,
                          )),
                      fit: FlexFit.loose),
                  _splitNames.length == 1
                      ? SizedBox()
                      : Flexible(
                          child: Text(
                            _splitNames[1],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: IOT_BG_COLOR.withValues(alpha: 0.5),
                                fontSize: 38.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          fit: FlexFit.loose,
                        )
                ])),
                alignment: Alignment.center,
              ),
              padding: const EdgeInsets.all(4),
            )),
        onTap: () async {
          if (groupId != null) await _groupMembers(context);
        });
  }

  Future<void> _groupMembers(context) async {
    await showDialog(
        context: context,
        useSafeArea: true,
        builder: (context) {
          return SimpleDialog(
              shape: Border.all(color: IOT_BG_COLOR),
              titlePadding: EdgeInsets.zero,
              title: Container(
                child: Text(
                  'Có $countMembers thành viên',
                  style: TextStyle(
                      color: IOT_FG_COLOR,
                      fontSize: SP_COMMON_FONT_SIZE.sp,
                      fontWeight: FontWeight.bold),
                  softWrap: true,
                ),
                padding: const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(color: IOT_BG_COLOR, border: Border.all(color: Colors.white)),
              ),
              contentPadding: EdgeInsets.zero,
              children: [
                FutureBuilder<List<String>>(
                    future: IotPositionStream().fetchGroupMembers(groupId ?? ''),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        List<String> data = snapshot.data as List<String>;
                        return Container(
                          constraints: BoxConstraints(
                              minHeight: 0.3.sh,
                              minWidth: 0.8.sw,
                              maxHeight: 0.6.sh,
                              maxWidth: 0.8.sw),
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                return Container(
                                    decoration: const BoxDecoration(
                                        border: Border(
                                      bottom: BorderSide(color: Colors.black12),
                                    )),
                                    child: Row(children: [
                                      Padding(
                                        child: _personOfGroupMembers(data[index]),
                                        padding: const EdgeInsets.all(5),
                                      ),
                                      Flexible(
                                        child: Text(
                                          data[index],
                                          style: TextStyle(
                                            fontSize: SP_COMMON_FONT_SIZE.sp,
                                          ),
                                        ),
                                        fit: FlexFit.loose,
                                      )
                                    ]));
                              }),
                        );
                      }
                      if (snapshot.hasError)
                        return IotExceptionPage(exception: snapshot.error);
                      else {
                        return IotCircularProgressWidget();
                      }
                    })
              ]);
        });
  }

  Widget _personOfGroupMembers(String fullName) {
    var _names = fullName.split(' ');
    var _shortName = '';
    for (var i = 0; i < _names.length; i++) {
      if (i == _names.length - 1)
        _shortName += ' ' + _names[i];
      else
        _shortName += _names[i].substring(0, 1);
    }
    var _splitNames = _shortName.split(' ');
    return Container(
        height: 0.056.sh,
        width: 0.056.sh,
        decoration: BoxDecoration(shape: BoxShape.circle, color: IOT_BG_COLOR),
        child: Padding(
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: Container(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                  child: Text(_splitNames[0],
                      textAlign: TextAlign.center,
                      style: TextStyle(color: IOT_BG_COLOR, fontSize: 24.sp)),
                  fit: FlexFit.loose),
              Flexible(
                child: Text(
                  _splitNames[1],
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: IOT_BG_COLOR, fontSize: 24.sp, fontWeight: FontWeight.bold),
                ),
                fit: FlexFit.loose,
              )
            ])),
            alignment: Alignment.center,
          ),
          padding: const EdgeInsets.all(4),
        ));
  }
}
