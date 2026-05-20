import 'dart:async';
import 'dart:io';

import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/model/im/position.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/im/iot_emoji.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/var/app_static_variable.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/im/compose/list_postions_page.dart';
import 'package:dngmsp/app/view/im/forward/forward_message_page.dart';
import 'package:dngmsp/app/view/im/reply/emotion_user_page.dart';
import 'package:dngmsp/app/view/im/reply/reply_download_file_widget.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/viewmodel/im/compose/emoji_stream.dart';
import 'package:dngmsp/app/viewmodel/im/compose/emotion_stream.dart';
import 'package:dngmsp/app/viewmodel/im/compose/position_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'confirm_button.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class IotReplyInternalMessagePage extends StatefulWidget {
  final int originalId;
  final String originalCreator;
  final String groupName;
  final bool onTapBackground;
  final String searchWords;
  IotReplyInternalMessagePage(this.originalId, this.originalCreator,
      this.groupName, this.onTapBackground, this.searchWords);

  @override
  _IotReplyInternalMessagePageState createState() =>
      _IotReplyInternalMessagePageState();
}

class _IotReplyInternalMessagePageState
    extends State<IotReplyInternalMessagePage> {
  late final TextEditingController _controller;
  late final IotEmojiStream _emojiStream;
  late final IotEmotionStream _emotionStream;
  late final String _username;

  @override
  void initState() {
    super.initState();
    _emojiStream = IotEmojiStream();
    _emotionStream = IotEmotionStream();
    _controller = TextEditingController();
    IotStaticVariable.iotOnReplyInternalMessagePage = true;
  }

  @override
  void dispose() async {
    _emojiStream.dispose();
    _emotionStream.dispose();
    _controller.dispose();
    IotStaticVariable.iotOnReplyInternalMessagePage = false;
    /*
    Future<void> _deleteCacheDir() async {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
    }

    final appDir = await getApplicationSupportDirectory();
    if (appDir.existsSync()) {
      appDir.deleteSync(recursive: true);
    }

     */
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: IotAppBar().build(context, false, widget.groupName),
          body: FutureBuilder(
              future: IotSharedPreferences().get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = snapshot.data as List<String>;
                  _username = data[3];
                  return _buildBody();
                }
                return SizedBox();
              }),
          bottomNavigationBar: IotBottomNavigatorBar(),
        ),
        onWillPop: () async {
          if (widget.onTapBackground)
            Navigator.popUntil(
                context, ModalRoute.withName(IotRoutes.HOME_PAGE));
          else
            Navigator.of(context).pop();
          return true;
        });
  }

  Widget _buildBody() {
    return FutureBuilder(
        future: context
            .read<IotReplyInternalMessageStream>()
            .listReplyIotInternalMessages(
                widget.originalId, widget.originalCreator),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return IotExceptionPage(exception: snapshot.error);
          if (snapshot.hasData) {
            return Container(
                child: Column(
              children: [
                Expanded(
                    child: Container(
                  alignment: FractionalOffset.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: _buildOriginalMessages(
                                snapshot.data as List<IotInternalMessage>),
                            fit: FlexFit.loose,
                          ),
                          Flexible(
                              child: _buildIncomingMessages(),
                              fit: FlexFit.loose)
                        ],
                      )),
                )),
                Column(
                  children: [
                    _composeMessageContent(),
                    Padding(
                        child: Align(
                          child: _composeMessageButton(),
                          alignment: Alignment.centerRight,
                        ),
                        padding: const EdgeInsets.only(right: 20)),
                  ],
                )
              ],
            ));
          }
          return IotCircularProgressWidget();
        });
    //});
  }

  Widget _buildIncomingMessages() {
    var _hasInitiation = false;
    return Consumer<IotReplyInternalMessageStream>(builder: (context, fcm, _) {
      return FutureBuilder(
          future: context
              .watch<IotReplyInternalMessageStream>()
              .listIncomingReplyMessages(_hasInitiation),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _hasInitiation = true;
              List<IotInternalMessage> data =
                  snapshot.data as List<IotInternalMessage>;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: data.length,
                reverse: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.all(Radius.circular(12.0))),
                    margin: const EdgeInsets.all(30.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _messageTopBar(data[index].creatorName, data[index].time),
                      _messageTitle(data[index].title),
                      ((data[index].hasFile ?? 'N') == 'Y'
                          ? _messageFiles(data[index].id, data[index].creator)
                          : SizedBox()),
                      _messageButtons(true, data[index].id, data[index].creator,
                          data[index].emotion ?? 0)
                    ]),
                  );
                },
              );
            }
            return SizedBox();
          });
    });
  }

  Widget _buildOriginalMessages(List<IotInternalMessage> data) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: data.length,
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.all(Radius.circular(12.0))),
          margin: const EdgeInsets.all(30.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _messageTopBar(data[index].creatorName, data[index].time),
            _messageTitle(data[index].title),
            ((data[index].hasFile ?? 'N') == 'Y'
                ? _messageFiles(data[index].id, data[index].creator)
                : SizedBox()),
            _messageButtons(false, data[index].id, data[index].creator,
                data[index].emotion ?? 0)
          ]),
        );
      },
    );
  }

  Widget _messageTopBar(String creatorName, int time) {
    return Container(
        decoration: const BoxDecoration(
            color: Colors.black12,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11.0),
                topRight: Radius.circular(11.0))),
        padding: const EdgeInsets.all(10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: Text(
                creatorName,
                style: TextStyle(fontSize: SP_SMALL_COMMON_FONT_SIZE.sp),
              ),
              fit: FlexFit.loose),
          Text(
            IotUtility().parseTimeMessage(time),
            style: TextStyle(
                color: Colors.black87, fontSize: SP_SMALL_COMMON_FONT_SIZE.sp),
          ),
        ]));
  }

  Widget _messageTitle(String title) {
    return Container(
        constraints: const BoxConstraints(minWidth: double.infinity),
        padding: const EdgeInsets.all(10),
        child: RichText(
          text: TextSpan(
              children: IotReplyInternalMessageStream()
                  .extractIotMessageTitle(context, title, widget.searchWords)),
        ));
  }

  Widget _messageFiles(int messageId, String creator) {
    return FutureBuilder(
        future: IotReplyInternalMessageStream().downloadFiles(
            messageId, widget.originalId, widget.originalCreator),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<IotDownloadFile> files =
                snapshot.data as List<IotDownloadFile>;
            return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return IotReplyDownloadFileWidget(
                      creator,
                      messageId,
                      files[index].fileData,
                      files[index].fileName,
                      files[index].fileType,
                      files[index].fileOrder,
                      files[index].eofficeId,
                      widget.searchWords);
                });
          }
          if (snapshot.hasError) return Icon(Icons.error_outline);
          return CircularProgressIndicator(
            strokeWidth: 1.0,
          );
        });
  }

  Widget _messageButtons(
      bool isInComing, int messageId, String messageCreator, int emotion) {
    return Row(
      children: [
        _messageForwardButton(messageId, messageCreator),
        Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Padding(
              child: _messageEmotionButton(messageId),
              padding: const EdgeInsets.only(right: 15)),
          (messageCreator == _username
              ? SizedBox()
              : IotConfirmButton(
                  originalId: widget.originalId,
                  originalCreator: widget.originalCreator,
                  messageId: messageId,
                  emotion: emotion,
                  isIncoming: isInComing,
                ))
        ])),
      ],
    );
  }

  Widget _messageForwardButton(int messageId, String messageCreator) {
    return TextButton(
        onPressed: () async {
          final IotPositionStream positionStream = IotPositionStream();
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return SimpleDialog(children: [
                  FutureBuilder<List<IotPosition>>(
                      future: positionStream.initPositions(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) Navigator.of(context).pop();
                        if (snapshot.hasError)
                          return IotExceptionPage(exception: snapshot.error);
                        return IotCircularProgressWidget();
                      })
                ]);
              });
          if (positionStream.positions.isNotEmpty)
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            IotListPositionsPage(positionStream)))
                .then((value) async {
              if (positionStream.positions
                  .where((element) => element.selected ?? false)
                  .isNotEmpty)
                await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return SimpleDialog(
                          contentPadding: EdgeInsets.zero,
                          titlePadding: EdgeInsets.zero,
                          children: [
                            IotForwardMessagePage(
                                positionStream,
                                widget.originalId,
                                widget.originalCreator,
                                messageId,
                                messageCreator)
                          ]);
                    });
            });
        },
        child: Column(
          children: [
            const Icon(Icons.forward),
            Text(
              'Chuyển tiếp',
              style: TextStyle(fontSize: SP_SMALL_COMMON_FONT_SIZE.sp),
            )
          ],
        ));
  }

  Widget _messageEmotionButton(int messageId) {
    return IconButton(
      icon: Icon(
        Icons.people_outline_rounded,
        color: IOT_BG_COLOR,
      ),
      onPressed: () async {
        await showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                  contentPadding: EdgeInsets.zero,
                  titlePadding: EdgeInsets.zero,
                  children: [
                    IotEmotionUserPage(
                      originalId: widget.originalId,
                      originalCreator: widget.originalCreator,
                      messageId: messageId,
                    )
                  ]);
            });
      },
    );
  }

  Widget _composeMessageButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(child: SizedBox()),
        _sendButton()
      ],
    );
  }


  Widget _sendButton() {
    return TextButton(
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        const Icon(
          Icons.send,
          size: 32,
          color: IOT_BG_COLOR,
        ),
        Text(
          'Gửi',
          style: TextStyle(
              color: IOT_BG_COLOR,
              fontSize: SP_COMMON_FONT_SIZE.sp,
              fontWeight: FontWeight.bold),
        ),
      ]),
      onPressed: () async => await _sendMessage(),
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'CHƯA CÓ NỘI DUNG',
        ),
        action: SnackBarAction(
          onPressed: () => null,
          label: 'OK',
        ),
        padding: EdgeInsets.all(10),
      ));
      return;
    }

    List<IotInternalMessage> _uploadedMessage = [];
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WillPopScope(
              child:
                  SimpleDialog(contentPadding: EdgeInsets.all(60), children: [
                FutureBuilder<List<IotInternalMessage>>(
                    future: context
                        .read<IotReplyInternalMessageStream>()
                        .uploadReplyMessage(
                            widget.originalId,
                            widget.originalCreator,
                            DateTime.now().millisecondsSinceEpoch,
                            _controller.text,
                            <File>[]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        Navigator.of(context).pop();
                        _uploadedMessage =
                            snapshot.data as List<IotInternalMessage>;
                      } else if (snapshot.hasError) Navigator.of(context).pop();
                      return IotCircularProgressWidget();
                    })
              ]),
              onWillPop: () async => false);
        });
    if (_uploadedMessage.isNotEmpty) {
      _controller.clear();
      _emojiStream.hideEmojis();
      await context
          .read<IotListInternalMessageStream>()
          .updateListInternalMessage(_uploadedMessage.first);
    } else
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.white,
          padding: EdgeInsets.all(15),
          content: Text(
            'KHÔNG GỬI THÔNG TIN NÀY ĐƯỢC !!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          )));
  }

  Widget _composeMessageContent() {
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
