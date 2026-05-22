import 'package:dngmsp/app/model/account/log.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/account/log_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotAccountLogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 2;
    return IotPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, true, 'TÀI KHOẢN'),
        body: FutureBuilder(
            future: IotAccountLogStream().fetchIotUserLogs(),
            builder: ((context, snapshot) {
              if (snapshot.hasError)
                return IotExceptionPage(exception: snapshot.error);
              else if (snapshot.hasData) {
                return _buildUserLogs(snapshot.data as List<IotAccountLog>);
              } else
                return IotCircularProgressWidget();
            })),
        backgroundColor: Colors.white,
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, true),
    );
  }

  Widget _buildUserLogs(List<IotAccountLog> data) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Center(
          child: Padding(
            child: Text(
              "Thông tin đăng nhập",
              style: const TextStyle(fontSize: 20, color: IOT_BG_COLOR),
            ),
            padding: const EdgeInsets.all(10),
          )),
      Flexible(
        child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${data[index].fullName}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      Flexible(
                          child: Text(
                            _timeOfUserLogs(data[index].lastLogTime as String),
                            style: const TextStyle(fontSize: 18),
                          ),
                          fit: FlexFit.loose),
                    ]),
                constraints:
                BoxConstraints(minHeight: 0.068.sh, maxHeight: 0.14.sh),
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: IOT_GRID_BORDER_COLOR),
                        top: BorderSide(color: IOT_GRID_BORDER_COLOR))),
              );
            }),
        fit: FlexFit.loose,
      )
    ]);
  }

  String _timeOfUserLogs(String logTime) {
    var date = logTime.split(' ')[0].split('/');
    var time = logTime.split(' ')[1].split(':');

    var datetime = DateTime.utc(int.parse(date[2]), int.parse(date[1]), int.parse(date[0]),
        int.parse(time[0]), int.parse(time[1]), int.parse(time[2]));
    var now = DateTime.now();

    var diff = now.difference(datetime);
    return diff.inDays == 0 && datetime.day == now.day
        ? 'Hôm nay ' + ((datetime.hour <= 9 ? '0' : '') +
        '${datetime.hour}:' +
        (datetime.minute <= 9 ? '0' : '') +
        '${datetime.minute}')
        : '${datetime.day}/${datetime.month}/${datetime.year}';
  }
}
