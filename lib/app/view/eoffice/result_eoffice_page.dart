import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dngmsp/app/model/eoffice/eoffice.dart';
import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/eoffice/search_eoffice_stream.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResultEofficePage extends StatefulWidget {
  final int type;
  final int agency;
  final String fromDate;
  final String toDate;
  final String keyword;
  ResultEofficePage(
      this.type, this.agency, this.fromDate, this.toDate, this.keyword);

  @override
  _ResultEofficePageState createState() => _ResultEofficePageState();
}

class _ResultEofficePageState extends State<ResultEofficePage> {
  int _lastId = 0;
  final List<Eoffice> _listEoffices = [];
  final List<int> _accessIds = [];
  ScrollController _scrollController = ScrollController();

  var _streamController = StreamController<String>.broadcast();
  Stream<String> get _stream => _streamController.stream;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() async {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!_accessIds.contains(_lastId)) {
          _streamController.sink.add('WAIT');
          var _map = await SearchEofficeStream().loadMoreEoffices(
              context,
              widget.type,
              widget.agency,
              widget.fromDate,
              widget.toDate,
              widget.keyword,
              _lastId,
              1);
          if (_map['VALUE'] != null) _listEoffices.addAll(_map['VALUE']);
          _streamController.sink.add(_map['STATUS']);
          _accessIds.add(_lastId);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IotBottomNavigatorBar.selectedIotBottomNavigatorBar = 2;
    return IotPopScope(
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
    return FutureBuilder(
        future: SearchEofficeStream().fetchEoffices(widget.type, widget.agency,
            widget.fromDate, widget.toDate, widget.keyword, 0, 0),
        builder: ((context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _listEoffices.clear();
            _listEoffices.addAll(snapshot.data as List<Eoffice>);
            return _listMessageItem();
          }
          if (snapshot.hasError)
            return IotExceptionPage(
                exception: snapshot.error, isBackHome: true);
          return IotCircularProgressWidget();
        }));
  }

  Widget _listMessageItem() {
    if (_listEoffices.isEmpty)
      return Center(
          child: Text(
        'KHÔNG TÌM THẤY VĂN BẢN',
        style: TextStyle(
            color: IOT_BG_COLOR,
            fontSize: SP_COMMON_FONT_SIZE.sp,
            fontWeight: FontWeight.bold),
      ));
    return StreamBuilder(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          print("TEST ${snapshot.hasData}");
          return ListView.builder(
              itemCount: _listEoffices.length + 1,
              controller: _scrollController,
              itemBuilder: (context, index) {
                if (index == _listEoffices.length - 1)
                  _lastId = _listEoffices[index].id;
                if (index == _listEoffices.length)
                  return _loadMoreWidget(snapshot);

                return InkWell(
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 0.12.sh),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: Container(
                                child: Column(children: [
                                  _showGroupAndTime(
                                      _listEoffices[index].creator,
                                      _listEoffices[index].date),
                                  Flexible(
                                      child: Align(
                                        child: _showTitleMessage(
                                            _listEoffices[index].title),
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
                    onTap: () async => _onTapChild(_listEoffices[index].id));
              });
        });
  }

  Widget _loadMoreWidget(AsyncSnapshot snapshot) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: (snapshot.connectionState == ConnectionState.active &&
                  snapshot.hasData
              ? (snapshot.data == 'WAIT'
                  ? CircularProgressIndicator()
                  : (snapshot.data == 'OK'
                      ? SizedBox()
                      : TextButton(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  snapshot.data == 'CONNECT'
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
                            var _map = await SearchEofficeStream()
                                .loadMoreEoffices(
                                    context,
                                    widget.type,
                                    widget.agency,
                                    widget.fromDate,
                                    widget.toDate,
                                    widget.keyword,
                                    _lastId,
                                    1);
                            if (_map['VALUE'] != null)
                              _listEoffices.addAll(_map['VALUE']);
                            _streamController.sink.add(_map['STATUS']);
                          })))
              : CircularProgressIndicator()),
        ));
  }

  Widget _showGroupAndTime(String name, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            name,
            style: TextStyle(
                color: Colors.black54, fontSize: SP_SMALL_COMMON_FONT_SIZE.sp),
          ),
          fit: FlexFit.loose,
        ),
        Text(date,
            style: TextStyle(
                color: Colors.black54, fontSize: SP_SMALL_COMMON_FONT_SIZE.sp))
      ],
    );
  }

  Widget _showTitleMessage(String title) {
    title = (title.length > 80 ? title.substring(0, 79) + '...' : title);
    return Text(
      title,
      style: TextStyle(color: Colors.black, fontSize: SP_COMMON_FONT_SIZE.sp),
    );
  }

  void _onTapChild(int docId) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return SimpleDialog(contentPadding: EdgeInsets.all(60), children: [
            FutureBuilder<IotDownloadFile>(
                future: SearchEofficeStream().downloadDataFiles(docId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Navigator.of(context).pop();
                    _previewDownloadFile(snapshot.data as IotDownloadFile);
                  } else if (snapshot.hasError) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('KHÔNG THỂ TẢI VỀ FILE NÀY !!')));
                  }
                  return IotCircularProgressWidget();
                })
          ]);
        });
  }

  void _previewDownloadFile(IotDownloadFile downloadFile) async {
    Directory _path = await getTemporaryDirectory();
    File _tempFile = File('${_path.path}/${downloadFile.fileName}');
    var raf = _tempFile.openSync(mode: FileMode.write);
    raf.writeFromSync(base64Decode(downloadFile.fileData));
    await raf.close();
    OpenResult result = await OpenFile.open(_tempFile.path);
    if (result.type == ResultType.noAppToOpen)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CHƯA CÀI ĐẶT APP ĐỂ ĐỌC ĐỊNH DẠNG FILE NÀY')));
  }
}
