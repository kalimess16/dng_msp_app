import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/icon/app_icons.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IotBottomNavigatorBar extends StatelessWidget {
  static int selectedIotBottomNavigatorBar = 0;
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final iconSize = isLandscape ? 22.0 : 28.0;
    final labelSize = isLandscape ? 11.0 : 14.0;

    return Container(
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
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: isLandscape,
        child: SizedBox(
          height: isLandscape ? 56 : null,
          child: BottomNavigationBar(
            items: _buildBarItems(iconSize),
            selectedItemColor: IOT_FG_COLOR,
            selectedFontSize: labelSize,
            unselectedFontSize: labelSize,
            selectedLabelStyle: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: IOT_BG_COLOR,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            unselectedItemColor: Colors.white70,
            currentIndex: IotBottomNavigatorBar.selectedIotBottomNavigatorBar,
            showUnselectedLabels: true,
            onTap: ((index) {
              IotBottomNavigatorBar.selectedIotBottomNavigatorBar = index;
              switch (index) {
                case 0:
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName(IotRoutes.HOME_PAGE),
                  );
                  break;
                default:
                  Navigator.pushNamed(context, _items[index]![1]);
                  break;
              }
            }),
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBarItems(double iconSize) {
    List<BottomNavigationBarItem> _navItems = [];
    _items.forEach((key, value) {
      var _nav;
      final icon = _iconWithSize(value[2], iconSize);
      switch (value[3]) {
        case 'N':
          _nav = BottomNavigationBarItem(icon: icon, label: value[0]);
          break;
        case 'IM':
          _nav = BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[icon, _buildMessagePositioned(false)],
            ),
            label: value[0],
          );
          break;
        case 'AR':
          _nav = BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[icon, _buildAutoReportPositioned(false)],
            ),
            label: value[0],
          );
          break;
      }
      _navItems.add(_nav);
    });
    return _navItems;
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
              ? _positioned(snapshot.data as int)
              : SizedBox());
        },
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
