import 'package:dngmsp/app/model/im/emotion_user.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/service/im/reply/reply_internal_message_service.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/view/widget/short_name_circular_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotEmotionUserPage extends StatelessWidget {
  final int originalId;
  final String originalCreator;
  final int messageId;
  IotEmotionUserPage(
      {required this.originalId, required this.originalCreator, required this.messageId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<IotEmotionUser>>(
        future: IotReplyInternalMessagesService()
            .fetchEmotionUsers(originalId, originalCreator, messageId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<IotEmotionUser> _list = snapshot.data as List<IotEmotionUser>;
            return Container(
              width: 1.sw,
              constraints: BoxConstraints(maxHeight: 0.6.sh),
              decoration: BoxDecoration(border: Border.all(color: Colors.black12, width: 2.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _title(context),
                  Flexible(
                    child: _body(context, _list),
                    fit: FlexFit.loose,
                  )
                ],
              ),
            );
          }
          if (snapshot.hasError)
            return IotExceptionPage(exception: snapshot.error);
          else
            return Container(
              child: IotCircularProgressWidget(),
              width: 120,
              height: 120,
              color: Colors.black12,
            );
        });
  }

  Widget _title(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Cán bộ nhận :',
              style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
            ),
            fit: FlexFit.loose,
          ),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close_outlined))
        ],
      ),
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
          color: IOT_FG_COLOR, border: Border(bottom: BorderSide(color: Colors.black12))),
      width: double.infinity,
    );
  }

  Widget _body(context, List<IotEmotionUser> _list) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: _list.length,
        itemBuilder: (context, index) {
          return Row(
            children: [
              Padding(
                  padding: const EdgeInsets.only(right: 10, top: 5, bottom: 3, left: 10),
                  child: IotShortNameCircular(
                    type: 'P',
                    creatorName: _list[index].name,
                    heightCircular: 0.055,
                    weightCircular: 0.055,
                    fontSizeCircular: 22,
                  )),
              Flexible(
                child: Container(
                  child: _list[index].isCreator == 'Y'
                      ? Text('Đã gửi',
                          style: TextStyle(
                              fontSize: SP_COMMON_FONT_SIZE.sp, fontWeight: FontWeight.bold))
                      : Text(
                          _list[index].description,
                          style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                        ),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12))),
                ),
                fit: FlexFit.loose,
              ),
            ],
          );
        });
  }
}
