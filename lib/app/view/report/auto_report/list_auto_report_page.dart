import 'package:dngmsp/app/model/report/auto_report.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/navigator_auto_report_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotListAutoReportPage extends StatefulWidget {
  static Map<String, bool> mapSelectedMessages = {};
  @override
  _IotListAutoReportPageState createState() => _IotListAutoReportPageState();
}

class _IotListAutoReportPageState extends State<IotListAutoReportPage>
    with WidgetsBindingObserver {
  int _lastAccessTime = 0;
  bool _isLoading = false;
  int _status = 0;

  final List<int> _accessTimes = [];
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(() async {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!_accessTimes.contains(_lastAccessTime)) {
          _status = await context
              .read<IotListAutoReportStream>()
              .loadMoreIotAutoReports(context, _lastAccessTime);
          _accessTimes.add(_lastAccessTime);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 1;
    return WillPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, true, 'SỐ LIỆU ĐỊNH KỲ'),
        body: _bodyListMessage(),
        backgroundColor: const Color(0xFFF4F8F5),
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, true),
    );
  }

  Widget _bodyListMessage() {
    var _hasInitiation = false;
    return Consumer<IotListAutoReportStream>(
      builder: (context, fcm, _) {
        return FutureBuilder(
          future: context.watch<IotListAutoReportStream>().initIotAutoReports(
            context,
            _hasInitiation,
          ),
          builder: ((context, snapshot) {
            if (snapshot.hasData) {
              _hasInitiation = true;
              return _listMessageItem(snapshot.data as List<IotAutoReport>);
            }
            if (snapshot.hasError)
              return IotExceptionPage(
                exception: snapshot.error,
                isBackHome: true,
              );
            return IotCircularProgressWidget();
          }),
        );
      },
    );
  }

  Widget _listMessageItem(List<IotAutoReport> data) {
    if (data.isEmpty)
      return Center(
        child: Text(
          'IOT',
          style: TextStyle(
            color: IOT_BG_COLOR,
            fontSize: SP_LARGER_COMMON_FONT_SIZE.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: data.length + 1,
      controller: _scrollController,
      itemBuilder: (context, index) {
        if (index == data.length - 1) _lastAccessTime = data[index].time;
        if (index == data.length) {
          _isLoading = true;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Opacity(
                opacity: (_isLoading && _accessTimes.isNotEmpty) ? 1.0 : 00,
                child: (_status == 0
                    ? CircularProgressIndicator()
                    : (_status < 0
                          ? TextButton(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _status == -1 ? 'MẤT KẾT NỐI' : 'TẢI LỖI',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.refresh,
                                    color: Colors.black87,
                                    size: 32,
                                  ),
                                ],
                              ),
                              onPressed: () async {
                                _status = await context
                                    .read<IotListAutoReportStream>()
                                    .loadMoreIotAutoReports(
                                      context,
                                      _lastAccessTime,
                                    );
                              },
                            )
                          : Text(''))),
              ),
            ),
          );
        }
        _isLoading = false;
        final status = data[index].status ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            elevation: status == 0 ? 2 : 1,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status == 0 ? IOT_BG_COLOR : Colors.black26,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _showCreatorName(data[index].creator)),
                        const SizedBox(width: 8),
                        _showTime(data[index].time),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      child: _showTitle(data[index].title, status),
                      padding: const EdgeInsets.only(left: 16),
                    ),
                  ],
                ),
              ),
              onTap: () async => await IotNavigatorAutoReportPage().onTap(
                context,
                data[index].id,
                data[index].reportType,
                data[index].reportDate,
                data[index].title,
                false,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _showCreatorName(String creatorName) {
    return Text(
      creatorName,
      style: TextStyle(
        color: Colors.black38,
        fontSize: 32.sp,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _showTime(int time) {
    return Text(
      IotUtility().parseTimeAutoReport(time),
      style: TextStyle(
        color: Colors.black54,
        fontSize: 32.sp,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _showTitle(String title, int status) {
    return Text(
      title,
      style: TextStyle(
        color: status == 0 ? Colors.black87 : Colors.black54,
        fontSize: SP_AUTO_REPORT_FONT_SIZE.sp,
        fontWeight: status == 0 ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
