import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Ảnh xem trước trang đầu văn bản PDF trong tin nhắn, tạo ngay trên điện thoại.
///
/// Port từ IotApp `service/PdfPreviewService.java` (US-5, US-7, US-9, US-10 —
/// spec `IotApp/docs/modules/messaging/pdf-preview.md`):
/// - Ảnh server cũ của máy photo RICOH (trang `/Rotate 270`) bị cắt thành dải dọc hẹp.
/// - Văn bản eOffice cần lấy cả phần bút phê ("Sao gửi … Lưu VT") ở lề trái.
///
/// PDFium (pdfrx) render trang theo hướng hiển thị nên trang xoay được xử lý đúng.
class IotPdfPreviewService {
  static const double dpi = 180;
  static const double _leftMarginPt = 50;

  // US-9: dò bút phê trong vùng x < 60%, y < 50% trang, ô ~2,8 mm, lấy mẫu mỗi 2 px.
  static const double _inkScanWidth = 0.60;
  static const double _inkScanHeight = 0.50;
  static final int _inkCell = (dpi / 9).round();
  static const int _inkStep = 2;
  static const int _inkMinSamplesPerCell = 3;
  static const int _inkMinCells = 15;
  static const double _annotatedMinWidth = 0.56;
  static const double _annotatedMaxHeight = 0.45;
  static const double _eofficeWidth = 0.48;
  static const double _eofficeHeight = 0.22;

  // US-10: vùng "tiêu đề + Sao gửi … Lưu VT" phóng đầy khung xem trước tỉ lệ 1,5:1.
  static const double _focusAspect = 1.5;
  static const double _focusZoneWidth = 0.35;
  static const double _focusWidthPx = 1100;
  static const double _maxFocusDpi = 400;

  // Nhãn "VB: ..." của server: chữ đậm 36px trên ảnh rộng ~715px.
  static const double _labelSizePerPx = 36 / 715;
  static const double _labelStripPerPx = _labelSizePerPx * 1.3;

  /// Đổi phiên bản khi đổi thuật toán để bỏ cache cũ.
  static const String cacheVersion = 'v3';

  // Tải PDF + render lần lượt từng văn bản (đỡ tốn bộ nhớ, mạng trên điện thoại).
  static Future<void> _queue = Future<void>.value();
  static const Duration _taskTimeout = Duration(seconds: 90);
  static final Map<String, Future<Uint8List?>> _pending = {};

  /// Thư mục gốc chứa cache ảnh (thay được trong test).
  @visibleForTesting
  static Future<Directory> Function() cacheRoot = getTemporaryDirectory;

  /// Ảnh xem trước tạo lại cho một file PDF của tin nhắn; có cache trong thư mục tạm
  /// `IOT/<messageId>/`. [loadPdf] chỉ được gọi khi chưa có cache.
  /// Trả về PNG, hoặc null nếu không tải/đọc/render được (giữ ảnh server).
  static Future<Uint8List?> regenerate({
    required int messageId,
    required String fileName,
    required bool eoffice,
    required String? label,
    required Future<Uint8List> Function() loadPdf,
  }) {
    final String key = '$messageId/$fileName/$eoffice/$label';
    return _pending[key] ??= _enqueue(() async {
      try {
        final File cache = await _cacheFile(messageId, fileName, eoffice);
        if (await cache.exists() && await cache.length() > 0) {
          return await cache.readAsBytes();
        }
        final Uint8List pdf = await loadPdf();
        final Uint8List? png = await renderFirstPagePreview(
          pdf,
          eoffice: eoffice,
          label: label,
        );
        if (png != null) {
          try {
            await cache.parent.create(recursive: true);
            await cache.writeAsBytes(png, flush: true);
          } catch (_) {
            // không ghi được cache thì lần sau render lại
          }
        }
        return png;
      } catch (_) {
        return null;
      }
    }).whenComplete(() {
      // Không viết `() => _pending.remove(key)`: remove trả về chính Future này,
      // whenComplete sẽ đợi nó → tự đợi chính mình, treo mãi (ảnh không bao giờ thay).
      _pending.remove(key);
    });
  }

