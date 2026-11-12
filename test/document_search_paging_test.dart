import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/resource/var/iot_screen.dart';
import 'package:dngmsp/app/view/im/search/result_internal_messages_page.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/search/search_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// US-10: màn kết quả tìm văn bản (lọc người gửi/nhận + thời gian) hiện 20 văn bản,
/// cuộn tới đáy không tự tải, nhấn "Xem thêm" mới tải 20 văn bản tiếp theo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (call) async => ['wifi'],
        );
  });

  testWidgets('20 văn bản, Xem thêm tải tiếp 20', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final senders = <String>[];
    final froms = <String>[];
    var calls = 0;
    final stream = IotSearchInternalMessageStream(
      fetchThread: (id, creator) async => <IotInternalMessage>[],
      fetchMessages: (from, to, sender, content, startTime) async {
        calls++;
        senders.add(sender);
        froms.add(from);
        if (calls > 5) return <IotInternalMessage>[];
        return [
          for (var i = 0; i < 10; i++)
            IotInternalMessage(
              originalId: calls * 100 + i,
              originalCreator: 'u',
              id: calls * 100 + i,
              creator: 'u',
              title: 'tin\n- VB ${(calls - 1) * 10 + i}/TD : Kế hoạch',
              time: 1000000 - calls * 100 - i,
              creatorName: 'User',
              hasFile: 'Y',
            ),
        ];
      },
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: stream),
          ChangeNotifierProvider(create: (_) => IotListInternalMessageStream()),
          ChangeNotifierProvider(create: (_) => IotListAutoReportStream()),
        ],
        child: IotScreenUtilInit(
          builder: (context, _) => MaterialApp(
            home: IotResultInternalMessagesPage(
              '1/11/2026',
              '12/11/2026',
              'u1;u2',
              '',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(stream.documents, hasLength(20));
    expect(calls, 2);
    expect(senders, everyElement('u1;u2'));
    expect(froms, everyElement('1/11/2026'));

    // Cuộn tới đáy: không tự tải thêm, chỉ hiện nút "Xem thêm".
    final more = find.text('Xem thêm');
    await tester.scrollUntilVisible(more, 300);
    await tester.pumpAndSettle();
    expect(more, findsOneWidget);
    expect(find.text('VB 19/TD'), findsOneWidget);
    expect(stream.documents, hasLength(20));
    expect(calls, 2);

    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(stream.documents, hasLength(40));
    expect(calls, 4);

    // Lần cuối: server còn 10 văn bản rồi hết → nút biến mất.
    await tester.scrollUntilVisible(more, 300);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(stream.documents, hasLength(50));
    expect(stream.hasMore, isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.text('VB 49/TD'), findsOneWidget);
    expect(more, findsNothing);
  });
}
