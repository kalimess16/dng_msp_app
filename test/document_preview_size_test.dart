import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dngmsp/app/service/im/pdf_preview_service.dart';
import 'package:dngmsp/app/view/im/reply/reply_download_file_widget.dart';
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
        availableWidth: width, imageSize: image, maxHeight: maxHeight);
    expect(box.width, width);
    expect(aspect(box), closeTo(aspect(image), 0.001));
  });

  test('ảnh dải dọc 328x1010 (máy photo) không bị bóp dẹt', () {
    const image = Size(328, 1010);
    final box = iotPreviewBoxSize(
        availableWidth: width, imageSize: image, maxHeight: maxHeight);
    expect(box.height, maxHeight);
    expect(box.width, lessThan(width));
    expect(aspect(box), closeTo(aspect(image), 0.001));
  });

  test('ảnh phóng vùng bút phê 1100x733 giữ tỉ lệ 1,5:1', () {
    const image = Size(1100, 733);
    final box = iotPreviewBoxSize(
        availableWidth: width, imageSize: image, maxHeight: maxHeight);
    expect(aspect(box), closeTo(aspect(image), 0.001));
    expect(box.height, lessThanOrEqualTo(maxHeight));
  });

  test('chưa đọc được kích thước thì dùng tỉ lệ mặc định', () {
    final box = iotPreviewBoxSize(
        availableWidth: width, imageSize: null, maxHeight: maxHeight);
    expect(aspect(box), closeTo(IOT_PREVIEW_DEFAULT_ASPECT, 0.001));
  });

  Future<String> pngBase64(int w, int h) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = Colors.blue);
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return base64Encode(data!.buffer.asUint8List());
  }

  for (final dims in const <List<int>>[
    <int>[715, 463],
    <int>[328, 1010],
  ]) {
    testWidgets('widget xem trước ${dims[0]}x${dims[1]} giữ tỉ lệ trên điện thoại',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // Ảnh dải dọc sẽ kích hoạt tạo lại ảnh: cho bước cache lỗi ngay để không gọi mạng.
      IotPdfPreviewService.cacheRoot =
          () async => throw UnsupportedError('không tải PDF trong test');
      final data = (await tester.runAsync(() => pngBase64(dims[0], dims[1])))!;

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(1080, 1920),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: ListView(children: [
              IotReplyDownloadFileWidget('u', 1, data, 'VB 623.pdf',
                  'application/pdf', 0, 0, null),
            ]),
          ),
        ),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pumpAndSettle();

      final box = tester.getSize(find.byType(Image));
      expect(box.width / box.height, closeTo(dims[0] / dims[1], 0.01));
      expect(box.width, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    });
  }

  test('tách số hiệu theo thứ tự dòng tiêu đề VB', () {
    const title = 'Kính gửi:\n'
        '- VB 5030/NHCS-TDNN : V/v phối hợp\r\n'
        '- VB  : trích yếu không số hiệu\n'
        'Nội dung khác\n'
        '- VB 100/QĐ-HĐQT : quyết định';
    expect(IotReplyInternalMessageStream.extractDocumentNumbers(title),
        <String>['5030/NHCS-TDNN', '', '100/QĐ-HĐQT']);
  });

  test('nhận biết ảnh server có nhãn VB (xám) và ảnh dải dọc cũ', () {
    IotPixels solid(int w, int h, int v) => IotPixels(
        w, h, Uint8List.fromList(List<int>.filled(w * h * 4, v)),
        bgra: false);
    expect(IotPdfPreviewService.hasEofficeLabel(solid(200, 60, 128)), isTrue);
    expect(IotPdfPreviewService.hasEofficeLabel(solid(200, 60, 255)), isFalse);
    expect(IotPdfPreviewService.isLegacyRotatedPreview(solid(32, 101, 255)),
        isTrue);
    expect(IotPdfPreviewService.isLegacyRotatedPreview(solid(71, 46, 255)),
        isFalse);
  });

  test('đọc được kích thước ảnh PNG thật', () async {
    // PNG 1x1 hợp lệ.
    final bytes = Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
      0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    final size = await iotReadImageSize(bytes);
    expect(size, const Size(1, 1));
    expect(await iotReadImageSize(Uint8List.fromList(<int>[1, 2, 3])), isNull);
  });
}
