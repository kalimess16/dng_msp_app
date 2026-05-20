import 'package:dngmsp/app/model/im/position.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/im/compose/list_postions_page.dart';
import 'package:dngmsp/app/view/im/search/result_internal_messages_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/im/compose/position_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotSearchInternalMessagesPage extends StatefulWidget {
  @override
  _IotSearchInternalMessagesPageState createState() =>
      _IotSearchInternalMessagesPageState();
}

class _IotSearchInternalMessagesPageState
    extends State<IotSearchInternalMessagesPage> {
  late final IotPositionStream _positionStream;
  late final TextEditingController _controller;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _toDate = DateTime.now();
  List<String> _senders = [];
  bool _selectedDateTime = false;
  bool _selectedSender = false;

  @override
  void initState() {
    super.initState();
    _positionStream = IotPositionStream();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _positionStream.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, false, 'Tìm Thông tin'),
        body: SingleChildScrollView(child: _bodyPage()),
        backgroundColor: Colors.white,
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, false),
    );
  }

  Widget _bodyPage() {
    return Container(
        child: Column(
      children: [
        _buildChosenDateTime(),
        Offstage(
          offstage: !_selectedDateTime,
          child: _buildDateTime(),
        ),
        _buildChosenSender(),
        Offstage(
          offstage: !_selectedSender,
          child: _buildSender(),
        ),
        _buildContentMessage(),
        Row(
          children: [
            Expanded(
                child: ElevatedButton(
                    onPressed: () async => await _search(),
                    child: Text(
                      'Tìm kiếm',
                      style: TextStyle(fontSize: SP_LARGER_COMMON_FONT_SIZE.sp),
                    ))),
          ],
        ),
      ],
    ));
  }

  Future<void> _search() async {
    String _selectedFromDate = '';
    String _selectedToDate = '';
    if (_selectedDateTime) {
      if (_fromDate.isAfter(_toDate))
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Từ ngày lớn hơn Đến ngày'),
        ));
      else {
        _selectedFromDate =
            '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}';
        _selectedToDate = '${_toDate.day}/${_toDate.month}/${_toDate.year}';
      }
    }
    _senders.clear();
    if (_selectedSender) {
      _positionStream.positions
          .where((element) => element.selected == true)
          .forEach((element) {
        _senders.add(element.id);
      });
      if (_senders.isEmpty)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Chưa chọn người gửi/nhận'),
        ));
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => IotResultInternalMessagesPage(
                _selectedFromDate,
                _selectedToDate,
                _senders.join(';'),
                _controller.text)));
  }

  Widget _buildChosenDateTime() {
    return Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: SwitchListTile(
            value: _selectedDateTime,
            title: Text(
              'Thời gian',
              style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
            ),
            onChanged: (bool? value) async {
              setState(() {
                _selectedDateTime = value ?? false;
              });
            }));
  }

  Widget _buildDateTime() {
    return Container(
        margin: const EdgeInsets.only(left: 20, right: 20),
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Từ ngày ',
                  style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                ),
                Expanded(
                  child: TextButton(
                      child: Text(
                          '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}',
                          style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp)),
                      onPressed: () async {
                        _fromDate =
                            await IotUtility().chooseDate(context, _fromDate);
                        setState(() {});
                      }),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Đến ngày ',
                  style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
                ),
                Expanded(
                  child: TextButton(
                      child: Text(
                          '${_toDate.day}/${_toDate.month}/${_toDate.year}',
                          style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp)),
                      onPressed: () async {
                        _toDate =
                            await IotUtility().chooseDate(context, _toDate);
                        setState(() {});
                      }),
                ),
              ],
            )
          ],
        ));
  }

  Widget _buildChosenSender() {
    return Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: SwitchListTile(
            value: _selectedSender,
            title: Text(
              'Người gửi/nhận',
              style: TextStyle(fontSize: SP_COMMON_FONT_SIZE.sp),
            ),
            onChanged: (bool? value) async {
              _selectedSender = value ?? false;
              if (!_selectedSender) {
                setState(() {
                  _positionStream.positions.clear();
                });
                return;
              }
              if (_positionStream.positions.isEmpty) {
                await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return SimpleDialog(
                          contentPadding: EdgeInsets.zero,
                          titlePadding: EdgeInsets.zero,
                          children: [
                            FutureBuilder<List<IotPosition>>(
                                future:
                                    _positionStream.initSearchingPositions(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData)
                                    Navigator.of(context).pop();
                                  if (snapshot.hasError)
                                    return IotExceptionPage(
                                        exception: snapshot.error);
                                  else
                                    return Container(
                                        child: IotCircularProgressWidget(),
                                        width: 120,
                                        height: 120,
                                        color: Colors.black12);
                                })
                          ]);
                    });
              }
              if (_positionStream.positions.isNotEmpty)
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            IotListPositionsPage(_positionStream)));
              if (_selectedSender) {
                var _selectedUsers = _positionStream.positions
                    .where((element) => element.selected == true);
                if (_selectedUsers.isEmpty) _selectedSender = false;
              }
              setState(() {});
            }));
  }

  Widget _buildSender() {
    String _names = '';
    if (_selectedSender) {
      _positionStream.positions
          .where((element) => element.selected == true)
          .forEach((element) {
        _names += element.name + '; ';
      });
    }
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: TextButton(
            child: Text(
              _names,
              style: TextStyle(fontSize: SP_SMALL_COMMON_FONT_SIZE.sp),
            ),
            onPressed: () async {
              if (_positionStream.positions.isNotEmpty)
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            IotListPositionsPage(_positionStream)));
              if (_selectedSender) {
                var _selectedUsers = _positionStream.positions
                    .where((element) => element.selected == true);
                if (_selectedUsers.isEmpty) _selectedSender = false;
              }
              setState(() {});
            }));
  }

  Widget _buildContentMessage() {
    return TextFormField(
      controller: _controller,
      maxLines: 1,
      style: TextStyle(color: Colors.black, fontSize: SP_COMMON_FONT_SIZE.sp),
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: 'Nội dung thông tin',
        hintStyle: const TextStyle(color: Colors.black26),
        isDense: true,
        border: const OutlineInputBorder(
            borderSide: BorderSide(color: IOT_BG_COLOR)),
      ),
    );
  }
}
