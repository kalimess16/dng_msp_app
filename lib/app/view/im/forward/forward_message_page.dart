import 'package:dngmsp/app/model/im/position.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/view/im/compose/list_postions_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/viewmodel/im/compose/position_stream.dart';
import 'package:dngmsp/app/viewmodel/im/forward/forward_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotForwardMessagePage extends StatefulWidget {
  final IotPositionStream positionStream;
  final int originalId;
  final String originalCreator;
  final int messageId;
  final String messageCreator;

  IotForwardMessagePage(this.positionStream, this.originalId, this.originalCreator, this.messageId,
      this.messageCreator);
  @override
  _IotForwardMessagePageState createState() => _IotForwardMessagePageState();
}

class _IotForwardMessagePageState extends State<IotForwardMessagePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    widget.positionStream.dispose();
    super.dispose();
  }

  String _errorMessage = '';
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
          stream: widget.positionStream.positionStream,
          builder: (BuildContext context, AsyncSnapshot<List<IotPosition>> snapshot) {
            return Column(
                //mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _forwardTitle(),
                  _buildForwardUsers(),
                  _buildForwardMessage(),
                  _buildErrorMessage()
                ]);
          }),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: IOT_BG_COLOR)),
      width: 0.8.sw,
    );
  }

  Widget _forwardTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Chuyển tiếp đến ",
          style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
        ),
        IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_outlined, size: 28))
      ],
    );
  }

  Widget _buildForwardUsers() {
    var _positions =
        widget.positionStream.positions.where((element) => element.selected ?? false).toList();
    String _names = _positions[0].name;
    if (_positions.length >= 2)
      _names = _names + ' và ' + '${_positions.length - 1} người khác ...';
    return Center(
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
                  builder: (BuildContext context) => IotListPositionsPage(widget.positionStream)))),
    );
  }

  Widget _buildForwardMessage() {
    return TextFormField(
      controller: _controller,
      minLines: 1,
      maxLines: 5,
      style: TextStyle(color: Colors.black, fontSize: SP_COMMON_FONT_SIZE.sp),
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: 'Mô tả',
        hintStyle: const TextStyle(color: Colors.black26),
        suffixIcon: _forwardSendButton(),
        isDense: true,
        border: const OutlineInputBorder(borderSide: BorderSide(color: IOT_BG_COLOR)),
      ),
    );
  }

  Widget _forwardSendButton() {
    return IconButton(
        onPressed: () async => await _sendForwardMessage(),
        icon: const Icon(
          Icons.send,
          size: 32,
          color: IOT_BG_COLOR,
        ));
  }

  Future<void> _sendForwardMessage() async {
    var _receivers = widget.positionStream.positions.where((value) => value.selected ?? false);
    if (_receivers.isEmpty) {
      setState(() {
        _errorMessage = 'CHƯA CHỌN NGƯỜI CHUYỂN TIẾP';
      });
      return;
    }
    List<String> _positionIds = [];
    _receivers.forEach((element) {
      _positionIds.add(element.id);
    });
    bool _isUploaded = false;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return IotPopScope(
              child: SimpleDialog(contentPadding: EdgeInsets.all(60), children: [
                FutureBuilder<bool>(
                    future: IotForwardMessageStream().uploadForwardMessage(
                        widget.originalId,
                        widget.originalCreator,
                        widget.messageId,
                        widget.messageCreator,
                        _positionIds.join(';'),
                        _controller.text),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        Navigator.of(context).pop();
                        _isUploaded = snapshot.data as bool;
                      } else if (snapshot.hasError) Navigator.of(context).pop();
                      return IotCircularProgressWidget();
                    })
              ]),
              onWillPop: () async => false);
        });
    if (_isUploaded) {
      Navigator.of(context).pop();
    } else
      setState(() {
        _errorMessage = 'LỖI KHÔNG CHUYỂN TIẾP ĐƯỢC .';
      });
  }

  Widget _buildErrorMessage() {
    return Padding(
      child: Opacity(
          opacity: _errorMessage.isNotEmpty ? 1.0 : 0.0,
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          )),
      padding: EdgeInsets.all(10),
    );
  }
}
