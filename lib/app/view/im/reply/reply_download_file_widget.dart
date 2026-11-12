import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/icon/app_icons.dart';
import 'package:dngmsp/app/service/im/pdf_preview_service.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/eoffice/mark_eoffice_page.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/viewmodel/im/reply/tapped_reply_download_file_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Chiều cao tối đa của ảnh xem trước văn bản, theo tỉ lệ chiều cao màn hình.
const double IOT_PREVIEW_MAX_HEIGHT_FACTOR = 0.32;

/// Tỉ lệ rộng/cao dùng khi chưa đọc được kích thước ảnh (ảnh server 715x463).
const double IOT_PREVIEW_DEFAULT_ASPECT = 715 / 463;

/// Đọc kích thước pixel của ảnh mà không giải mã toàn bộ ảnh.
Future<Size?> iotReadImageSize(Uint8List bytes) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size =
        Size(descriptor.width.toDouble(), descriptor.height.toDouble());
    descriptor.dispose();
    buffer.dispose();
    if (size.width <= 0 || size.height <= 0) return null;
    return size;
  } catch (_) {
    return null;
  }
}

/// Kích thước khung hiển thị ảnh xem trước: giữ tỉ lệ ảnh, rộng tối đa bằng
/// [availableWidth], cao tối đa [maxHeight]; ảnh dải dọc (ảnh cũ server cắt
/// sai trang xoay) chỉ co lại theo chiều cao chứ không bị bóp dẹt.
Size iotPreviewBoxSize({
  required double availableWidth,
  required Size? imageSize,
  required double maxHeight,
}) {
  final double aspect = (imageSize == null)
      ? IOT_PREVIEW_DEFAULT_ASPECT
      : imageSize.width / imageSize.height;
  double width = availableWidth;
  double height = width / aspect;
  if (height > maxHeight) {
    height = maxHeight;
    width = math.min(availableWidth, height * aspect);
  }
  return Size(width, height);
}

class IotReplyDownloadFileWidget extends StatefulWidget {
  final creator;
  final messageId;
  final fileData;
  final fullFilename;
  final fileType;
  final fileOrder;
  final eofficeId;
  final searchWords;

  /// Số hiệu văn bản lấy từ dòng tiêu đề `- VB <số hiệu> :` tương ứng, dùng cho
  /// nhãn "VB: ..." khi app tạo lại ảnh xem trước.
  final String? documentNo;

  IotReplyDownloadFileWidget(
      this.creator,
      this.messageId,
      this.fileData,
      this.fullFilename,
      this.fileType,
      this.fileOrder,
      this.eofficeId,
      this.searchWords,
      {this.documentNo});

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
    Color _borderColor = Colors.green.withValues(alpha: 0.2);
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
                    color: Colors.black.withValues(alpha: 0.02),
                    border: Border.all(color: Colors.amber),
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
              );
            return SizedBox();
          }),
      Container(
          margin: const EdgeInsets.all(10),
          constraints: BoxConstraints(maxHeight: 0.065.sh),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.02),
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

  /// Bytes ảnh xem trước đã giải mã, giữ lại giữa các lần rebuild để
  /// `MemoryImage` không bị giải mã lại (tránh nháy ảnh khi cuộn/bấm).
  String? _previewSource;
  Uint8List? _previewBytes;
  Future<Size?>? _previewSize;

  Uint8List _previewImageBytes(String fileData) {
    if (_previewSource != fileData || _previewBytes == null) {
      _previewSource = fileData;
      _previewBytes = base64Decode(fileData);
      _previewSize = iotReadImageSize(_previewBytes!);
      if ('${widget.fileType}'.startsWith('application/pdf')) {
        _regeneratePreview(fileData, _previewBytes!);
      }
    }
    return _previewBytes!;
  }

  /// IotApp US-7/US-9/US-10: ảnh server của văn bản eOffice (nhãn "VB:") hoặc ảnh dải
  /// dọc cũ (máy photo) → tải PDF ở nền, tạo lại ảnh có "tiêu đề + Sao gửi … Lưu VT".
  /// Lỗi thì giữ ảnh server.
  Future<void> _regeneratePreview(String source, Uint8List serverPreview) async {
    final IotPixels? pixels = await IotPixels.decode(serverPreview);
    if (pixels == null) return;
    final bool eoffice = IotPdfPreviewService.hasEofficeLabel(pixels);
    if (!eoffice && !IotPdfPreviewService.isLegacyRotatedPreview(pixels)) {
      return; // file đính kèm thường, ảnh server đã đúng
    }
    final String fileName = '${widget.fullFilename}';
    final Uint8List? png = await IotPdfPreviewService.regenerate(
      messageId: widget.messageId as int,
      fileName: fileName,
      eoffice: eoffice,
      label: eoffice ? 'VB: ${_documentLabel(fileName)}' : null,
      loadPdf: () async {
        final IotDownloadFile file = await IotReplyInternalMessageStream()
            .downloadDataFiles(widget.creator, widget.messageId, fileName,
                widget.fileType);
        return base64Decode(file.fileData);
      },
    );
    if (png == null || !mounted || _previewSource != source) return;
    setState(() {
      _previewBytes = png;
      _previewSize = iotReadImageSize(png);
    });
  }

  /// Số hiệu cho nhãn: từ dòng tiêu đề; không có thì suy từ tên file
  /// ("VB 03-NQ-BĐD (..).pdf" → "03-NQ-BĐD"); tên file khác thì để trống như server.
  String _documentLabel(String fileName) {
    final String? documentNo = widget.documentNo?.trim();
    if (documentNo != null && documentNo.isNotEmpty) return documentNo;
    if (!RegExp(r'^VB\s', caseSensitive: false).hasMatch(fileName)) return '';
    return fileName
        .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^VB\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*\(.*\)\s*$'), '')
        .trim();
  }

  Widget _jpgFileContent(_fileType, _fullFilename, _fileData, _suffixFile,
      _eofficeId, _fileOrder, _messageId, _creator) {
    final Uint8List bytes = _previewImageBytes(_fileData);
    return Stack(
      children: [
        StreamBuilder(
            stream: _downloadFileStream.downloadFileStream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              final Color borderColor = snapshot.hasData
                  ? Colors.amber
                  : Colors.green.withValues(alpha: 0.4);
              return Container(
                  margin: const EdgeInsets.only(
                      top: 5, left: 10, right: 10, bottom: 5),
                  decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: const BorderRadius.all(Radius.circular(3))),
                  width: double.infinity,
                  padding: const EdgeInsets.all(5),
                  child: _previewImage(bytes));
            }),
        _markEoffices(_fileType, _eofficeId, _fileOrder, _messageId, _creator)
      ],
      fit: StackFit.loose,
    );
  }

  /// Ảnh xem trước giữ đúng tỉ lệ gốc (US-5 IotApp): không kéo giãn vào khung
  /// cố định, chỉ co lại khi vượt chiều cao tối đa.
  Widget _previewImage(Uint8List bytes) {
    return FutureBuilder<Size?>(
        future: _previewSize,
        builder: (context, snapshot) {
          final Size? imageSize = snapshot.data;
          return LayoutBuilder(builder: (context, constraints) {
            final Size box = iotPreviewBoxSize(
              availableWidth: constraints.maxWidth,
              imageSize: imageSize,
              maxHeight: IOT_PREVIEW_MAX_HEIGHT_FACTOR.sh,
            );
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: box.width,
                height: box.height,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
            );
          });
        });
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
