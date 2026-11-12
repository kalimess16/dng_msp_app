import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/view/im/reply/reply_internal_message_page.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

IotInternalMessage _message(int id, int time, String title) =>
    IotInternalMessage(
      originalId: 1,
      originalCreator: 'u',
      id: id,
      creator: 'u',
      title: title,
      time: time,
      creatorName: 'User',
    );

/// Cấu trúc giống màn xem tin nhắn: cuộn ngoài `reverse` chứa ListView `reverse` co theo nội dung.
Widget _replyLikeScroll(GlobalKey key, double documentHeight) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        reverse: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView(
              shrinkWrap: true,
              reverse: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Container(key: key, height: documentHeight, color: Colors.blue),
                const SizedBox(height: 900), // tin cũ hơn nằm phía trên
              ],
            ),
            const SizedBox(height: 120), // trả lời mới nhận
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('US-2 nhận biết thông báo văn bản', () {
    test('tin có dòng "- VB … :" là thông báo văn bản', () {
      expect(
        IotReplyInternalMessageStream.isDocumentNotification(
          'Kính gửi các phòng\n- VB 5030/NHCS-TDNN : V/v phối hợp',
        ),
        isTrue,
      );
      expect(
        IotReplyInternalMessageStream.isDocumentNotification(
          'Đề nghị các anh chị kiểm tra VB cũ',
        ),
        isFalse,
      );
    });

    test('chọn thông báo văn bản mới nhất theo thời gian', () {
      final messages = [
        _message(1, 100, '- VB 1/QĐ : cũ'),
        _message(2, 300, 'Đã nhận'),
        _message(3, 200, '- VB 2/QĐ : mới'),
      ];
      expect(
        IotReplyInternalMessageStream.latestDocumentNotificationIndex(messages),
        2,
      );
      expect(
        IotReplyInternalMessageStream.latestDocumentNotificationIndex([
          _message(1, 1, 'Xin chào'),
        ]),
        isNull,
      );
    });
  });

  group('US-2 cuộn tới tiêu đề', () {
    testWidgets('tin văn bản cao hơn màn hình: mép trên lên đầu màn hình', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(_replyLikeScroll(key, 1500));

      // Mặc định (reverse) đang ở cuối: tiêu đề nằm ngoài màn hình.
      expect(tester.getTopLeft(find.byKey(key)).dy, lessThan(0));

      iotRevealTopOfScrollItem(key.currentContext!);
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(key)).dy, moreOrLessEquals(0));
    });

    testWidgets('tin văn bản vừa màn hình: tiêu đề hiển thị trọn', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(_replyLikeScroll(key, 300));

      iotRevealTopOfScrollItem(key.currentContext!);
      await tester.pumpAndSettle();

      final top = tester.getTopLeft(find.byKey(key)).dy;
      expect(top, greaterThanOrEqualTo(0));
      expect(tester.getBottomLeft(find.byKey(key)).dy, lessThanOrEqualTo(780));
    });
  });

  group('US-9 giữ vị trí đọc khi xoay', () {
    final cards = {
      'u:1': const Rect.fromLTWH(0, 100, 300, 400), // tin mới (trên)
      'u:2': const Rect.fromLTWH(0, 520, 300, 200), // tin cũ (dưới)
    };

    test('mép trên vùng nhìn nằm giữa tin → nhớ đúng tin và tỉ lệ đã đọc', () {
      final anchor = iotFindReadingAnchor(200, cards)!;
      expect(anchor.id, 'u:1');
      expect(anchor.fraction, closeTo(0.25, 0.0001));
    });

    test('mép trên rơi vào khoảng trống giữa hai tin → lấy tin ngay dưới', () {
      final anchor = iotFindReadingAnchor(510, cards)!;
      expect(anchor.id, 'u:2');
      expect(anchor.fraction, 0);
    });

    test('không có tin nào → null', () {
      expect(iotFindReadingAnchor(0, const {}), isNull);
    });
  });
}
