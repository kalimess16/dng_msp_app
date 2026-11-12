import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/icon/app_icons.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/var/iot_screen.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IotBottomNavigatorBar extends StatelessWidget {
  static int selectedIotBottomNavigatorBar = 0;

  /// US-9: mục được chọn của từng trang (route). Các trang gán [selectedIotBottomNavigatorBar] trong
  /// `build()`; khi xoay màn hình mọi trang trong ngăn xếp build lại và trang build sau cùng (thường là
  /// home → 0) ghi đè → thanh của trang đang xem đánh dấu sai mục. Ghi nhận giá trị ở lần dựng đầu.
  static final Expando<int> _routeSelection = Expando<int>('iotRouteTab');

  /// Mục được chọn cho trang chứa [context] (giá trị tại lần dựng đầu tiên trên trang đó).
  static int selectedFor(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return selectedIotBottomNavigatorBar;
    return _routeSelection[route] ??= selectedIotBottomNavigatorBar;
  }

  final Map<int, List<dynamic>> _items = {
    0: [
      'IOT',
      IotRoutes.HOME_PAGE,
      const Icon(Icons.home_outlined, size: 28),
      'N',
    ],
    1: [
      'Số liệu định kỳ',
      IotRoutes.AUTO_REPORT_PAGE,
      const Icon(IotAppIcons.auto_report, size: 28),
      'AR',
    ],
    2: [
      'Thông tin',
      IotRoutes.MSP_PAGE,
      const Icon(IotAppIcons.msp, size: 28),
      'IM',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final selectedIndex = selectedFor(context);
    final isLandscape = orientation == Orientation.landscape;
    final iconSize = 22.0;
    final labelSize = isLandscape ? 12.0 : 13.0;
    final layout = iotBottomBarLayout(
      orientation,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Container(
      height: layout.height,
      decoration: BoxDecoration(
        color: IOT_BG_COLOR,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      // US-5/6/7: nội dung căn giữa phần xanh nhưng không chạm vạch cử chỉ — xem `iotBottomBarLayout`.
      padding: EdgeInsets.only(top: layout.top, bottom: layout.bottom),
      child: Row(
        children: [
          for (final entry in _items.entries)
            Expanded(
              child: _buildNavItem(
                context,
                entry.key,
                entry.value,
                iconSize: iconSize,
                labelSize: labelSize,
                horizontal: isLandscape,
                selected: entry.key == selectedIndex,
              ),
            ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = index;
    switch (index) {
      case 0:
        Navigator.popUntil(context, ModalRoute.withName(IotRoutes.HOME_PAGE));
        break;
      default:
        Navigator.pushNamed(context, _items[index]![1]);
        break;
    }
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    List<dynamic> value, {
    required double iconSize,
    required double labelSize,
    required bool horizontal,
    required bool selected,
  }) {
    final color = selected ? IOT_FG_COLOR : Colors.white70;
    final label = Text(
      value[0],
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: labelSize,
        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
      ),
    );
    final icon = IconTheme(
      data: IconThemeData(color: color, size: iconSize),
      child: _buildBarIcon(value, iconSize),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => _onTap(context, index),
        child: Center(
          // Chữ hệ thống phóng to → thu nhỏ vừa khối nội dung thay vì tràn.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: horizontal
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [icon, const SizedBox(width: 6), label],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [icon, const SizedBox(height: 2), label],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarIcon(List<dynamic> value, double iconSize) {
    final icon = _iconWithSize(value[2], iconSize);
    switch (value[3]) {
      case 'IM':
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[icon, _buildMessagePositioned(false)],
        );
      case 'AR':
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[icon, _buildAutoReportPositioned(false)],
        );
      default:
        return icon;
    }
  }

  Widget _iconWithSize(dynamic icon, double size) {
    if (icon is Icon) {
      return Icon(icon.icon, size: size);
    }
    return Icon(icon as IconData, size: size);
  }

  Widget _buildMessagePositioned(bool isSelected) {
    return Consumer<IotListInternalMessageStream>(
      builder: (context, fcm, _) => FutureBuilder<int>(
        future: context
            .read<IotListInternalMessageStream>()
            .countUnreadInternalMessage(),
        builder: (context, snapshot) {
          return (snapshot.hasData && snapshot.data! > 0
              ? _positioned(snapshot.data as int)
              : SizedBox());
        },
      ),
    );
  }

  Widget _buildAutoReportPositioned(bool isSelected) {
    return Consumer<IotListAutoReportStream>(
      builder: (context, fcm, _) => FutureBuilder<int>(
        future: context
            .read<IotListAutoReportStream>()
            .countUnreadAutoReports(),
        builder: (context, snapshot) {
          return (snapshot.hasData && snapshot.data! > 0
              ? _buildNotificationDot()
              : const SizedBox.shrink());
        },
      ),
    );
  }

  Widget _buildNotificationDot() {
    return Positioned(
      right: -4,
      top: -2,
      child: Semantics(
        label: 'Có số liệu định kỳ mới',
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: IOT_BG_COLOR, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _positioned(int count) {
    return Positioned(
      right: -8,
      top: -6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: IOT_BG_COLOR, width: 1.5),
        ),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
