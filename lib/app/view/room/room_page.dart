import 'dart:convert';

import 'package:dngmsp/app/model/report/data_report.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/room/room_stream.dart';
import 'package:flutter/material.dart';

class IotServerRoomPage extends StatefulWidget {
  final String? srvRoomType;
  IotServerRoomPage({this.srvRoomType});

  @override
  _IotServerRoomPageState createState() => _IotServerRoomPageState();
}

class _IotServerRoomPageState extends State<IotServerRoomPage> {

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: IotAppBar().build(context, true, 'NHIỆT ĐỘ PMC VÀ WAN'),
          body: _buildBodyPage(),
          bottomNavigationBar: IotBottomNavigatorBar(),
        ),
        onWillPop: () => IotAppBar().backIotPages(context, true)
    );
  }

  Widget _buildBodyPage() {
    return FutureBuilder<List<IotDataReport>>(
        future: IotServerRoomStream()
            .fetchIotServerRoom(),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return _buildListView(snapshot.data as List<IotDataReport>);
          else if (snapshot.hasError)
            return IotExceptionPage(exception: snapshot.error);
          else
            return IotCircularProgressWidget();
        });
  }

  Widget _buildListView(List<IotDataReport> data) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          if (data[index].code!.startsWith("TEMPE-")) {
            return InkWell(
                child: Container(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data[index].title ?? '',
                          style: const TextStyle(
                              color: IOT_BG_COLOR, fontWeight: FontWeight.bold),
                        ),
                        Row(children: [
                          Flexible(
                              fit: FlexFit.loose,
                              child: Image.memory(
                                  base64.decode((data[index].content ?? ''))))
                        ])
                      ]),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: IOT_GRID_BORDER_COLOR))),
                ));
          } else {
            return InkWell(
                child: Container(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data[index].title ?? '',
                          style: const TextStyle(
                              color: IOT_BG_COLOR, fontWeight: FontWeight.bold),
                        ),
                        Row(children: [
                          Flexible(
                              fit: FlexFit.loose, child: Text(data[index].content ?? ''))
                        ])
                      ]),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: IOT_GRID_BORDER_COLOR))),
                ));
          }
        });
  }
}
