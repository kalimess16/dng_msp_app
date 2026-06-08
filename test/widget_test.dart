// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dngmsp/app/resource/string/login_strings.dart';
import 'package:dngmsp/app/view/main/login_page.dart';
import 'package:dngmsp/main.dart';

void main() {
  test('MainApp can be constructed', () {
    expect(MainApp(preferences: <String>[]), isA<MainApp>());
  });

  testWidgets('Login page fits compact screens with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1080, 1920),
        builder: (context, child) {
          return MaterialApp(
            home: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: IotLoginPage(),
            ),
          );
        },
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(LOGIN_WITH_GOOGLE_TITLE), findsOneWidget);
  });
}
