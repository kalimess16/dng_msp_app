import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/icon/app_icons.dart';
import 'package:flutter/material.dart';

class IotCircularProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          IotAppIcons.iot,
          size: 32,
          color: IOT_BG_COLOR,
        ),
        Container(
          child: const CircularProgressIndicator(
            color: IOT_BG_COLOR,
          ),
          width: 70,
          height: 70,
        )
      ],
    ));
  }
}
