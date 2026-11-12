import 'dart:io';
import 'dart:typed_data';

import 'package:dngmsp/app/service/im/pdf_preview_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Luồng tạo lại ảnh (hàng đợi + cache). Để riêng file: hàng đợi là biến tĩnh, không chạy
/// chung với testWidgets (thời gian giả) để tránh tác vụ của test khác chặn hàng đợi.
void main() {
  group('IotPdfPreviewService.regenerate', () {
    late Directory temp;
    setUp(() {
      temp = Directory.systemTemp.createTempSync('iot_preview_test');
      IotPdfPreviewService.cacheRoot = () async => temp;
    });
    tearDown(() => temp.deleteSync(recursive: true));

    test('có cache thì trả về ảnh cache, không tải PDF', () async {
      final cache = File('${temp.path}/IOT/7/VB 1.pdf.preview-eoffice-'
          '${IotPdfPreviewService.cacheVersion}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[1, 2, 3]);
      var loads = 0;
      final png = await IotPdfPreviewService.regenerate(
        messageId: 7,
        fileName: 'VB 1.pdf',
        eoffice: true,
        label: 'VB: 1',
        loadPdf: () async {
          loads++;
          return Uint8List(0);
        },
      ).timeout(const Duration(seconds: 5));
      expect(png, cache.readAsBytesSync());
      expect(loads, 0);
    });

    test('tải PDF lỗi thì trả về null (giữ ảnh server), không treo', () async {
      Future<Uint8List?> run() => IotPdfPreviewService.regenerate(
            messageId: 8,
            fileName: 'VB 2.pdf',
            eoffice: false,
            label: null,
            loadPdf: () async => throw Exception('mạng lỗi'),
          );
      // Hai lần gọi cùng lúc dùng chung một tác vụ; lần sau đó chạy lại được.
      final results = await Future.wait(<Future<Uint8List?>>[run(), run()])
          .timeout(const Duration(seconds: 5));
      expect(results, <Uint8List?>[null, null]);
      expect(await run().timeout(const Duration(seconds: 5)), isNull);
    });
  });

}
