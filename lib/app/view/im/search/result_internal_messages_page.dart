import 'dart:convert';
import 'dart:io';

import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/im/reply/navigator_internal_message.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/search/search_internal_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Tên file an toàn để ghi vào thư mục tạm: bỏ phần đường dẫn do server gửi về.
String iotSafeTempFileName(String fileName) {
  final base = fileName.split(RegExp(r'[\\/]')).last.trim();
  if (base.isEmpty || base == '.' || base == '..') return 'van_ban';
  return base;
}

/// US-3: kết quả tìm kiếm theo văn bản — mỗi dòng là một văn bản khớp từ khóa.
class IotResultInternalMessagesPage extends StatefulWidget {
  final String fromDate;
  final String toDate;
  final String senders;
  final String keyword;
  IotResultInternalMessagesPage(
    this.fromDate,
    this.toDate,
    this.senders,
    this.keyword,
  );

  @override
  _IotResultInternalMessagesPageState createState() =>
      _IotResultInternalMessagesPageState();
}

class _IotResultInternalMessagesPageState
    extends State<IotResultInternalMessagesPage> {
  late final Future<List<IotDocumentSearchResult>> _searchFuture;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _status = 0;

  bool get _isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  double get _commonFontSize => _isLandscape ? 16 : SP_COMMON_FONT_SIZE.sp;

  double get _smallFontSize => _isLandscape ? 14 : SP_SMALL_COMMON_FONT_SIZE.sp;

  @override
  void initState() {
    super.initState();
    _searchFuture = context
        .read<IotSearchInternalMessageStream>()
        .searchDocuments(
          widget.fromDate,
          widget.toDate,
          widget.senders,
          widget.keyword,
        );
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 50) _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    final stream = context.read<IotSearchInternalMessageStream>();
    if (_isLoadingMore || !stream.hasMore) return;
    setState(() => _isLoadingMore = true);
    final status = await stream.loadMoreDocuments(
      context,
      widget.fromDate,
      widget.toDate,
      widget.senders,
      widget.keyword,
    );
    if (!mounted) return;
    setState(() {
      _status = status;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 2;
    return IotPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, false, 'KẾT QUẢ TÌM VĂN BẢN'),
        body: FutureBuilder<List<IotDocumentSearchResult>>(
          future: _searchFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return IotExceptionPage(
                exception: snapshot.error,
                isBackHome: true,
              );
            if (!snapshot.hasData) return IotCircularProgressWidget();
            return Consumer<IotSearchInternalMessageStream>(
              builder: (context, stream, _) =>
                  _listDocuments(stream.documents, stream.hasMore),
            );
          },
        ),
        backgroundColor: Colors.white,
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, false),
    );
  }

  Widget _listDocuments(List<IotDocumentSearchResult> data, bool hasMore) {
    if (data.isEmpty && !hasMore)
      return Center(
        child: Text(
          'KHÔNG TÌM THẤY VĂN BẢN NÀO',
          style: TextStyle(
            color: IOT_BG_COLOR,
            fontSize: _commonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    return ListView.builder(
      controller: _scrollController,
      itemCount: data.length + 1,
      itemBuilder: (context, index) {
        if (index == data.length) return _listFooter(hasMore);
        return _documentItem(data[index]);
      },
    );
  }

  Widget _listFooter(bool hasMore) {
    Widget child;
    if (_isLoadingMore)
      child = const CircularProgressIndicator();
    else if (_status < 0)
      child = TextButton.icon(
        icon: const Icon(Icons.refresh, color: Colors.black87),
        label: Text(
          _status == -1 ? 'MẤT KẾT NỐI' : 'TẢI LỖI',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _loadMore,
      );
    else if (hasMore)
      child = TextButton(
        child: Text('Tải thêm', style: TextStyle(fontSize: _smallFontSize)),
        onPressed: _loadMore,
      );
    else
      child = const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: child),
    );
  }

  Widget _documentItem(IotDocumentSearchResult document) {
    final message = document.message;
    final heading = document.documentNo.isEmpty
        ? 'Văn bản'
        : 'VB ${document.documentNo}';
    return InkWell(
      onTap: () => _openDocument(document),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(
                Icons.description_outlined,
                color: IOT_BG_COLOR,
                size: _isLandscape ? 24 : 28,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _showGroupAndTime(message.groupName ?? ' ', message.time),
                  const SizedBox(height: 4),
                  _highlightText(heading, FontWeight.bold),
                  if (document.summary.isNotEmpty)
                    _highlightText(document.summary, FontWeight.normal),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.forum_outlined, color: Colors.black54),
              tooltip: 'Xem tin nhắn',
              onPressed: () => _openMessage(document),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightText(String text, FontWeight fontWeight) {
    final style = TextStyle(
      color: Colors.black87,
      fontSize: _commonFontSize,
      fontWeight: fontWeight,
    );
    if (widget.keyword.trim().isEmpty) return Text(text, style: style);
    return RichText(
      text: TextSpan(
        style: style,
        children: IotReplyInternalMessageStream().highlightOccurrences(
          text,
          widget.keyword.trim(),
          fontSize: _commonFontSize,
        ),
      ),
    );
  }

  Widget _showGroupAndTime(String groupName, int time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.black54, fontSize: _smallFontSize),
          ),
        ),
        Text(
          IotUtility().parseTimeMessage(time),
          style: TextStyle(color: Colors.black54, fontSize: _smallFontSize),
        ),
      ],
    );
  }

  Future<void> _openMessage(IotDocumentSearchResult document) async {
    final message = document.message;
    await IotNavigatorInternalMessage().onTap(
      context,
      message.originalId,
      message.originalCreator,
      message.groupName ?? '',
      false,
      widget.keyword,
    );
  }

  Future<void> _openDocument(IotDocumentSearchResult document) async {
    final message = document.message;
    if ((message.hasFile ?? 'N') != 'Y') return _openMessage(document);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => IotPopScope(
        child: SimpleDialog(
          contentPadding: const EdgeInsets.all(60),
          children: [IotCircularProgressWidget()],
        ),
        onWillPop: () async => false,
      ),
    );
    IotDownloadFile? file;
    try {
      file = await IotReplyInternalMessageStream().downloadMessageDocument(
        originalId: message.originalId,
        originalCreator: message.originalCreator,
        messageId: message.id,
        creator: message.creator,
        fileIndex: document.fileIndex,
      );
    } catch (_) {
      file = null;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KHÔNG THỂ TẢI VỀ FILE NÀY !!')),
      );
      return;
    }
    await _openDownloadedFile(file);
  }

  Future<void> _openDownloadedFile(IotDownloadFile file) async {
    final directory = await getTemporaryDirectory();
    final tempFile = File(
      '${directory.path}/${iotSafeTempFileName(file.fileName)}',
    );
    await tempFile.writeAsBytes(base64Decode(file.fileData), flush: true);
    final result = await OpenFile.open(tempFile.path);
    if (!mounted) return;
    if (result.type == ResultType.noAppToOpen)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CHƯA CÀI ĐẶT APP ĐỂ ĐỌC ĐỊNH DẠNG FILE NÀY'),
        ),
      );
  }
}
