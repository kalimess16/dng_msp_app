import 'dart:async';

import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/eoffice/result_eoffice_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/eoffice/search_eoffice_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchEofficePage extends StatefulWidget {
  @override
  _SearchEofficePageState createState() => _SearchEofficePageState();
}

class _SearchEofficePageState extends State<SearchEofficePage> {
  var _streamController = StreamController<List<dynamic>>.broadcast();
  Stream<List<dynamic>> get _stream => _streamController.stream;

  late List<dynamic> _list;
  late final TextEditingController _controller;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _toDate = DateTime.now();
  List<String> _types = ['-- TẤT CẢ --', 'Văn bản đến', 'Văn bản đi'];
  String _selectedType = '';
  List<String> _agencies = [];
  String _selectedAgency = '';
  bool _selectedDateTime = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _streamController.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IotPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, false, 'Tìm văn bản'),
        body: FutureBuilder(
            future: SearchEofficeStream().fetchEofficeAgencies(0),
            builder: ((context, snapshot) {
              if (snapshot.hasData) {
                _agencies = snapshot.data as List<String>;
                _selectedType = _types[0];
                _selectedAgency = _agencies[0];
                _list = [
                  _selectedType,
                  _selectedAgency,
                  _selectedDateTime,
                  [_fromDate, _toDate]
                ];
                return _bodyPage();
              }
              if (snapshot.hasError)
                return IotExceptionPage(exception: snapshot.error);
              return IotCircularProgressWidget();
            })),
        backgroundColor: Colors.white,
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, false),
    );
  }

  Widget _bodyPage() {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypes(),
        _buildAgencies(),
        _buildChosenDateTime(),
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

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => ResultEofficePage(
                _types.indexOf(_selectedType),
                _agencies.indexOf(_selectedAgency),
                _selectedFromDate,
                _selectedToDate,
                _controller.text)));
  }

  Widget _buildTypes() {
    List<PopupMenuEntry> menuItems = [];
    _types.forEach((name) {
      menuItems.add(PopupMenuItem(
        child: Text(
          name,
          style: TextStyle(color: Colors.white),
        ),
        value: name,
      ));
    });
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loại văn bản',
                style: TextStyle(
                    fontSize: SP_COMMON_FONT_SIZE.sp, color: Colors.black54)),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(width: 0.25))),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamBuilder(
                        stream: _stream,
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            _selectedType = snapshot.data[0];
                          }
                          return Flexible(
                            child: Text(
                              '$_selectedType',
                              style: TextStyle(
                                  fontSize: SP_COMMON_FONT_SIZE.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                            fit: FlexFit.loose,
                          );
                        }),
                    PopupMenuButton(
                        icon: Icon(
                          Icons.arrow_drop_down_circle_outlined,
                          size: 0.1.sw,
                          color: IOT_BG_COLOR,
                        ),
                        color: Colors.green,
                        onSelected: (selectedItemValue) {
                          _list[0] = '$selectedItemValue';
                          _streamController.sink.add(_list);
                        },
                        itemBuilder: (context) => menuItems)
                  ]),
            ),
          ],
        ));
  }

  Widget _buildAgencies() {
    List<PopupMenuEntry> menuItems = [];
    _agencies.forEach((name) {
      menuItems.add(PopupMenuItem(
        child: Text(
          name,
          style: TextStyle(color: Colors.white),
        ),
        value: name,
      ));
    });
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cơ quan ban hành',
                style: TextStyle(
                    fontSize: SP_COMMON_FONT_SIZE.sp, color: Colors.black54)),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(width: 0.25))),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamBuilder(
                        stream: _stream,
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            _selectedAgency = snapshot.data[1];
                          }
                          return Flexible(
                            child: Text(
                              '$_selectedAgency',
                              style: TextStyle(
                                  fontSize: SP_COMMON_FONT_SIZE.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                            fit: FlexFit.loose,
                          );
                        }),
                    PopupMenuButton(
                        icon: Icon(
                          Icons.arrow_drop_down_circle_outlined,
                          size: 0.1.sw,
                          color: IOT_BG_COLOR,
                        ),
                        color: Colors.green,
                        onSelected: (selectedItemValue) {
                          _list[1] = '$selectedItemValue';
                          _streamController.sink.add(_list);
                        },
                        itemBuilder: (context) => menuItems)
                  ]),
            ),
          ],
        ));
  }

  Widget _buildChosenDateTime() {
    return StreamBuilder(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            _selectedDateTime = snapshot.data[2];
          }
          return Container(
              width: double.infinity,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SwitchListTile(
                        value: _selectedDateTime,
                        title: Text(
                          'Theo Thời gian',
                          style: TextStyle(
                              fontSize: SP_COMMON_FONT_SIZE.sp,
                              fontWeight: FontWeight.bold),
                        ),
                        onChanged: (bool? value) {
                          _list[2] = value ?? false;
                          _streamController.sink.add(_list);
                        }),
                    Offstage(
                      offstage: !_selectedDateTime,
                      child: _buildDateTime(),
                    ),
                  ]));
        });
  }

  Widget _buildDateTime() {
    return StreamBuilder(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            List<DateTime> _dates = snapshot.data[3];
            _fromDate = _dates[0];
            _toDate = _dates[1];
          }
          return Container(
              padding: const EdgeInsets.only(left: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black12)),
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
                                style: TextStyle(
                                    fontSize: SP_COMMON_FONT_SIZE.sp)),
                            onPressed: () async {
                              var _date = await IotUtility()
                                  .chooseDate(context, _fromDate);
                              _list[3] = [_date, _toDate];

                              _streamController.sink.add(_list);
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
                                style: TextStyle(
                                    fontSize: SP_COMMON_FONT_SIZE.sp)),
                            onPressed: () async {
                              var _date = await IotUtility()
                                  .chooseDate(context, _toDate);
                              _list[3] = [_fromDate, _date];
                              _streamController.sink.add(_list);
                            }),
                      ),
                    ],
                  )
                ],
              ));
        });
  }

  Widget _buildContentMessage() {
    return TextFormField(
      controller: _controller,
      maxLines: 1,
      style: TextStyle(color: Colors.black, fontSize: SP_COMMON_FONT_SIZE.sp),
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: 'Từ cần tìm',
        hintStyle: const TextStyle(color: Colors.black26),
        isDense: true,
        border: const OutlineInputBorder(
            borderSide: BorderSide(color: IOT_BG_COLOR)),
      ),
    );
  }
}
