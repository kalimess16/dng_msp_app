import 'package:dngmsp/app/resource/icon/app_icons.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IotConfirmButton extends StatefulWidget {
  final int originalId;
  final String originalCreator;
  final int messageId;
  final int emotion;
  final bool isIncoming;
  IotConfirmButton(
      {required this.originalId,
      required this.originalCreator,
      required this.messageId,
      required this.emotion,
      required this.isIncoming});
  @override
  _IotConfirmButtonState createState() => _IotConfirmButtonState();
}

class _IotConfirmButtonState extends State<IotConfirmButton> {
  bool isPressed = false;
  int _emotion = -1;

  @override
  void initState() {
    super.initState();
    isPressed = (widget.emotion > 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isIncoming)
      isPressed = (widget.emotion > 0) || (widget.emotion == 0 && _emotion == 0);
    return Padding(
        child: (!isPressed
            ? GestureDetector(
                onTap: () async {
                  context
                      .read<IotReplyInternalMessageStream>()
                      .updateEmotionNumInternalMessage(
                          widget.originalId, widget.originalCreator, widget.messageId)
                      .then((value) {
                    setState(() {
                      isPressed = (value > 0);
                      _emotion = widget.messageId;
                    });
                  });
                },
                child: Column(children: [
                  const Icon(
                    IotAppIcons.confirm,
                    color: Colors.black12,
                    size: 20,
                  ),
                  const Text(
                    'Xác nhận',
                    style: TextStyle(fontSize: 12),
                  )
                ]))
            : Column(children: [
                const Icon(
                  IotAppIcons.confirm,
                  color: Colors.pinkAccent,
                  size: 20,
                ),
                const Text(
                  'Đã xem',
                  style: TextStyle(fontSize: 12),
                )
              ])),
        padding: const EdgeInsets.only(right: 20));
  }
}
