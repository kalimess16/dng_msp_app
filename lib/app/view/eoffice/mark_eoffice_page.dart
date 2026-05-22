import 'dart:async';

import 'package:dngmsp/app/model/eoffice/mark_eoffice.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/eoffice/mark_eoffice_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MarkEofficePage extends StatefulWidget {
  final int eOfficeId;
  final int messageId;
  final String messageCreator;
  final int messageFileOrder;
  MarkEofficePage(
      {required this.eOfficeId,
      required this.messageId,
      required this.messageCreator,
      required this.messageFileOrder});
  @override
  _MarkEofficePageState createState() => _MarkEofficePageState();
}

class _MarkEofficePageState extends State<MarkEofficePage> {
  var _streamController = StreamController<List<dynamic>>.broadcast();
  Stream<List<dynamic>> get _stream => _streamController.stream;

  late final TextEditingController _controllerTitle;
  late final TextEditingController _controllerAgency;
  late final TextEditingController _controllerDate;
  late final TextEditingController _controllerNote;
  List<String> _list = ["", ""];
  List<String> _agencies = [];

  @override
  void initState() {
    super.initState();
    _controllerTitle = TextEditingController();
    _controllerAgency = TextEditingController();
    _controllerDate = TextEditingController();
    _controllerNote = TextEditingController();
  }

