import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/var/iot_screen.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const double _statusBar = 24;
const double _gestureBar = 24; // thanh cử chỉ (vạch ngang)
const double _buttonBar = 48; // thanh 3 nút

Future<void> _pumpPage(
  WidgetTester tester,
  Size screen, {
  double bottomInset = _gestureBar,
  double textScale = 1,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  final padding = FakeViewPadding(top: _statusBar, bottom: bottomInset);
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IotListInternalMessageStream()),
        ChangeNotifierProvider(create: (_) => IotListAutoReportStream()),
      ],
      child: IotScreenUtilInit(
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: IotAppBar().build(context, false, 'KẾT QUẢ TÌM VĂN BẢN'),
              body: const SizedBox.expand(),
              bottomNavigationBar: IotBottomNavigatorBar(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _labels = ['IOT', 'Số liệu định kỳ', 'Thông tin'];

/// Khối icon + nhãn của các mục (hợp các hình chữ nhật).
Rect _contentRect(WidgetTester tester) {
  Rect? rect;
  for (final label in _labels) {
    final item = find.ancestor(
      of: find.text(label),
      matching: find.byType(FittedBox),
    );
    final r = tester.getRect(
      find
          .descendant(
            of: item.first,
            matching: find.byWidgetPredicate((w) => w is Flex),
          )
          .first,
    );
    rect = rect == null ? r : rect.expandToInclude(r);
  }
  return rect!;
}

void _expectAppBar(WidgetTester tester, Orientation o) {
  expect(
    tester.getSize(find.byType(AppBar)).height,
    _statusBar + iotToolbarHeight(o),
  );
}

void _expectGestureBarCentered(WidgetTester tester, Size screen) {
  final bar = tester.getRect(find.byType(IotBottomNavigatorBar));
  final content = _contentRect(tester);
  final topGap = content.top - bar.top;
  final bottomGap = bar.bottom - content.bottom;

  // US-7: nội dung nằm giữa phần xanh (lệch ≤ 2dp do làm tròn chữ).
  expect((topGap - bottomGap).abs(), lessThanOrEqualTo(2));
  // Không chạm vạch cử chỉ (US-5).
  expect(bottomGap, greaterThanOrEqualTo(IOT_GESTURE_HANDLE_CLEARANCE - 1));
  expect(bar.bottom, screen.height);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('dọc, thanh cử chỉ: icon + nhãn căn giữa, thanh gọn', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const screen = Size(360, 780);
    await _pumpPage(tester, screen);
    _expectAppBar(tester, Orientation.portrait);
    _expectGestureBarCentered(tester, screen);
    // Trước US-6: 56 + 24 = 80.
    expect(
      tester.getSize(find.byType(IotBottomNavigatorBar)).height,
      lessThan(80),
    );
  });

  testWidgets('ngang, thanh cử chỉ: căn giữa, icon và nhãn cùng hàng', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const screen = Size(780, 360);
    await _pumpPage(tester, screen);
    _expectAppBar(tester, Orientation.landscape);
    _expectGestureBarCentered(tester, screen);
    expect(
      tester.getSize(find.byType(IotBottomNavigatorBar)).height,
      lessThan(64), // US-6: 40 + 24
    );
    final icon = tester.getRect(find.byIcon(Icons.home_outlined));
    final label = tester.getRect(find.text('IOT'));
    expect(label.left, greaterThan(icon.right));
  });

  testWidgets('thanh 3 nút: nội dung nằm trên vùng nút hệ thống', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const screen = Size(360, 780);
    await _pumpPage(tester, screen, bottomInset: _buttonBar);
    final content = _contentRect(tester);
    expect(content.bottom, lessThanOrEqualTo(screen.height - _buttonBar));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chữ hệ thống 200%: không tràn, vẫn trong khối nội dung', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const screen = Size(360, 780);
    await _pumpPage(tester, screen, textScale: 2);
    expect(tester.takeException(), isNull);
    final content = _contentRect(tester);
    final bar = tester.getRect(find.byType(IotBottomNavigatorBar));
    expect(
      bar.bottom - content.bottom,
      greaterThanOrEqualTo(IOT_GESTURE_HANDLE_CLEARANCE - 1),
    );
  });

  test('bố cục: thanh cử chỉ căn giữa, thanh 3 nút đặt trên vùng nút', () {
    final gesture = iotBottomBarLayout(Orientation.portrait, 24);
    expect(gesture.top, gesture.bottom);
    expect(gesture.bottom, greaterThanOrEqualTo(IOT_GESTURE_HANDLE_CLEARANCE));

    final buttons = iotBottomBarLayout(Orientation.portrait, 48);
    expect(buttons.bottom, 48 + 8);
    expect(buttons.top, 8);

    final none = iotBottomBarLayout(Orientation.landscape, 0);
    expect(none.top, none.bottom);
  });

  testWidgets(
    'US-9 xoay màn hình: thanh dưới giữ đúng mục của trang đang xem',
    (tester) async {
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      final navigatorKey = GlobalKey<NavigatorState>();

      Widget page(int tab) => Builder(
        builder: (context) {
          // Giống các trang thật: gán mục được chọn ngay trong build().
          IotBottomNavigatorBar.selectedIotBottomNavigatorBar = tab;
          return Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: IotBottomNavigatorBar(),
          );
        },
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => IotListInternalMessageStream(),
            ),
            ChangeNotifierProvider(create: (_) => IotListAutoReportStream()),
          ],
          child: IotScreenUtilInit(
            builder: (context, _) =>
                MaterialApp(navigatorKey: navigatorKey, home: page(0)),
          ),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => page(2)),
      );
      await tester.pumpAndSettle();

      Color labelColor(String text) =>
          tester.widget<Text>(find.text(text).last).style!.color!;
      expect(labelColor('Thông tin'), IOT_FG_COLOR);

      // Xoay: cả trang home (bên dưới) lẫn trang đang xem build lại.
      tester.view.physicalSize = const Size(780, 360);
      await tester.pumpAndSettle();
      expect(labelColor('Thông tin'), IOT_FG_COLOR);
      expect(labelColor('IOT'), isNot(IOT_FG_COLOR));
    },
  );
}
