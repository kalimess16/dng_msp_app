import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:dngmsp/app/service/im/pdf_preview_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

/// Kiểm thử thuật toán ảnh xem trước với PDF thật (IotApp đã tải về `%TEMP%\IOT`).
/// Đặt `IOT_PDF_SAMPLES=<thư mục>` để chạy; `IOT_PDF_OUT=<thư mục>` để lưu ảnh PNG ra xem.
void main() {
  final String? samples = Platform.environment['IOT_PDF_SAMPLES'];
  final String? out = Platform.environment['IOT_PDF_OUT'];

  test('PDF thật: vùng tiêu đề + bút phê giống IotApp', () async {
    // PDFIUM_PATH: pdfium.dll (vd. %LOCALAPPDATA%\pdfrx\...\pdfium.dll). Nạp sẵn vào tiến trình để
    // worker của pdfrx mở "pdfium.dll" theo tên vẫn dùng đúng module này.
    final String? pdfium = Platform.environment['PDFIUM_PATH'];
    if (pdfium != null) {
      DynamicLibrary.open(pdfium);
      Pdfrx.pdfiumModulePath = pdfium;
    }
    await pdfrxInitialize();
    final List<File> pdfs = Directory(samples!)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.pdf'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    int focused = 0;
    int total = 0;
    for (final File pdf in pdfs) {
      final Uint8List bytes = await pdf.readAsBytes();
      final Uint8List? png = await IotPdfPreviewService.renderFirstPagePreview(
        bytes,
        eoffice: true,
        label: 'VB: TEST',
      );
      expect(png, isNotNull, reason: pdf.path);
      total++;
      // Kích thước từ header PNG (IHDR).
      final ByteData ihdr = ByteData.sublistView(png!, 16, 24);
      final int width = ihdr.getUint32(0);
      final int height = ihdr.getUint32(4);
      final double aspect = width / height;
      if ((aspect - 1.5).abs() < 0.02) focused++;
      final String name = pdf.path.substring(samples.length + 1).replaceAll(RegExp(r'[\\/]'), '__');
      // ignore: avoid_print
      print('${width}x$height  $name');
      if (out != null) {
        await File('$out/$name.png').writeAsBytes(png);
      }
    }
    // ignore: avoid_print
    print('phóng vùng bút phê: $focused/$total');
    expect(total, greaterThan(0));
  }, skip: samples == null ? 'Chưa đặt IOT_PDF_SAMPLES' : false,
      timeout: const Timeout(Duration(minutes: 10)));
}
