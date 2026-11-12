import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/view/im/search/result_internal_messages_page.dart';
import 'package:dngmsp/app/viewmodel/im/search/search_internal_message_stream.dart';
import 'package:flutter_test/flutter_test.dart';

IotInternalMessage _message(int id, int time, String title) =>
    IotInternalMessage(
      originalId: id,
      originalCreator: 'u',
      id: id,
      creator: 'u',
      title: title,
      time: time,
      creatorName: 'User',
      hasFile: 'Y',
    );

/// Chuỗi tin trả lại đúng tin tìm được (title không đổi) — test không gọi mạng thật.
Future<List<IotInternalMessage>> _sameThread(int id, String creator) async =>
    <IotInternalMessage>[];

const _title =
    'Kính gửi các phòng, lưu ý tín dụng\r\n'
    '- VB 5030/NHCS-TDNN : V/v phối hợp thu hồi nợ\r\n'
    '- VB 100/QĐ-HĐQT : Quyết định ban hành quy chế Tín Dụng\n'
    '- VB  : trích yếu không số hiệu';

void main() {
  group('US-3 lọc văn bản theo từ khóa', () {
    test('bỏ dấu, chữ thường, gộp khoảng trắng', () {
      expect(
        IotSearchInternalMessageStream.foldVietnamese('  Quyết   ĐỊNH '),
        'quyet dinh',
      );
      // Dạng tổ hợp (NFD): "e" + dấu mũ + dấu sắc.
      expect(
        IotSearchInternalMessageStream.foldVietnamese('Quye\u0302\u0301t'),
        'quyet',
      );
    });

    test('chỉ trả về văn bản có tên khớp, không trả dòng tin nhắn', () {
      final docs = IotSearchInternalMessageStream.extractMatchingDocuments(
        _message(1, 10, _title),
        'tín dụng',
      );
      expect(docs, hasLength(1));
      expect(docs.single.documentNo, '100/QĐ-HĐQT');
      expect(docs.single.summary, 'Quyết định ban hành quy chế Tín Dụng');
      expect(docs.single.fileIndex, 1);
    });

    test('khớp không dấu và theo số hiệu', () {
      final byName = IotSearchInternalMessageStream.extractMatchingDocuments(
        _message(1, 10, _title),
        'phoi hop',
      );
      expect(byName.single.documentNo, '5030/NHCS-TDNN');
      expect(byName.single.fileIndex, 0);

      final byNumber = IotSearchInternalMessageStream.extractMatchingDocuments(
        _message(1, 10, _title),
        '100/qđ',
      );
      expect(byNumber.single.fileIndex, 1);
    });

    test('từ khóa rỗng trả mọi văn bản; tin không có VB trả rỗng', () {
      final all = IotSearchInternalMessageStream.extractMatchingDocuments(
        _message(1, 10, _title),
        '',
      );
      expect(all.map((d) => d.fileIndex), [0, 1, 2]);
      expect(all[2].documentNo, '');
      expect(all[2].summary, 'trích yếu không số hiệu');

      expect(
        IotSearchInternalMessageStream.extractMatchingDocuments(
          _message(2, 10, 'Tín dụng tháng này tăng'),
          'tín dụng',
        ),
        isEmpty,
      );
    });
  });

  group('US-3 phân trang', () {
    test('trang đầu không có văn bản khớp → tự đọc trang kế tiếp', () async {
      final startTimes = <int>[];
      final pages = [
        [_message(1, 900, 'Tín dụng không có VB'), _message(2, 800, 'abc')],
        [_message(3, 700, '- VB 7/TD : Tín dụng quý 3')],
      ];
      final stream = IotSearchInternalMessageStream(
        fetchThread: _sameThread,
        fetchMessages: (from, to, senders, content, startTime) async {
          startTimes.add(startTime);
          return startTimes.length <= pages.length
              ? pages[startTimes.length - 1]
              : <IotInternalMessage>[];
        },
      );

      final docs = await stream.searchDocuments('', '', '', 'tín dụng');

      expect(docs.single.documentNo, '7/TD');
      expect(startTimes, hasLength(2));
      expect(
        startTimes[1],
        800,
      ); // trang 2 bắt đầu từ thời gian tin cuối trang 1
      expect(stream.hasMore, isTrue);
    });

    test('server hết dữ liệu → hasMore = false', () async {
      final stream = IotSearchInternalMessageStream(
        fetchThread: _sameThread,
        fetchMessages: (a, b, c, d, e) async => <IotInternalMessage>[],
      );
      final docs = await stream.searchDocuments('', '', '', 'x');
      expect(docs, isEmpty);
      expect(stream.hasMore, isFalse);
    });

    test('không đọc quá số trang giới hạn trong một lần tải', () async {
      var calls = 0;
      final stream = IotSearchInternalMessageStream(
        fetchThread: _sameThread,
        fetchMessages: (a, b, c, d, e) async {
          calls++;
          return [_message(calls, 1000 - calls, 'không có văn bản')];
        },
      );
      await stream.searchDocuments('', '', '', 'x');
      expect(calls, IotSearchInternalMessageStream.maxPagesPerLoad);
      expect(stream.hasMore, isTrue);
    });

    test('lỗi lần tìm đầu được ném ra cho màn hình', () async {
      final stream = IotSearchInternalMessageStream(
        fetchThread: _sameThread,
        fetchMessages: (a, b, c, d, e) async => throw IotException(code: 408),
      );
      expect(
        () => stream.searchDocuments('', '', '', 'x'),
        throwsA(isA<IotException>()),
      );
    });
  });

  group('US-4 tra cứu mọi văn bản trong tin', () {
    test(
      'title tìm kiếm chỉ có dòng đầu → dùng nội dung đầy đủ của chuỗi',
      () async {
        final threadCalls = <String>[];
        final stream = IotSearchInternalMessageStream(
          fetchMessages: (a, b, c, d, startTime) async => startTime > 5000
              ? [
                  // API tìm kiếm chỉ trả dòng đầu của tin.
                  _message(1, 900, 'Kính gửi các phòng, lưu ý tín dụng'),
                ]
              : <IotInternalMessage>[],
          fetchThread: (originalId, originalCreator) async {
            threadCalls.add('$originalCreator:$originalId');
            return [
              _message(9, 100, '- VB 1/X : tin khác trong chuỗi, Tín dụng'),
              _message(1, 900, _title),
            ];
          },
        );

        final docs = await stream.searchDocuments('', '', '', 'tín dụng');

        // Chỉ văn bản dòng 3 (file thứ 2) của đúng tin id=1, không lấy tin id=9.
        expect(docs, hasLength(1));
        expect(docs.single.message.id, 1);
        expect(docs.single.documentNo, '100/QĐ-HĐQT');
        expect(docs.single.fileIndex, 1);
        expect(threadCalls, ['u:1']);
      },
    );

    test('nhiều tin cùng chuỗi chỉ lấy chuỗi một lần', () async {
      var threadCalls = 0;
      IotInternalMessage inThread(int id, int time) => IotInternalMessage(
        originalId: 7,
        originalCreator: 'u',
        id: id,
        creator: 'u',
        title: 'dòng đầu',
        time: time,
        creatorName: 'User',
      );
      final stream = IotSearchInternalMessageStream(
        fetchMessages: (a, b, c, d, startTime) async => startTime > 5000
            ? [inThread(1, 900), inThread(2, 800)]
            : <IotInternalMessage>[],
        fetchThread: (id, creator) async {
          threadCalls++;
          return [
            IotInternalMessage(
              originalId: 7,
              originalCreator: 'u',
              id: 1,
              creator: 'u',
              title: 'a\n- VB 1/A : Kế hoạch',
              time: 900,
              creatorName: 'User',
            ),
            IotInternalMessage(
              originalId: 7,
              originalCreator: 'u',
              id: 2,
              creator: 'u',
              title: 'b\n- VB 2/B : Kế hoạch',
              time: 800,
              creatorName: 'User',
            ),
          ];
        },
      );

      final docs = await stream.searchDocuments('', '', '', 'kế hoạch');

      expect(docs.map((d) => d.documentNo), ['1/A', '2/B']);
      expect(threadCalls, 1);
    });

    test('lỗi lấy chuỗi → vẫn dùng title của kết quả tìm kiếm', () async {
      final stream = IotSearchInternalMessageStream(
        fetchMessages: (a, b, c, d, startTime) async => startTime > 5000
            ? [_message(1, 900, '- VB 5/K : Tín dụng')]
            : <IotInternalMessage>[],
        fetchThread: (id, creator) async => throw IotException(code: 408),
      );

      final docs = await stream.searchDocuments('', '', '', 'tín dụng');

      expect(docs.single.documentNo, '5/K');
    });
  });

  test('tên file tạm bỏ phần đường dẫn', () {
    expect(iotSafeTempFileName('VB 623.pdf'), 'VB 623.pdf');
    expect(iotSafeTempFileName('../../shared_prefs/x.xml'), 'x.xml');
    expect(iotSafeTempFileName(r'C:\a\b.pdf'), 'b.pdf');
    expect(iotSafeTempFileName('..'), 'van_ban');
    expect(iotSafeTempFileName(''), 'van_ban');
  });
}
