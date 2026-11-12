import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/var/iot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sizes {
  double font = 0, w = 0, h = 0, longSide = 0, shortSide = 0, sh = 0;
}

Future<_Sizes> _measure(WidgetTester tester, Size screen) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  final sizes = _Sizes();
  await tester.pumpWidget(
    IotScreenUtilInit(
      builder: (context, _) => MaterialApp(
        home: Builder(
          builder: (context) {
            sizes
              ..font = SP_COMMON_FONT_SIZE.sp
              ..w = 100.w
              ..h = 100.h
              ..longSide = 0.12.longSide
              ..shortSide = 0.1.shortSide
              ..sh = 0.12.sh;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return sizes;
}

void main() {
  testWidgets(
    'dọc: giữ nguyên cách tính cũ (khung 1080x1920, chữ theo chiều rộng)',
    (tester) async {
      addTearDown(tester.view.reset);
      final portrait = await _measure(tester, const Size(360, 780));

      expect(portrait.font, moreOrLessEquals(SP_COMMON_FONT_SIZE * 360 / 1080));
      expect(portrait.w, moreOrLessEquals(100 * 360 / 1080));
      expect(portrait.h, moreOrLessEquals(100 * 780 / 1920));
      expect(portrait.longSide, moreOrLessEquals(portrait.sh)); // = 0.12.sh cũ
      expect(portrait.shortSide, moreOrLessEquals(0.1 * 360)); // = 0.1.sw cũ
    },
  );

  testWidgets('ngang: chữ và kích thước item giống dọc, không phóng gấp đôi', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final portrait = await _measure(tester, const Size(360, 780));
    final landscape = await _measure(tester, const Size(780, 360));

    // Trước US-5: chữ ngang = 44 * 780/1080 ≈ 31.8 (gấp 2,17 lần dọc).
    expect(landscape.font, moreOrLessEquals(portrait.font));
    expect(landscape.longSide, moreOrLessEquals(portrait.longSide));
    expect(landscape.shortSide, moreOrLessEquals(portrait.shortSide));
    // Khung đổi chiều → .w/.h lệch so với dọc không quá 25% (trước đây .w gấp 2,17, .h còn 0,46).
    expect(landscape.w / portrait.w, inInclusiveRange(0.75, 1.25));
    expect(landscape.h / portrait.h, inInclusiveRange(0.75, 1.25));
  });

  testWidgets('xoay màn hình khi app đang chạy: tính lại theo hướng mới', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await _measure(tester, const Size(360, 780));
    tester.view.physicalSize = const Size(780, 360);
    await tester.pump();

    expect(ScreenUtil().orientation, Orientation.landscape);
    expect(
      SP_COMMON_FONT_SIZE.sp,
      moreOrLessEquals(SP_COMMON_FONT_SIZE * 360 / 1080),
    );
    expect(100.w, moreOrLessEquals(100 * 780 / 1920));
  });

  test('khung thiết kế theo hướng', () {
    expect(iotDesignSize(Orientation.portrait), const Size(1080, 1920));
    expect(iotDesignSize(Orientation.landscape), const Size(1920, 1080));
  });
}
