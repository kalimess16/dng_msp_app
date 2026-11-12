import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dngmsp/app/resource/var/iot_screen.dart';
import 'package:dngmsp/app/service/im/pdf_preview_service.dart';
import 'package:dngmsp/app/view/im/reply/reply_download_file_widget.dart';
import 'package:dngmsp/app/view/im/reply/reply_internal_message_page.dart';
import 'package:dngmsp/app/viewmodel/im/reply/reply_internal_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const double width = 340;
  const double maxHeight = 270;

  double aspect(Size s) => s.width / s.height;

  test('ảnh máy scan 715x463 giữ đúng tỉ lệ, rộng hết khung', () {
    const image = Size(715, 463);
    final box = iotPreviewBoxSize(
      availableWidth: width,
      imageSize: image,
      maxHeight: maxHeight,
    );
    expect(box.width, width);
    expect(aspect(box), closeTo(aspect(image), 0.001));
  });

  test('ảnh dải dọc 328x1010 (máy photo) không bị bóp dẹt', () {
    const image = Size(328, 1010);
    final box = iotPreviewBoxSize(
      availableWidth: width,
      imageSize: image,
      maxHeight: maxHeight,
    );
    expect(box.height, maxHeight);
    expect(box.width, lessThan(width));
    expect(aspect(box), closeTo(aspect(image), 0.001));
  });

  test('ảnh phóng vùng bút phê 1100x733 giữ tỉ lệ 1,5:1', () {
    const image = Size(1100, 733);
    final box = iotPreviewBoxSize(
      availableWidth: width,
      imageSize: image,
      maxHeight: maxHeight,
    );
    expect(aspect(box), closeTo(aspect(image), 0.001));
    expect(box.height, lessThanOrEqualTo(maxHeight));
  });

  test('chưa đọc được kích thước thì dùng tỉ lệ mặc định', () {
    final box = iotPreviewBoxSize(
      availableWidth: width,
      imageSize: null,
      maxHeight: maxHeight,
    );
    expect(aspect(box), closeTo(IOT_PREVIEW_DEFAULT_ASPECT, 0.001));
  });

  group('US-8 chiều cao tối đa theo hướng màn hình', () {
    test('dọc: giữ 32% cạnh dài như trước', () {
      // 360x780: khung ~330 rộng → ảnh chuẩn cao ~214 < 0,32 × 780 = 249,6.
      expect(
        iotPreviewMaxHeight(availableWidth: 330, screenLongSide: 780),
        closeTo(0.32 * 780, 0.001),
      );
    });

    test(
      'ngang: ảnh văn bản trải hết chiều rộng, không co theo chiều cao màn',
      () {
        const available = 700.0;
        final maxHeight = iotPreviewMaxHeight(
          availableWidth: available,
          screenLongSide: 780,
        );
        // Trước US-8: 0,32 × 360 ≈ 115 → ảnh 715x463 chỉ rộng ~178 / 700.
        for (final image in const [Size(715, 463), Size(1100, 733)]) {
          final box = iotPreviewBoxSize(
            availableWidth: available,
            imageSize: image,
            maxHeight: maxHeight,
          );
          expect(box.width, closeTo(available, 0.001));
          expect(aspect(box), closeTo(aspect(image), 0.001));
        }
        // Ảnh dải dọc vẫn bị giới hạn chiều cao, không dài quá mức.
        final strip = iotPreviewBoxSize(
          availableWidth: available,
          imageSize: const Size(328, 1010),
          maxHeight: maxHeight,
        );
        expect(strip.height, closeTo(maxHeight, 0.001));
        expect(strip.width, lessThan(available / 2));
      },
    );
  });

  Future<String> pngBase64(int w, int h) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = Colors.blue,
    );
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return base64Encode(data!.buffer.asUint8List());
  }

  for (final dims in const <List<int>>[
    <int>[715, 463],
    <int>[328, 1010],
  ]) {
    testWidgets(
      'widget xem trước ${dims[0]}x${dims[1]} giữ tỉ lệ trên điện thoại',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        // Ảnh dải dọc sẽ kích hoạt tạo lại ảnh: cho bước cache lỗi ngay để không gọi mạng.
        IotPdfPreviewService.cacheRoot = () async =>
            throw UnsupportedError('không tải PDF trong test');
        final data = (await tester.runAsync(
          () => pngBase64(dims[0], dims[1]),
        ))!;

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(1080, 1920),
            builder: (_, __) => MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    IotReplyDownloadFileWidget(
                      'u',
                      1,
                      data,
                      'VB 623.pdf',
                      'application/pdf',
                      0,
                      0,
                      null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pumpAndSettle();

        final box = tester.getSize(find.byType(Image));
        expect(box.width / box.height, closeTo(dims[0] / dims[1], 0.01));
        expect(box.width, lessThanOrEqualTo(360));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('US-8 widget xem trước 1100x733 khi quay ngang rộng hết khung', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2340, 1080);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    IotPdfPreviewService.cacheRoot = () async =>
        throw UnsupportedError('không tải PDF trong test');
    final data = (await tester.runAsync(() => pngBase64(1100, 733)))!;

    await tester.pumpWidget(
      IotScreenUtilInit(
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                IotReplyDownloadFileWidget(
                  'u',
                  1,
                  data,
                  'VB 623.pdf',
                  'application/pdf',
                  0,
                  0,
                  null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    final box = tester.getSize(find.byType(Image));
    // Màn ngang 780dp, khung trừ lề ~ 750dp. Trước US-8 ảnh chỉ rộng ~173dp.
    expect(box.width, greaterThan(700));
    expect(box.width / box.height, closeTo(1100 / 733, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'US-8 ngang 2 cột: giữ thứ tự file, mỗi ảnh nửa khung và xem trọn',
    (tester) async {
      tester.view.physicalSize = const Size(
        2193,
        1233,
      ); // 731x411dp như Pixel ngang
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      IotPdfPreviewService.cacheRoot = () async =>
          throw UnsupportedError('không tải PDF trong test');
      final data = (await tester.runAsync(() => pngBase64(1100, 733)))!;

      await tester.pumpWidget(
        IotScreenUtilInit(
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  iotFileColumns(
                    itemCount: 3,
                    columns: 2,
                    itemBuilder: (context, i) => KeyedSubtree(
                      key: ValueKey('file-$i'),
                      child: IotReplyDownloadFileWidget(
                        'u',
                        1,
                        data,
                        'VB $i.pdf',
                        'application/pdf',
                        i,
                        0,
                        null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      final r0 = tester.getRect(find.byKey(const ValueKey('file-0')));
      final r1 = tester.getRect(find.byKey(const ValueKey('file-1')));
      final r2 = tester.getRect(find.byKey(const ValueKey('file-2')));
      // Thứ tự: 0 | 1 trên cùng hàng, 2 xuống hàng dưới bên trái.
      expect(r0.top, r1.top);
      expect(r1.left, greaterThan(r0.left));
      expect(r2.top, greaterThan(r0.top));
      expect(r2.left, r0.left);

      final images = tester.getRect(find.byType(Image).first);
      // Nửa khung (~365dp) và thấp hơn vùng nhìn ngang (~220dp + lề) → xem trọn một ảnh.
      expect(images.width, inInclusiveRange(300, 366));
      expect(images.height, lessThan(250));
      expect(tester.takeException(), isNull);
    },
  );

  test('tách số hiệu theo thứ tự dòng tiêu đề VB', () {
    const title =
        'Kính gửi:\n'
        '- VB 5030/NHCS-TDNN : V/v phối hợp\r\n'
        '- VB  : trích yếu không số hiệu\n'
        'Nội dung khác\n'
        '- VB 100/QĐ-HĐQT : quyết định';
    expect(
      IotReplyInternalMessageStream.extractDocumentNumbers(title),
      <String>['5030/NHCS-TDNN', '', '100/QĐ-HĐQT'],
    );
  });

  test('nhận biết ảnh server có nhãn VB (xám) và ảnh dải dọc cũ', () {
    IotPixels solid(int w, int h, int v) => IotPixels(
      w,
      h,
      Uint8List.fromList(List<int>.filled(w * h * 4, v)),
      bgra: false,
    );
    expect(IotPdfPreviewService.hasEofficeLabel(solid(200, 60, 128)), isTrue);
    expect(IotPdfPreviewService.hasEofficeLabel(solid(200, 60, 255)), isFalse);
    expect(
      IotPdfPreviewService.isLegacyRotatedPreview(solid(32, 101, 255)),
      isTrue,
    );
    expect(
      IotPdfPreviewService.isLegacyRotatedPreview(solid(71, 46, 255)),
      isFalse,
    );
  });

  test('đọc được kích thước ảnh PNG thật', () async {
    // PNG 1x1 hợp lệ.
    final bytes = Uint8List.fromList(<int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0xF0,
      0x1F,
      0x00,
      0x05,
      0x00,
      0x01,
      0xFF,
      0x89,
      0x99,
      0x3D,
      0x1D,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);
    final size = await iotReadImageSize(bytes);
    expect(size, const Size(1, 1));
    expect(await iotReadImageSize(Uint8List.fromList(<int>[1, 2, 3])), isNull);
  });
}
