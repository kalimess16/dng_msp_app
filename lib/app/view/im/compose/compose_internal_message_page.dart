import 'dart:io';

import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/im/iot_emoji.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/viewmodel/im/compose/compose_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/compose/emoji_stream.dart';
import 'package:dngmsp/app/viewmodel/im/compose/position_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:provider/provider.dart';

import 'position_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotComposeInternalMessagePage extends StatefulWidget {
  final bool openFromHomePage;
  IotComposeInternalMessagePage({required this.openFromHomePage});

  @override
  _IotComposeInternalMessagePageState createState() =>
      _IotComposeInternalMessagePageState();
}

class _IotComposeInternalMessagePageState
    extends State<IotComposeInternalMessagePage> {
  late final TextEditingController _controller;
  late final IotComposeMessageStream _composeMessageStream;
  late final IotEmojiStream _emojiStream;
  late final IotPositionStream _positionStream;

  final int _originalId = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _composeMessageStream = IotComposeMessageStream();
    _emojiStream = IotEmojiStream();
    _positionStream = IotPositionStream();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _emojiStream.dispose();
    _controller.dispose();
    _positionStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IotPopScope(
        child: Scaffold(
            appBar: IotAppBar().build(context, false, 'SOẠN THÔNG TIN'),
            body: _buildBody()),
        onWillPop: () => IotAppBar().backIotPages(context, false));
  }

  Widget _buildBody() {
    return Container(
        child: Column(
      children: [
        Padding(
            child: Align(
              child: IotPositionButton(_positionStream),
              alignment: Alignment.centerRight,
            ),
            padding: const EdgeInsets.only(right: 20, top: 5, bottom: 5)),
        _buildBodyMessage(),
        _buildSendButton(),
      ],
    ));
  }

  Future<void> _sendMessage() async {
    var _receivers =
        _positionStream.positions.where((value) => value.selected ?? false);
    if (_receivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'CHƯA CÓ NGƯỜI NHẬN',
        ),
        action: SnackBarAction(
          onPressed: () => null,
          label: 'OK',
        ),
        padding: const EdgeInsets.all(10),
      ));
      return;
    }
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'CHƯA CÓ NỘI DUNG ',
        ),
        action: SnackBarAction(
          onPressed: () => null,
          label: 'OK',
        ),
        padding: const EdgeInsets.all(10),
      ));
      return;
    }
    List<String> _positionIds = [];
    _receivers.forEach((element) {
      _positionIds.add(element.id);
    });
    if (widget.openFromHomePage)
      await _uploadMessage(_positionIds);
    else
      await _uploadMessageInList(_positionIds);
  }

  Future<void> _uploadMessage(_positionIds) async {
    bool _isUploaded = false;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return IotPopScope(
              child: SimpleDialog(
                  contentPadding: EdgeInsets.zero,
                  titlePadding: EdgeInsets.zero,
                  children: [
                    FutureBuilder<bool>(
                        future: _composeMessageStream.uploadMessage(
                            _originalId,
                            _positionIds.join(';'),
                            _controller.text,
                            <File>[]),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            Navigator.of(context).pop();
                            _isUploaded = snapshot.data as bool;
                          } else if (snapshot.hasError)
                            Navigator.of(context).pop();

                          return Container(
                            child: IotCircularProgressWidget(),
                            width: 120,
                            height: 120,
                            color: Colors.black12,
                          );
                        })
                  ]),
              onWillPop: () async => false);
        });
    if (_isUploaded)
      Navigator.of(context).pop();
    else
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(15),
          content: const Text(
            'KHÔNG GỬI THÔNG TIN NÀY ĐƯỢC !!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          )));
  }

  Future<void> _uploadMessageInList(_positionIds) async {
    List<IotInternalMessage> _messageInList = [];
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return IotPopScope(
              child: SimpleDialog(
                  contentPadding: EdgeInsets.zero,
                  titlePadding: EdgeInsets.zero,
                  children: [
                    FutureBuilder<List<IotInternalMessage>>(
                        future: _composeMessageStream.uploadMessageInList(
                            _originalId,
                            _positionIds.join(';'),
                            _controller.text,
                            <File>[]),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            Navigator.of(context).pop();
                            _messageInList =
                                snapshot.data as List<IotInternalMessage>;
                          } else if (snapshot.hasError)
                            Navigator.of(context).pop();

                          return Container(
                            child: IotCircularProgressWidget(),
                            width: 120,
                            height: 120,
                            color: Colors.black12,
                          );
                        })
                  ]),
              onWillPop: () async => false);
        });
    if (_messageInList.isNotEmpty) {
      _controller.clear();
      _emojiStream.hideEmojis();
      await context
          .read<IotListInternalMessageStream>()
          .updateListInternalMessage(_messageInList.first);
      Navigator.of(context).pop();
    } else
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(15),
          content: const Text(
            'KHÔNG GỬI THÔNG TIN NÀY ĐƯỢC !!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          )));
  }


  Widget _buildBodyMessage() {
    return Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(child: _buildEmojis(), fit: FlexFit.loose),
            _buildMessage(),
          ],
        ),
        alignment: Alignment.bottomCenter);
  }

  Widget _buildMessage() {
    return TextFormField(
      controller: _controller,
      minLines: 1,
      maxLines: 5,
      style: TextStyle(color: Colors.black, fontSize: SP_COMMON_FONT_SIZE.sp),
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: 'Nội dung thông tin',
        hintStyle: const TextStyle(color: Colors.black26),
        suffixIcon: _buildEmojiButton(),
        isDense: true,
        border: const OutlineInputBorder(
            borderSide: BorderSide(color: IOT_BG_COLOR)),
      ),
      onTap: () => _emojiStream.hideEmojis(),
    );
  }

  Widget _buildSendButton() {
    return Container(
        decoration: const BoxDecoration(color: IOT_BG_COLOR),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(
                  Icons.send,
                  color: IOT_FG_COLOR,
                  size: 36,
                ),
                onPressed: () async => await _sendMessage()),
            Flexible(
                child: Text(
                  'Gửi',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: SP_COMMON_FONT_SIZE.sp,
                      fontWeight: FontWeight.bold),
                ),
                fit: FlexFit.loose)
          ],
        ));
  }

  Widget _buildEmojiButton() {
    return IconButton(
        icon: const Icon(
          Icons.emoji_emotions_outlined,
          size: 36,
          color: Colors.black54,
        ),
        onPressed: () async {
          await _emojiStream.showEmojis();
        });
  }

  Widget _buildEmojis() {
    final List<Widget> _emojiWidgets = [];
    IotEmoji().emojis.forEach((emoji) {
      _emojiWidgets.add(GestureDetector(
          child: Container(
            child: FittedBox(
              child: Text(emoji),
              fit: BoxFit.fitHeight,
            ),
            height: 8 * (Platform.isIOS ? 1.2 : 1),
            padding: const EdgeInsets.all(5),
          ),
          onTap: () => _onEmojiSelected(emoji)));
    });

    return StreamBuilder(
        stream: _emojiStream.emojiStream,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.data == null) return SizedBox();
          final bool _offstage = snapshot.data as bool;
          if (!_offstage) return const SizedBox();
          return Container(
              height: 120,
              decoration: BoxDecoration(
                  border: Border.all(color: IOT_FG_COLOR, width: 1.5)),
              child: GridView.count(
                  padding: const EdgeInsets.all(5),
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  crossAxisCount: 9,
                  shrinkWrap: true,
                  children: _emojiWidgets));
        });
  }

  _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (text.isEmpty || selection.start < 0)
      _controller
        ..text += emoji
        ..selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length));
    else {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.baseOffset + emoji.length),
      );
    }
  }
}
