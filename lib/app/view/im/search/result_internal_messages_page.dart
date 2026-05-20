import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/view/widget/short_name_circular_widget.dart';
import 'package:dngmsp/app/viewmodel/im/reply/navigator_internal_message.dart';
import 'package:dngmsp/app/viewmodel/im/search/search_internal_message_stream.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotResultInternalMessagesPage extends StatefulWidget {
  final String fromDate;
  final String toDate;
  final String senders;
  final String messageContent;
  IotResultInternalMessagesPage(
      this.fromDate, this.toDate, this.senders, this.messageContent);

  @override
  _IotResultInternalMessagesPageState createState() =>
      _IotResultInternalMessagesPageState();
}

class _IotResultInternalMessagesPageState
    extends State<IotResultInternalMessagesPage> {
  int _lastAccessTime = 0;
  bool _isLoading = false;
  int _status = 0;
  bool _isFirstPage = true;

  final List<int> _accessTimes = [];
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() async {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!_accessTimes.contains(_lastAccessTime)) {
          _status = await context
              .read<IotSearchInternalMessageStream>()
              .loadMoreIotInternalMessages(
                  context,
                  widget.fromDate,
                  widget.toDate,
                  widget.senders,
                  widget.messageContent,
                  _lastAccessTime);
          _accessTimes.add(_lastAccessTime);
        }
        _isFirstPage = false;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 2;
    return WillPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, false, 'KẾT QUẢ TÌM KIẾM'),
        body: _bodyListMessage(),
        backgroundColor: Colors.white,
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, false),
    );
  }

  Widget _bodyListMessage() {
    var _hasInitiation = false;
    return Consumer<IotSearchInternalMessageStream>(builder: (context, fcm, _) {
      return FutureBuilder(
          future: context
              .read<IotSearchInternalMessageStream>()
              .initIotInternalMessages(context, widget.fromDate, widget.toDate,
                  widget.senders, widget.messageContent, _hasInitiation),
          builder: ((context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              _hasInitiation = true;
              var data = snapshot.data as List<IotInternalMessage>;
              return _listMessageItem(data);
            }
            if (snapshot.hasError)
              return IotExceptionPage(
                  exception: snapshot.error, isBackHome: true);
            return IotCircularProgressWidget();
          }));
    });
  }

  Widget _listMessageItem(List<IotInternalMessage> data) {
    if (data.isEmpty)
      return Center(
          child: Text(
        'KHÔNG TÌM THẤY THÔNG TIN NÀO',
        style: TextStyle(
            color: IOT_BG_COLOR,
            fontSize: SP_COMMON_FONT_SIZE.sp,
            fontWeight: FontWeight.bold),
      ));
    return ListView.builder(
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
                    opacity: (!_isFirstPage && _isLoading) ? 1.0 : 00,
                    child: (_status == 0
                        ? CircularProgressIndicator()
                        : (_status < 0
                            ? TextButton(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _status == -1
                                            ? 'MẤT KẾT NỐI'
                                            : 'TẢI LỖI',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Icon(
                                        Icons.refresh,
                                        color: Colors.black87,
                                        size: 32,
                                      )
                                    ]),
                                onPressed: () async {
                                  _status = await context
                                      .read<IotSearchInternalMessageStream>()
                                      .loadMoreIotInternalMessages(
                                          context,
                                          widget.fromDate,
                                          widget.toDate,
                                          widget.senders,
                                          widget.messageContent,
                                          _lastAccessTime);
                                })
                            : Text('')))),
              ),
            );
          }
          _isLoading = false;
          return InkWell(
              child: Container(
                constraints: BoxConstraints(maxHeight: 0.09.sh),
                padding: const EdgeInsets.all(10),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          child: IotShortNameCircular(
                              type: 'P', creatorName: data[index].creatorName),
                          padding: const EdgeInsets.only(right: 20)),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Container(
                          child: Column(children: [
                            _showGroupAndTime(data[index].status ?? 0,
                                data[index].groupName ?? ' ', data[index].time),
                            Flexible(
                                child: Align(
                                  child: _showTitleMessage(data[index].title,
                                      data[index].status ?? 0),
                                  alignment: Alignment.centerLeft,
                                ),
                                fit: FlexFit.loose)
                          ]),
                          decoration: const BoxDecoration(
                              border: Border(
                            bottom: BorderSide(color: Colors.black12),
                          )),
                        ),
                      ),
                    ]),
              ),
              onTap: () async => await IotNavigatorInternalMessage().onTap(
                  context,
                  data[index].originalId,
                  data[index].originalCreator,
                  data[index].groupName ?? '',
                  false,
                  widget.messageContent));
        });
  }

  Widget _showGroupAndTime(int status, String groupName, int time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            groupName,
            style: TextStyle(
                color: status == 0 ? Colors.black : Colors.black87,
                fontSize: SP_SMALL_COMMON_FONT_SIZE.sp,
                fontWeight: status == 0 ? FontWeight.bold : FontWeight.normal),
          ),
          fit: FlexFit.loose,
        ),
        Text(IotUtility().parseTimeMessage(time),
            style: TextStyle(
                color: Colors.black87,
                fontSize: SP_SMALL_COMMON_FONT_SIZE.sp,
                fontWeight: FontWeight.normal))
      ],
    );
  }

  Widget _showTitleMessage(String title, int status) {
    return Text(
      title,
      style: TextStyle(
          color: status == 0 ? Colors.black87 : Colors.black54,
          fontSize: SP_COMMON_FONT_SIZE.sp,
          fontWeight: status == 0 ? FontWeight.bold : FontWeight.normal),
    );
  }
}
