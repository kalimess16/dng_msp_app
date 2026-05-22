import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/routes.dart';
import 'package:dngmsp/app/resource/var/app_static_variable.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/view/widget/short_name_circular_widget.dart';
import 'package:dngmsp/app/viewmodel/im/reply/list_internal_message_stream.dart';
import 'package:dngmsp/app/viewmodel/im/reply/navigator_internal_message.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotListInternalMessagesPage extends StatefulWidget {
  static Map<String, bool> mapSelectedMessages = {};
  @override
  _IotListInternalMessagesPageState createState() =>
      _IotListInternalMessagesPageState();
}

class _IotListInternalMessagesPageState
    extends State<IotListInternalMessagesPage>
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
    IotStaticVariable.iotOnReplyInternalMessagePage = false;

    _scrollController.addListener(() async {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!_accessTimes.contains(_lastAccessTime)) {
          _status = await context
              .read<IotListInternalMessageStream>()
              .loadMoreIotInternalMessages(context, _lastAccessTime);
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
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 2;
    return WillPopScope(
      child: Scaffold(
        appBar: _appBar(),
        body: _bodyListMessage(),
        backgroundColor: const Color(0xFFF4F8F5),
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, true),
    );
  }

  AppBar _appBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: IOT_BG_COLOR,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () async =>
            await Navigator.of(context).pushNamed(IotRoutes.SEARCH_MSP_PAGE),
        icon: const Icon(Icons.search_sharp, size: 28),
      ),
      centerTitle: true,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'THÔNG TIN NỘI BỘ',
          style: TextStyle(
            color: IOT_FG_COLOR,
            fontWeight: FontWeight.bold,
            fontSize: SP_COMMON_FONT_SIZE.sp,
          ),
        ),
      ),
      actions: [
        IconButton(
          padding: const EdgeInsets.only(right: 12),
          onPressed: () async => await Navigator.of(
            context,
          ).pushNamed(IotRoutes.COMPOSE_MSP_PAGE_IN_LIST),
          icon: const Icon(Icons.add_outlined, size: 30),
        ),
      ],
    );
  }

  Widget _bodyListMessage() {
    var _hasInitiation = false;
    return Consumer<IotListInternalMessageStream>(
      builder: (context, fcm, _) {
        return FutureBuilder(
          future: context
              .watch<IotListInternalMessageStream>()
              .initIotInternalMessages(context, _hasInitiation),
          builder: ((context, snapshot) {
            if (snapshot.hasData) {
              _hasInitiation = true;
              var data = snapshot.data as List<IotInternalMessage>;
              return _listMessageItem(data);
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

  Widget _listMessageItem(List<IotInternalMessage> data) {
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
                                    .read<IotListInternalMessageStream>()
                                    .loadMoreIotInternalMessages(
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            elevation: (data[index].status ?? 0) == 0 ? 2 : 1,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      child: IotShortNameCircular(
                        type: 'P',
                        creatorName: data[index].creatorName,
                      ),
                      padding: const EdgeInsets.only(right: 10),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _showGroupAndTime(
                            data[index].status ?? 0,
                            data[index].groupName ?? ' ',
                            data[index].time,
                          ),
                          const SizedBox(height: 6),
                          _showTitleMessage(
                            data[index].title,
                            data[index].status ?? 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () async => await IotNavigatorInternalMessage().onTap(
                context,
                data[index].originalId,
                data[index].originalCreator,
                data[index].groupName ?? '',
                false,
                '',
              ),
            ),
          ),
        );
      },
    );
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
              fontWeight: status == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          fit: FlexFit.loose,
        ),
        Text(
          IotUtility().parseTimeMessage(time),
          style: TextStyle(
            color: Colors.black87,
            fontSize: SP_SMALL_COMMON_FONT_SIZE.sp,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _showTitleMessage(String title, int status) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: status == 0 ? Colors.black87 : Colors.black54,
        fontSize: SP_COMMON_FONT_SIZE.sp,
        fontWeight: status == 0 ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
