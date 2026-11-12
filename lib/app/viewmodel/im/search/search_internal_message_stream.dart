import 'dart:async';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/service/im/reply/reply_internal_message_service.dart';
import 'package:dngmsp/app/service/im/search/search_internal_message_service.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:flutter/material.dart';

typedef IotSearchMessagesFetcher =
    Future<List<IotInternalMessage>> Function(
      String fromDate,
      String toDate,
      String senders,
      String content,
      int startTime,
    );

/// Lấy toàn bộ tin của một chuỗi (nội dung đầy đủ, như màn xem tin nhắn).
typedef IotThreadMessagesFetcher =
    Future<List<IotInternalMessage>> Function(
      int originalId,
      String originalCreator,
    );

/// Một văn bản (dòng `- VB <số hiệu> : <trích yếu>`) trong tin nhắn khớp từ khóa tìm kiếm.
class IotDocumentSearchResult {
  final IotInternalMessage message;

  /// Thứ tự dòng `- VB` trong tin nhắn, cũng là thứ tự file đính kèm tương ứng.
  final int fileIndex;
  final String documentNo;
  final String summary;

  const IotDocumentSearchResult({
    required this.message,
    required this.fileIndex,
    required this.documentNo,
    required this.summary,
  });
}

/// US-3: tìm theo tên/số hiệu văn bản, chỉ trả về các văn bản khớp, không trả cả tin nhắn.
/// US-10: mỗi lần tải (tìm lần đầu hoặc nhấn "Xem thêm") hiện tối đa [pageSize] văn bản mới nhất.
class IotSearchInternalMessageStream extends ChangeNotifier {
  /// Số văn bản hiện thêm sau mỗi lần tải.
  static const int pageSize = 20;

  /// Số trang tin nhắn tối đa đọc liên tiếp trong một lần tải khi chưa gom đủ [pageSize] văn bản.
  static const int maxPagesPerLoad = 10;

  static final RegExp _documentLineRegExp = RegExp(
    r'^\s*-?\s*VB[\s:]+(.*)$',
    caseSensitive: false,
  );

  static const Map<String, String> _vietnameseGroups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  static final Map<int, String> _vietnameseFold = {
    for (final entry in _vietnameseGroups.entries)
      for (final rune in entry.value.runes) rune: entry.key,
  };

  /// Số chuỗi tin lấy nội dung đầy đủ song song.
  static const int fullTitleConcurrency = 4;

  IotSearchInternalMessageStream({
    IotSearchMessagesFetcher? fetchMessages,
    IotThreadMessagesFetcher? fetchThread,
  }) : _fetchMessages =
           fetchMessages ??
           IotSearchInternalMessagesService().fetchInternalMessages,
       _fetchThread =
           fetchThread ??
           IotReplyInternalMessagesService().fetchInternalMessages;

  final IotSearchMessagesFetcher _fetchMessages;
  final IotThreadMessagesFetcher _fetchThread;
  final Map<String, Future<List<IotInternalMessage>>> _threadCache = {};
  final List<IotDocumentSearchResult> documents = [];

  /// Văn bản đã đọc từ server nhưng chưa hiện (trang tin có nhiều hơn số còn thiếu).
  final List<IotDocumentSearchResult> _pending = [];
  int _nextStartTime = 0;
  bool _serverHasMore = true;

  /// Còn văn bản để "Xem thêm": còn văn bản chờ hiện hoặc server còn trang tin.
  bool get hasMore => _pending.isNotEmpty || _serverHasMore;

