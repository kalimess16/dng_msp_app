import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Khung thiết kế gốc của app (màn hình dọc).
const Size IOT_DESIGN_SIZE = Size(1080, 1920);

/// US-5: khung thiết kế theo hướng màn hình. Quay ngang → đổi chiều khung để `.w` không phóng
/// gấp đôi và `.h` không bị bóp nhỏ (khung dọc 1080 rộng áp lên màn ngang ~2 lần rộng hơn).
Size iotDesignSize(Orientation orientation) =>
    orientation == Orientation.landscape
    ? IOT_DESIGN_SIZE.flipped
    : IOT_DESIGN_SIZE;

/// US-5: cỡ chữ `.sp` theo cạnh ngắn màn hình. Màn dọc giữ nguyên như trước (cạnh ngắn = chiều
/// rộng); quay ngang chữ giữ đúng cỡ như dọc thay vì to gấp đôi.
double iotFontSizeResolver(num fontSize, ScreenUtil instance) =>
    fontSize *
    min(instance.screenWidth, instance.screenHeight) /
    IOT_DESIGN_SIZE.width;

/// US-6: chiều cao app bar gọn (mặc định Material là 56). Thanh trạng thái hệ thống vẫn giữ nguyên.
double iotToolbarHeight(Orientation orientation) =>
    orientation == Orientation.landscape ? 40 : 48;

/// Chiều cao khối icon + nhãn của thanh điều hướng dưới. Ngang: icon và nhãn cùng hàng.
double iotBottomBarContentHeight(Orientation orientation) =>
    orientation == Orientation.landscape ? 24 : 40;

/// Vùng hệ thống dưới không quá giá trị này coi là thanh cử chỉ (vạch ngang), lớn hơn là thanh 3 nút.
const double IOT_GESTURE_BAR_MAX_INSET = 32;

/// Khoảng cách tối thiểu từ nội dung tới mép dưới để không chạm vạch cử chỉ. Đo trên Pixel: vạch nằm
/// ~10–14dp từ đáy → 18 chừa ~4dp.
const double IOT_GESTURE_HANDLE_CLEARANCE = 18;

/// Bố cục thanh điều hướng dưới: tổng chiều cao (gồm vùng hệ thống) và lề trên/dưới của khối nội dung.
class IotBottomBarLayout {
  final double height;
  final double top;
  final double bottom;

  const IotBottomBarLayout({
    required this.height,
    required this.top,
    required this.bottom,
  });
}

/// US-7: thanh cử chỉ → căn giữa icon + nhãn trên toàn bộ phần xanh (gồm vùng thanh cử chỉ), lề trên =
/// lề dưới ≥ [IOT_GESTURE_HANDLE_CLEARANCE]. Thanh 3 nút / không có vùng hệ thống → nội dung nằm trên
/// vùng hệ thống, lề 8dp (nút hệ thống chiếm cả vùng nên không được lấn xuống).
IotBottomBarLayout iotBottomBarLayout(
  Orientation orientation,
  double bottomInset,
) {
  final content = iotBottomBarContentHeight(orientation);
  if (bottomInset > 0 && bottomInset <= IOT_GESTURE_BAR_MAX_INSET) {
    final margin = max(IOT_GESTURE_HANDLE_CLEARANCE, bottomInset * 2 / 3);
    return IotBottomBarLayout(
      height: content + 2 * margin,
      top: margin,
      bottom: margin,
    );
  }
  return IotBottomBarLayout(
    height: content + 16 + bottomInset,
    top: 8,
    bottom: 8 + bottomInset,
  );
}

/// `ScreenUtilInit` dùng chung của app: tự đổi khung thiết kế khi xoay màn hình.
class IotScreenUtilInit extends StatelessWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const IotScreenUtilInit({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: iotDesignSize(MediaQuery.orientationOf(context)),
      fontSizeResolver: iotFontSizeResolver,
      builder: builder,
    );
  }
}

/// Kích thước theo tỉ lệ màn hình nhưng không đổi khi xoay — dùng cho kích thước item (chiều cao
/// dòng, avatar, icon). Giới hạn hộp thoại phải nằm trong màn hình thì vẫn dùng `.sh`/`.sw`.
extension IotOrientationSize on num {
  /// Tỉ lệ theo cạnh dài: bằng `.sh` khi màn hình dọc.
  double get longSide =>
      max(ScreenUtil().screenWidth, ScreenUtil().screenHeight) * this;

  /// Tỉ lệ theo cạnh ngắn: bằng `.sw` khi màn hình dọc.
  double get shortSide =>
      min(ScreenUtil().screenWidth, ScreenUtil().screenHeight) * this;
}