  static Future<T> _enqueue<T>(Future<T> Function() task) {
    final Completer<T> completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        // Một lần tải/render treo (mạng chập chờn) không được chặn cả hàng đợi.
        completer.complete(await task().timeout(_taskTimeout));
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  static Future<File> _cacheFile(
    int messageId,
    String fileName,
    bool eoffice,
  ) async {
    final Directory temp = await cacheRoot();
    final String safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final String suffix =
        eoffice ? '.preview-eoffice-$cacheVersion.png' : '.preview.png';
    return File('${temp.path}/IOT/$messageId/$safeName$suffix');
  }

  /// Ảnh xem trước (PNG) trang đầu file PDF.
  ///
  /// [eoffice]: văn bản eOffice (ảnh server có nhãn "VB:"): ảnh màu, lấy cả bút phê.
  /// [label]: nhãn "VB: <số hiệu>" vẽ ở góc trên-trái; null/rỗng thì không vẽ.
  static Future<Uint8List?> renderFirstPagePreview(
    Uint8List pdf, {
    required bool eoffice,
    String? label,
  }) async {
    final PdfDocument document = await PdfDocument.openData(pdf);
    try {
      if (document.pages.isEmpty) return null;
      final PdfPage page = document.pages.first;
      final double fullW = page.width * dpi / 72;
      final double fullH = page.height * dpi / 72;
      final PdfImage? rendered = await page.render(
        fullWidth: fullW,
        fullHeight: fullH,
        backgroundColor: 0xffffffff,
      );
      if (rendered == null) return null;
      final IotPixels full = IotPixels(
        rendered.width,
        rendered.height,
        Uint8List.fromList(rendered.pixels),
        bgra: true,
      );
      rendered.dispose();

      final bool hasLabel = label != null && label.isNotEmpty;
      final int pageW = full.width;
      final int pageH = full.height;

      if (!eoffice) {
        // File thường: trang ngang lấy cả trang; trang dọc cắt từ lề 50pt, nửa trên (như server).
        if (pageW > pageH) {
          return _compose(full, ui.Rect.fromLTWH(0, 0, pageW * 1.0, pageH * 1.0),
              grayscale: true);
        }
        final int x =
            math.min(pageW - 1, (_leftMarginPt * dpi / 72).round());
        final int w = math.max(1, pageW - x);
        final int h = math.max(1, math.min(pageH, (pageH * 0.5).round()));
        return _compose(full, ui.Rect.fromLTWH(x * 1.0, 0, w * 1.0, h * 1.0),
            grayscale: true);
      }

      if (pageW <= pageH) {
        final IotFocusRegion? focus =
            await Isolate.run(() => annotationFocus(full));
        if (focus != null) {
          // US-10: render riêng vùng tiêu đề + bút phê ở độ phân giải cao.
          final double scale =
              math.min(_maxFocusDpi, dpi * _focusWidthPx / focus.width) / dpi;
          final int w = math.max(1, (focus.width * scale).round());
          final int h = math.max(1, (focus.height * scale).round());
          final PdfImage? region = await page.render(
            x: (focus.x * scale).round(),
            y: (focus.y * scale).round(),
            width: w,
            height: h,
            fullWidth: fullW * scale,
            fullHeight: fullH * scale,
            backgroundColor: 0xffffffff,
          );
          if (region != null) {
            final IotPixels pixels = IotPixels(region.width, region.height,
                Uint8List.fromList(region.pixels),
                bgra: true);
            region.dispose();
            return _compose(
              pixels,
              ui.Rect.fromLTWH(0, 0, w * 1.0, h * 1.0),
              label: hasLabel ? label : null,
              labelStrip: hasLabel,
            );
          }
        }
      }

      int x;
      int w;
      int h;
      if (pageW > pageH) {
        x = 0;
        w = pageW;
        h = pageH;
      } else {
        final List<int>? ink = await Isolate.run(() => annotationExtent(full));
        if (ink != null) {
          // US-9: có bút phê nhưng không tách được → cắt từ mép trái tới hết bút phê.
          x = 0;
          w = math.max((pageW * _annotatedMinWidth).round(),
              ink[0] + (pageW * 0.02).round());
          w = math.min(w, (pageW * _inkScanWidth).round());
          h = math.max((pageH * _eofficeHeight).round(),
              ink[1] + (pageH * 0.015).round());
          h = math.min(h, (pageH * _annotatedMaxHeight).round());
        } else {
          x = math.min(pageW - 1, (_leftMarginPt * dpi / 72).round());
          w = (pageW * _eofficeWidth).round();
          h = (pageH * _eofficeHeight).round();
        }
        w = math.max(1, math.min(pageW - x, w));
        h = math.max(1, math.min(pageH, h));
      }
      return _compose(
        full,
        ui.Rect.fromLTWH(x * 1.0, 0, w * 1.0, h * 1.0),
        label: hasLabel ? label : null,
      );
    } finally {
      await document.dispose();
    }
  }

  /// Cắt [src] từ ảnh, (tuỳ chọn) chuyển xám, thêm nhãn "VB: ..." rồi mã hoá PNG.
  /// [labelStrip]: đặt nhãn trên dải trắng riêng phía trên (US-10), không che bút phê.
  static Future<Uint8List?> _compose(
    IotPixels pixels,
    ui.Rect src, {
    String? label,
    bool labelStrip = false,
    bool grayscale = false,
  }) async {
    final ui.Image image = await _toImage(pixels);
    final int outW = src.width.round();
    final int strip =
        labelStrip ? (outW * _labelStripPerPx).round() : 0;
    final int outH = src.height.round() + strip;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, outW * 1.0, outH * 1.0),
        ui.Paint()..color = const ui.Color(0xffffffff));
    final ui.Paint paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
    if (grayscale) {
      paint.colorFilter = const ui.ColorFilter.matrix(<double>[
        0.299, 0.587, 0.114, 0, 0, //
        0.299, 0.587, 0.114, 0, 0, //
        0.299, 0.587, 0.114, 0, 0, //
        0, 0, 0, 1, 0,
      ]);
    }
    canvas.drawImageRect(
      image,
      src,
      ui.Rect.fromLTWH(0, strip * 1.0, src.width, src.height),
      paint,
    );
    if (label != null && label.isNotEmpty) {
      _drawLabel(canvas, label, outW);
    }
    final ui.Image out = await recorder.endRecording().toImage(outW, outH);
    image.dispose();
    try {
      final ByteData? data =
          await out.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      out.dispose();
    }
  }

  static Future<ui.Image> _toImage(IotPixels pixels) {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.data,
      pixels.width,
      pixels.height,
      pixels.bgra ? ui.PixelFormat.bgra8888 : ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  /// Nhãn giống server: chữ trắng đậm trên nền xám (128) ở góc trên-trái.
  static void _drawLabel(ui.Canvas canvas, String text, int imageWidth) {
    final double fontSize =
        math.max(36, (imageWidth * _labelSizePerPx).roundToDouble());
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xffffffff),
          backgroundColor: const Color(0xff808080),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: imageWidth.toDouble());
    painter.paint(canvas, Offset.zero);
    painter.dispose();
  }

  // ---------------------------------------------------------------------------
  // Nhận biết ảnh server cần tạo lại.

  /// Ảnh xem trước cũ do server tạo sai có dạng dọc (cao hơn rộng).
  static bool isLegacyRotatedPreview(IotPixels preview) =>
      preview.height > preview.width;

  /// Ảnh server của văn bản eOffice có nhãn "VB: ..." nền xám (128) ở góc trên-trái.
  static bool hasEofficeLabel(IotPixels preview) {
    final int w = math.min(120, preview.width);
    final int h = math.min(36, preview.height);
    int gray = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int i = preview.offset(x, y);
        if ((preview.r(i) - 128).abs() <= 16 &&
            (preview.g(i) - 128).abs() <= 16 &&
            (preview.b(i) - 128).abs() <= 16) {
          gray++;
        }
      }
    }
    return w * h > 0 && gray >= w * h * 0.35;
  }

  // ---------------------------------------------------------------------------
  // Dò bút phê (toạ độ pixel ở 180 dpi). Hàm thuần, chạy được trong isolate.

  static bool _isBlueInk(IotPixels p, int x, int y) {
    final int i = p.offset(x, y);
    final int r = p.r(i), g = p.g(i), b = p.b(i);
    return b > r + 40 && b > g + 15 && r < 170;
  }

  /// US-9: vùng bút phê (mực xanh) ở nửa trái, nửa trên trang.
  /// Trả về [mép phải, mép dưới] (pixel), hoặc null nếu không có bút phê.
  static List<int>? annotationExtent(IotPixels page) {
    final int scanW = (page.width * _inkScanWidth).round();
    final int scanH = (page.height * _inkScanHeight).round();
    final int cols = scanW ~/ _inkCell + 1;
    final int rows = scanH ~/ _inkCell + 1;
    final List<int> samples = List<int>.filled(rows * cols, 0);
    for (int y = 0; y < scanH; y += _inkStep) {
      for (int x = 0; x < scanW; x += _inkStep) {
        if (_isBlueInk(page, x, y)) {
          samples[(y ~/ _inkCell) * cols + x ~/ _inkCell]++;
        }
      }
    }
    int cells = 0;
    int right = -1;
    int bottom = -1;
    for (int cy = 0; cy < rows; cy++) {
      for (int cx = 0; cx < cols; cx++) {
        if (samples[cy * cols + cx] >= _inkMinSamplesPerCell) {
          cells++;
          right = math.max(right, (cx + 1) * _inkCell);
          bottom = math.max(bottom, (cy + 1) * _inkCell);
        }
      }
    }
    return cells >= _inkMinCells ? <int>[right, bottom] : null;
  }

  /// US-10: vùng "tiêu đề cơ quan + danh sách bút phê (Sao gửi … Lưu VT)", bỏ dòng
  /// ngày và chữ ký, tỉ lệ rộng:cao = 1,5 (kể cả dải nhãn) để phóng đầy khung.
  /// Trả về null nếu không có bút phê hoặc không tách được.
  static IotFocusRegion? annotationFocus(IotPixels page) {
    if (annotationExtent(page) == null) return null;
    final int pageW = page.width;
    final int pageH = page.height;
    final int zoneW = (pageW * _focusZoneWidth).round();
    final int px1mm = (dpi / 25.4).round();

    final List<List<int>> bands = _inkBands(page, zoneW, 0,
        (pageH * _inkScanHeight).round(), 2, (1.4 * px1mm).round(), px1mm);
    int signature = -1;
    for (int i = bands.length - 1; i >= 0 && signature < 0; i--) {
      if (bands[i][1] - bands[i][0] >= (12.7 * px1mm).round()) {
        signature = i;
      }
    }
    if (signature <= 0) {
      return null; // không thấy chữ ký, hoặc phía trên chữ ký không có dòng nào
    }
    final List<int> sig = bands[signature];
    // Dòng ngày có chữ số nên cao ≥ 3,8 mm; "Lưu VT" (chữ thường) chỉ 2–3,4 mm.
    final int dateMin = (3.8 * px1mm).round();
    // Tách dải chữ ký: các dòng nhỏ (< 8 mm) trước thân chữ ký là "Lưu VT"/ngày bị dính vào.
    final List<List<int>> inner = _inkBands(
        page, zoneW, sig[0], sig[1] + 1, 4, (0.7 * px1mm).round(), px1mm);
    int body = -1;
    for (int i = 0; i < inner.length && body < 0; i++) {
      if (inner[i][1] - inner[i][0] >= 8 * px1mm) body = i;
    }
    int dateTop = sig[0];
    int lastLineBottom = bands[signature - 1][1];
    if (body >= 1) {
      dateTop = inner[body][0];
      lastLineBottom = inner[body - 1][1];
      for (int i = 0; i < body; i++) {
        if (inner[i][1] - inner[i][0] >= dateMin) {
          dateTop = inner[i][0];
          lastLineBottom = i > 0 ? inner[i - 1][1] : bands[signature - 1][1];
          break;
        }
      }
    } else if (body == 0) {
      final List<int> before = bands[signature - 1];
      final int beforeHeight = before[1] - before[0];
      if (signature >= 2 &&
          beforeHeight >= dateMin &&
          beforeHeight <= 10 * px1mm &&
          sig[0] - before[1] <= (pageH * 0.03).round()) {
        dateTop = before[0]; // dòng ngày tách riêng ngay trên chữ ký
        lastLineBottom = bands[signature - 2][1];
      }
    }
    int bottom = math.max(dateTop - (pageH * 0.004).round(),
        lastLineBottom + (pageH * 0.006).round());
    bottom = math.min(bottom, dateTop + (pageH * 0.006).round());

    final int top = math.max(
        0,
        math.min(_headerTop(page), bands[0][0]) - (pageH * 0.012).round());
    if (bottom - top < (pageH * 0.10).round()) return null;
    int width = ((bottom - top) *
            _focusAspect /
            (1 - _focusAspect * _labelStripPerPx))
        .round();
    width = math.max((pageW * 0.30).round(),
        math.min((pageW * _inkScanWidth).round(), width));
    return IotFocusRegion(0, top, width, bottom - top);
  }

  /// Các dải dòng mực xanh trong vùng x < zoneW, y0 ≤ y < y1 (lấy mẫu mỗi 2 px).
  static List<List<int>> _inkBands(IotPixels page, int zoneW, int y0, int y1,
      int minSamples, int maxGap, int px1mm) {
    final List<List<int>> bands = <List<int>>[];
    int start = -1;
    int last = -1;
    void addBand(int s, int e) {
      if (e - s >= (0.6 * px1mm).round()) bands.add(<int>[s, e]);
    }

    for (int y = y0; y < y1 && y < page.height; y += _inkStep) {
      int samples = 0;
      for (int x = 0; x < zoneW && samples < minSamples; x += _inkStep) {
        if (_isBlueInk(page, x, y)) samples++;
      }
      if (samples < minSamples) continue;
      if (start >= 0 && y - last > maxGap) {
        addBand(start, last);
        start = -1;
      }
      if (start < 0) start = y;
      last = y;
    }
    if (start >= 0) addBand(start, last);
    return bands;
  }

  /// Dòng đầu có chữ in (tiêu đề cơ quan) ở nửa trái, trong 15% trên cùng.
  static int _headerTop(IotPixels page) {
    final int x0 = (page.width * 0.05).round();
    final int x1 = (page.width * 0.45).round();
    final int y0 = (page.height * 0.015).round();
    final int y1 = (page.height * 0.15).round();
    for (int y = y0; y < y1; y += _inkStep) {
      int dark = 0;
      for (int x = x0; x < x1; x += _inkStep) {
        final int i = page.offset(x, y);
        if (page.r(i) < 100 && page.g(i) < 100 && page.b(i) < 100 &&
            ++dark >= 3) {
          return y;
        }
      }
    }
    return (page.height * 0.045).round();
  }
}

/// Ảnh thô 4 byte/pixel (BGRA từ PDFium, hoặc RGBA từ bộ giải mã Flutter).
class IotPixels {
  final int width;
  final int height;
  final Uint8List data;
  final bool bgra;

  const IotPixels(this.width, this.height, this.data, {required this.bgra});

  int offset(int x, int y) => (y * width + x) * 4;
  int r(int i) => data[bgra ? i + 2 : i];
  int g(int i) => data[i + 1];
  int b(int i) => data[bgra ? i : i + 2];

  /// Giải mã ảnh (JPEG/PNG) thành RGBA.
  static Future<IotPixels?> decode(Uint8List encoded) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(encoded);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final IotPixels? result = data == null
          ? null
          : IotPixels(image.width, image.height, data.buffer.asUint8List(),
              bgra: false);
      image.dispose();
      codec.dispose();
      return result;
    } catch (_) {
      return null;
    }
  }
}

/// Vùng cắt (pixel ở 180 dpi).
class IotFocusRegion {
  final int x;
  final int y;
  final int width;
  final int height;
  const IotFocusRegion(this.x, this.y, this.width, this.height);

  @override
  String toString() => 'IotFocusRegion($x, $y, $width x $height)';
}
