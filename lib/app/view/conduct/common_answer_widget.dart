import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/view/conduct/common_conduct_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonConductAnswerWidget extends StatefulWidget {
  final String answer;
  final int num;
  CommonConductAnswerWidget({Key? key, required this.answer, required this.num});

  @override
  State<CommonConductAnswerWidget> createState() => _CommonConductAnswerWidgetState();
}

class _CommonConductAnswerWidgetState extends State<CommonConductAnswerWidget> {
  bool _isTap = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 15, left: 6, right: 6),
        width: double.infinity,
        child: Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.num == 1 ? 'A' : (widget.num == 2 ? 'B' : (widget.num == 3 ? 'C' : 'D'))}. ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 64.sp,
                    color: Colors.orange,
                  )),
              TextSpan(
                  text: '${widget.answer}',
                  style: TextStyle(
                      fontSize: SP_COMMON_FONT_SIZE.sp,
                      color: (_isTap ? Colors.red : Colors.black))),
            ],
          ),
        ),
        decoration: BoxDecoration(
            color: Colors.black12, border: Border.all(color: IOT_BG_COLOR)),
      ),
      onTap: () {
        if (CommonConductPage.numberAnswer == -1)
          setState(() {
            _isTap = true;
            CommonConductPage.numberAnswer = widget.num;
          });
      },
    );
  }
}
