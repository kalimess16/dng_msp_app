import 'dart:async';

import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotNoteReportPage extends StatefulWidget {
  late final String reportNote;
  IotNoteReportPage({required this.reportNote});
  _IotNoteReportPageState createState() => _IotNoteReportPageState();
}

class _IotNoteReportPageState extends State<IotNoteReportPage> {
  double _opacityLevel = 1.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        Duration(seconds: 30), (Timer t) => _changeOpacity(false));
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  void _changeOpacity(bool isStopped) {
    setState(() {
      if (isStopped) {
        _opacityLevel = 0;
        _timer.cancel();
      } else
        _opacityLevel = _opacityLevel == 0 ? 1.0 : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        child: Align(
            alignment: Alignment.bottomRight,
            child: AnimatedOpacity(
                opacity: _opacityLevel,
                duration: const Duration(seconds: 5),
                child: Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.reportNote,
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 36.sp),
                        ),
                        flex: 1,
                      ),
                      ElevatedButton(
                        child: const Text('Ẩn'),
                        onPressed: () => _changeOpacity(true),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(left: 4, right: 5),
                  decoration: const BoxDecoration(color: IOT_BG_COLOR),
                  constraints: BoxConstraints(
                      maxHeight: 0.10.sh, minWidth: double.infinity),
                ))));
  }
}