  @override
  void dispose() {
    _streamController.close();
    _controllerTitle.dispose();
    _controllerAgency.dispose();
    _controllerDate.dispose();
    _controllerNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IotPopScope(
      child: Scaffold(
        appBar: IotAppBar().build(context, false, 'PHÂN LOẠI VĂN BẢN'),
        body: FutureBuilder(
            future: MarkEofficeStream().fetchMarkEoffice(
                widget.eOfficeId,
                widget.messageId,
                widget.messageCreator,
                widget.messageFileOrder),
            builder: ((context, snapshot) {
              if (snapshot.hasData) {
                MarkEoffice _markEoffice = snapshot.data as MarkEoffice;
                _controllerTitle.text = _markEoffice.tieude;
                _controllerAgency.text = _markEoffice.tencoquan;
                _controllerDate.text = _markEoffice.ngaygui;
                _controllerNote.text = _markEoffice.ghichu;

                _list[0] = _markEoffice.tencoquan;
                _list[1] = _markEoffice.ngaygui;

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
        _buildTitle(),
        _buildAgencies(),
        _buildDateTime(),
        _buildNote(),
        Row(
          children: [
            Expanded(
                child: ElevatedButton(
                    onPressed: () async => await _save(),
                    child: Text(
                      'Lưu trữ',
                      style: TextStyle(fontSize: SP_LARGER_COMMON_FONT_SIZE.sp),
                    ))),
          ],
        ),
      ],
    ));
  }

  Future<void> _save() async {
    if (_controllerTitle.text.isEmpty || _controllerAgency.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Chưa nhập đầy đủ thông tin !!'),
      ));
      return;
    }
    List<String> _date = _controllerDate.text.split('/');
    //print(DateTime.parse(
    //    '${_date[2].padLeft(2, '0')}-${_date[1].padLeft(2, '0')}-${_date[0]}'));
    if (_date.isEmpty || _date.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ngày văn bản nhập chưa đúng !!'),
      ));
      return;
    }
    var _year = int.tryParse(_date[2]) ?? 0,
        _month = int.tryParse(_date[1]) ?? 0,
        _day = int.tryParse(_date[0]) ?? 0;
    if (_year < 2000 ||
        _year > 2050 ||
        _month <= 0 ||
        _month >= 13 ||
        _day <= 0 ||
        _day >= 32) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ngày văn bản nhập chưa đúng !!'),
      ));
    }
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return SimpleDialog(contentPadding: EdgeInsets.all(60), children: [
            FutureBuilder<bool>(
                future: MarkEofficeStream().saveMarkEoffice(
                    widget.eOfficeId,
                    widget.messageId,
                    widget.messageCreator,
                    widget.messageFileOrder,
                    _controllerTitle.text,
                    _controllerAgency.text,
                    _controllerDate.text,
                    _controllerNote.text),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    bool _isOk = snapshot.data as bool;
                    Navigator.of(context).pop(_isOk);
                  } else if (snapshot.hasError) {
                    Navigator.of(context).pop(false);
                  }
                  return IotCircularProgressWidget();
                })
          ]);
        }).then((value) {
      if (!value)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('KHÔNG LƯU ĐƯỢC !!')));
      else
        Navigator.of(context).pop();
    });
  }

  Widget _buildTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(top: 5, left: 5),
          child: Text('Tiêu đề',
              style: TextStyle(
                  color: Colors.black54, fontSize: SP_COMMON_FONT_SIZE.sp))),
      TextFormField(
        controller: _controllerTitle,
        style: TextStyle(color: Colors.black, fontSize: SP_COMMON_FONT_SIZE.sp),
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
            hintText: 'Tiêu đề của văn bản',
            hintStyle: const TextStyle(color: Colors.black26),
            contentPadding: EdgeInsets.only(left: 10)),
      )
    ]);
  }

  Widget _buildAgencies() {
    return FutureBuilder(
        future: MarkEofficeStream().fetchMarkEofficeAgencies(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            _agencies = snapshot.data as List<String>;
            return _buildAgencyItems();
          }
          if (snapshot.hasError)
            return IotExceptionPage(exception: snapshot.error);
          return Container(
              child: CircularProgressIndicator(),
              alignment: Alignment.centerRight);
        }));
  }

  Widget _buildAgencyItems() {
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(top: 5, left: 5),
          child: Text('Cơ quan ban hành',
              style: TextStyle(
                  color: Colors.black54, fontSize: SP_COMMON_FONT_SIZE.sp))),
      Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StreamBuilder(
                stream: _stream,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    _list[0] = snapshot.data[0];
                  }
                  return Flexible(
                    child: TextFormField(
                      controller: _controllerAgency,
                      maxLines: 1,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: SP_COMMON_FONT_SIZE.sp),
                      decoration: InputDecoration(
                          hintText: 'Cơ quan ban hành',
                          hintStyle: const TextStyle(color: Colors.black26),
                          contentPadding: EdgeInsets.only(left: 10)),
                      keyboardType: TextInputType.text,
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
                  _controllerAgency.text = _list[0];
                  _streamController.sink.add(_list);
                },
                itemBuilder: (context) => menuItems)
          ])
    ]);
  }

  Widget _buildDateTime() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(top: 5, left: 5),
          child: Text('Ngày ban hành',
              style: TextStyle(
                  color: Colors.black54, fontSize: SP_COMMON_FONT_SIZE.sp))),
      Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StreamBuilder(
                stream: _stream,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    _list[1] = snapshot.data[1];
                  }
                  return Flexible(
                    child: TextFormField(
                      controller: _controllerDate,
                      maxLines: 1,
                      keyboardType: TextInputType.datetime,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: SP_COMMON_FONT_SIZE.sp),
                      decoration: InputDecoration(
                          hintText: 'Ngày văn bản',
                          hintStyle: const TextStyle(color: Colors.black26),
                          contentPadding: EdgeInsets.only(left: 10)),
                    ),
                    fit: FlexFit.loose,
                  );
                }),
            IconButton(
                onPressed: () async {
                  var _date = await IotUtility().chooseDate(
                      context,
                      (_list[1].isNotEmpty
                          ? DateTime.parse(
                              '${_list[1].substring(6)}-${_list[1].substring(3, 5)}-${_list[1].substring(0, 2)}')
                          : DateTime.now()));
                  _list[1] = '${_date.year}/${_date.month}/${_date.day}';
                  _controllerDate.text =
                      '${_date.day}/${_date.month}/${_date.year}';
                  _streamController.sink.add(_list);
                },
                icon: Icon(Icons.calendar_month,
                    color: IOT_BG_COLOR, size: 0.1.sw))
          ])
    ]);
  }

  Widget _buildNote() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(top: 5, left: 5),
          child: Text('Ghi chú',
              style: TextStyle(
                  color: Colors.black54, fontSize: SP_COMMON_FONT_SIZE.sp))),
      TextFormField(
        controller: _controllerNote,
        maxLines: 3,
        style: TextStyle(color: Colors.black, fontSize: SP_COMMON_FONT_SIZE.sp),
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: 'Ghi chú của bạn',
          hintStyle: const TextStyle(color: Colors.black26),
          contentPadding: const EdgeInsets.only(left: 10, top: 3),
        ),
      )
    ]);
  }
}
