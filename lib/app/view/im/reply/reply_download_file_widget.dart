import 'dart:convert';
import 'dart:io';

import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/icon/app_icons.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/eoffice/mark_eoffice_page.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/viewmodel/im/reply/tapped_reply_download_file_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class IotReplyDownloadFileWidget extends StatefulWidget {
  final creator;
  final messageId;
  final fileData;
  final fullFilename;
  final fileType;
  final fileOrder;
  final eofficeId;
  final searchWords;

  IotReplyDownloadFileWidget(
      this.creator,
      this.messageId,
      this.fileData,
      this.fullFilename,
      this.fileType,
      this.fileOrder,
      this.eofficeId,
      this.searchWords);

  @override
  State<StatefulWidget> createState() {
    return _IotReplyDownloadFileWidgetState();
  }
}

class _IotReplyDownloadFileWidgetState
    extends State<IotReplyDownloadFileWidget> {
  final _downloadFileStream = IotTappedReplyDownloadFileStream();
  @override
  void dispose() {
    _downloadFileStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _childDownloadFile(
        widget.creator,
        widget.messageId,
        widget.fileData,
        widget.fullFilename,
        widget.fileType,
        widget.fileOrder,
        widget.eofficeId);
  }

  Widget _childDownloadFile(creator, messageId, _fileData, _fullFilename,
      _fileType, _fileOrder, _eofficeId) {
    String _suffixFile = IotUtility().applicationMineType(_fileType);
    _suffixFile = _suffixFile.isEmpty
        ? _fullFilename
            .substring(_fullFilename.lastIndexOf('.') + 1)
            .toUpperCase()
        : _suffixFile;
    bool _isJpgFile = _fileData != null &&
        _fileData.isNotEmpty &&
        (_fileType.startsWith('image/jpg') ||
            _fileType.startsWith('image/jpeg') ||
            _fileType.startsWith('image/png') ||
            _fileType.startsWith('application/pdf'));
    return GestureDetector(
      child: (!_isJpgFile)
          ? _otherFileContent(_fileType, _fullFilename, _fileData, _suffixFile)
          : _jpgFileContent(_fileType, _fullFilename, _fileData, _suffixFile,
              _eofficeId, _fileOrder, messageId, creator),
      onTap: () => _onTapChild(creator, messageId, _fullFilename, _fileType),
    );
  }

  Widget _prefixIcon(_suffixFile) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.all(5),
      child: Text(
        '$_suffixFile',
        style: TextStyle(
            shadows: [Shadow(color: Colors.red, blurRadius: 0.5)],
            color: IOT_FG_COLOR,
            fontSize: SP_COMMON_FONT_SIZE.sp,
            fontWeight: FontWeight.w700),
      ),
      //height: 0.06.sh,
      width: 0.07.sh,
      decoration: const BoxDecoration(
          color: IOT_BG_COLOR,
          borderRadius: BorderRadius.only(topRight: Radius.circular(20))),
    );
  }

  Widget _otherFileContent(_fileType, _fullFilename, _fileData, _suffixFile) {
    String _shortFilename = '$_fullFilename'.length < 20
        ? '$_fullFilename'
        : '$_fullFilename'.substring(0, 20) + '...';
    Color _borderColor = Colors.green.withOpacity(0.2);
    if (widget.searchWords != null &&
        widget.searchWords.toString().isNotEmpty) {
      if (_fullFilename
          .toString()
          .toLowerCase()
          .contains(widget.searchWords.toString().toLowerCase()))
        _borderColor = Colors.red;
    }

    return Stack(children: [
      StreamBuilder(
          stream: _downloadFileStream.downloadFileStream,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData)
              return Container(
                margin: const EdgeInsets.all(10),
                constraints: BoxConstraints(maxHeight: 0.065.sh),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.02),
                    border: Border.all(color: Colors.amber),
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
              );
            return SizedBox();
          }),
      Container(
          margin: const EdgeInsets.all(10),
          constraints: BoxConstraints(maxHeight: 0.065.sh),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.02),
              border: Border.all(color: _borderColor),
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          child: Row(children: [
            _prefixIcon(_suffixFile),
            Flexible(
              child: FittedBox(
                  child: Padding(
                    child: Text(_shortFilename,
                        style: TextStyle(
                          fontSize: SP_COMMON_FONT_SIZE.sp,
                        )),
                    padding: EdgeInsets.only(right: 5),
                  ),
                  fit: BoxFit.fitWidth),
              fit: FlexFit.loose,
            ),
          ]))
    ]);
  }

  Widget _jpgFileContent(_fileType, _fullFilename, _fileData, _suffixFile,
      _eofficeId, _fileOrder, _messageId, _creator) {
    return Stack(
      children: [
        StreamBuilder(
            stream: _downloadFileStream.downloadFileStream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData)
                return Container(
                  margin: const EdgeInsets.only(
                      top: 5, left: 10, right: 10, bottom: 5),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber),
                      borderRadius: const BorderRadius.all(Radius.circular(3))),
                  constraints: BoxConstraints(maxHeight: 0.20.sh),
                  width: double.infinity,
                );
              return SizedBox();
            }),
        Container(
            margin:
                const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.green.withOpacity(0.4)),
                borderRadius: const BorderRadius.all(Radius.circular(3))),
            constraints: BoxConstraints(maxHeight: 0.2.sh),
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 5, right: 5, left: 5),
            child: Image.memory(
              base64Decode(_fileData),
              fit: BoxFit.fill,
            )),
        _markEoffices(_fileType, _eofficeId, _fileOrder, _messageId, _creator)
      ],
      fit: StackFit.loose,
    );
  }

  void _onTapChild(creator, messageId, _fullFilename, _fileType) async {
    _downloadFileStream.tappedChild();
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return SimpleDialog(contentPadding: EdgeInsets.all(60), children: [
            FutureBuilder<IotDownloadFile>(
                future: IotReplyInternalMessageStream().downloadDataFiles(
                    creator, messageId, _fullFilename, _fileType),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Navigator.of(context).pop(true);
                    _previewDownloadFile(snapshot.data as IotDownloadFile);
                  } else if (snapshot.hasError) {
                    Navigator.of(context).pop(false);
                  }
                  return IotCircularProgressWidget();
                })
          ]);
        }).then((value) {
      if (!value)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('KHÔNG THỂ TẢI VỀ FILE NÀY !!')));
    });
  }

  void _previewDownloadFile(IotDownloadFile downloadFile) async {
    Directory _path = await getTemporaryDirectory();
    File _tempFile = File('${_path.path}/${downloadFile.fileName}');
    var raf = _tempFile.openSync(mode: FileMode.write);
    raf.writeFromSync(base64Decode(downloadFile.fileData));
    await raf.close();
    OpenResult result = await OpenFile.open(_tempFile.path);
    if (result.type == ResultType.noAppToOpen)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CHƯA CÀI ĐẶT APP ĐỂ ĐỌC ĐỊNH DẠNG FILE NÀY')));
  }

  Widget _markEoffices(
      _fileType, _eofficeId, _fileOrder, _messageId, _creator) {
    if (!_fileType.startsWith('application/pdf')) return SizedBox();

    return Positioned(
      child: IconButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => MarkEofficePage(
                      eOfficeId: _eofficeId,
                      messageId: _messageId,
                      messageCreator: _creator,
                      messageFileOrder: _fileOrder))),
          icon: Icon(IotAppIcons.category, color: Colors.grey)),
      top: -5,
      right: 0,
    );
  }
}