  /// Chữ thường, bỏ dấu tiếng Việt, gộp khoảng trắng — dùng để so khớp từ khóa.
  static String foldVietnamese(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      if (rune >= 0x0300 && rune <= 0x036F) continue; // dấu dạng tổ hợp (NFD)
      buffer.write(_vietnameseFold[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Các văn bản trong [message] có số hiệu hoặc trích yếu chứa [keyword].
  /// [keyword] rỗng → trả về mọi văn bản của tin nhắn.
  static List<IotDocumentSearchResult> extractMatchingDocuments(
    IotInternalMessage message,
    String keyword,
  ) {
    final foldedKeyword = foldVietnamese(keyword);
    final results = <IotDocumentSearchResult>[];
    var fileIndex = 0;
    for (final line in message.title.split(RegExp(r'\r\n|\n|\r'))) {
      final match = _documentLineRegExp.firstMatch(line);
      if (match == null) continue;
      final index = fileIndex++;
      final body = match.group(1) ?? '';
      final separator = body.indexOf(':');
      final documentNo = separator < 0
          ? ''
          : body.substring(0, separator).trim();
      final summary = (separator < 0 ? body : body.substring(separator + 1))
          .trim();
      if (foldedKeyword.isNotEmpty &&
          !foldVietnamese(body).contains(foldedKeyword))
        continue;
      results.add(
        IotDocumentSearchResult(
          message: message,
          fileIndex: index,
          documentNo: documentNo,
          summary: summary,
        ),
      );
    }
    return results;
  }

  /// Tìm lần đầu. Lỗi được ném ra để màn hình hiển thị [IotExceptionPage].
  Future<List<IotDocumentSearchResult>> searchDocuments(
    String fromDate,
    String toDate,
    String senders,
    String keyword,
  ) async {
    documents.clear();
    _pending.clear();
    _threadCache.clear();
    _serverHasMore = true;
    _nextStartTime = DateTime.now().millisecondsSinceEpoch;
    await _loadNextPage(fromDate, toDate, senders, keyword);
    return documents;
  }

  /// "Xem thêm" từ màn hình: kiểm tra kết nối rồi gọi [loadNextDocuments].
  /// 0: đã tải thêm, 1: hết dữ liệu, -1: mất kết nối, -2: lỗi mạng (101), -9: lỗi khác.
  Future<int> loadMoreDocuments(
    BuildContext context,
    String fromDate,
    String toDate,
    String senders,
    String keyword,
  ) async {
    if (!hasMore) return 1;
    if (!await IotUtility().checkInternetConnection(context)) return -1;
    return loadNextDocuments(fromDate, toDate, senders, keyword);
  }

  /// Hiện thêm tối đa [pageSize] văn bản. Lỗi → giữ nguyên danh sách đang hiện để thử lại.
  /// 0: đã tải thêm, 1: hết dữ liệu, -2: lỗi mạng (101), -9: lỗi khác.
  Future<int> loadNextDocuments(
    String fromDate,
    String toDate,
    String senders,
    String keyword,
  ) async {
    if (!hasMore) return 1;
    try {
      await _loadNextPage(fromDate, toDate, senders, keyword);
    } on IotException catch (e) {
      return e.code == 101 ? -2 : -9;
    } catch (_) {
      return -9;
    } finally {
      notifyListeners();
    }
    return hasMore ? 0 : 1;
  }

  /// Gom đủ [pageSize] văn bản (dùng trước văn bản dư của lần trước) rồi mới thêm vào [documents].
  Future<void> _loadNextPage(
    String fromDate,
    String toDate,
    String senders,
    String keyword,
  ) async {
    final taken = _takePending(pageSize);
    try {
      for (
        var page = 0;
        page < maxPagesPerLoad && taken.length < pageSize && _serverHasMore;
        page++
      ) {
        final messages = await _fetchMessages(
          fromDate,
          toDate,
          senders,
          keyword,
          _nextStartTime,
        );
        if (messages.isEmpty) {
          _serverHasMore = false;
          break;
        }
        for (final message in await _withFullTitles(messages)) {
          _pending.addAll(extractMatchingDocuments(message, keyword));
        }
        final lastTime = messages.last.time;
        if (lastTime == _nextStartTime) {
          // server trả lại đúng trang cũ → dừng để không lặp vô hạn
          _serverHasMore = false;
          break;
        }
        _nextStartTime = lastTime;
        taken.addAll(_takePending(pageSize - taken.length));
      }
    } catch (_) {
      _pending.insertAll(0, taken); // trả lại để lần "Xem thêm" sau hiện đúng thứ tự
      rethrow;
    }
    documents.addAll(taken);
  }

  List<IotDocumentSearchResult> _takePending(int count) {
    final n = count < _pending.length ? count : _pending.length;
    final taken = _pending.sublist(0, n);
    _pending.removeRange(0, n);
    return taken;
  }

  /// US-4: `title` của API tìm kiếm không chứa đủ các dòng `- VB` → thay bằng nội dung đầy đủ
  /// của đúng tin đó trong chuỗi. Lỗi khi lấy chuỗi → giữ nguyên `title` của kết quả tìm kiếm.
  Future<List<IotInternalMessage>> _withFullTitles(
    List<IotInternalMessage> messages,
  ) async {
    final result = <IotInternalMessage>[];
    for (var i = 0; i < messages.length; i += fullTitleConcurrency) {
      final batch = messages.skip(i).take(fullTitleConcurrency);
      result.addAll(await Future.wait(batch.map(_withFullTitle)));
    }
    return result;
  }

  Future<IotInternalMessage> _withFullTitle(IotInternalMessage message) async {
    final key = '${message.originalCreator}:${message.originalId}';
    try {
      final thread = await (_threadCache[key] ??= _fetchThread(
        message.originalId,
        message.originalCreator,
      ));
      final full = thread.where(
        (m) => m.id == message.id && m.creator == message.creator,
      );
      if (full.isEmpty || full.first.title.isEmpty) return message;
      return IotInternalMessage(
        originalId: message.originalId,
        originalCreator: message.originalCreator,
        id: message.id,
        creator: message.creator,
        title: full.first.title,
        time: message.time,
        status: message.status,
        creatorName: message.creatorName,
        emotion: message.emotion,
        notificationId: message.notificationId,
        hasFile: (full.first.hasFile == 'Y' || message.hasFile == 'Y')
            ? 'Y'
            : 'N',
        groupName: message.groupName,
      );
    } catch (_) {
      _threadCache.remove(key);
      return message;
    }
  }
}
