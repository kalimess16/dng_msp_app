import 'package:dngmsp/app/model/report/manual_report.dart';
import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:dngmsp/app/view/report/manual_report/detail_manual_report_page.dart';
import 'package:dngmsp/app/view/widget/app_bar.dart';
import 'package:dngmsp/app/view/widget/bottom_navigator_bar.dart';
import 'package:dngmsp/app/view/widget/circular_progress_widget.dart';
import 'package:dngmsp/app/view/widget/exception_widget.dart';
import 'package:dngmsp/app/viewmodel/report/manual_report/manual_report_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotManualReportPage extends StatefulWidget {
  final String? reportCode;
  final String? reportTitle;
  final String? reportNote;
  IotManualReportPage({this.reportCode, this.reportTitle, this.reportNote});

  @override
  _IotManualReportPageState createState() => _IotManualReportPageState();
}

class _IotManualReportPageState extends State<IotManualReportPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late List<Widget> _listItems;
  late IotManualReportStream _manualReportStream;

  bool get _isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  double get _commonFontSize => _isLandscape ? 18 : SP_COMMON_FONT_SIZE.sp;

  double get _fieldValueFontSize => _isLandscape ? 22 : SP_COMMON_FONT_SIZE.sp;

  double get _fieldIconSize => _isLandscape ? 42 : 0.1.sw;

  @override
  void initState() {
    super.initState();
    _manualReportStream = IotManualReportStream();
  }

  @override
  void dispose() {
    _manualReportStream.disposeParameterStream();
    _manualReportStream.disposeValueStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IotPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: IotAppBar().build(context, false, widget.reportTitle!),
        body: _buildBodyPage(),
        bottomNavigationBar: IotBottomNavigatorBar(),
      ),
      onWillPop: () => IotAppBar().backIotPages(context, false),
    );
  }

  Widget _buildBodyPage() {
    return FutureBuilder<List<IotManualReport>>(
      future: _manualReportStream.fetchIotReports(widget.reportCode!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _manualReportStream.setMapReportParameters(
            snapshot.data as List<IotManualReport>,
          );
          return _buildForm(snapshot.data as List<IotManualReport>);
        } else if (snapshot.hasError) {
          return IotExceptionPage(exception: snapshot.error);
        } else
          return IotCircularProgressWidget();
      },
    );
  }

  Widget _buildForm(List<IotManualReport> data) {
    _listItems = _buildListView(data);
    _listItems.add(_buildSubmitButton());

    if (widget.reportNote != null && widget.reportNote!.length > 0) {
      _listItems.add(
        Container(
          child: Text(
            "*** ${widget.reportNote}",
            style: TextStyle(color: Colors.red, fontSize: _commonFontSize),
          ),
          alignment: Alignment.bottomLeft,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: _isLandscape ? 8 : 10,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _listItems,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: EdgeInsets.only(top: _isLandscape ? 8 : 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            child: Text(
              "Thực hiện",
              style: TextStyle(color: IOT_BG_COLOR, fontSize: _commonFontSize),
            ),
            onPressed: () => submit(),
          ),
          const SizedBox(width: 20),
          OutlinedButton(
            child: Text(
              "Quay ra",
              style: TextStyle(color: IOT_BG_COLOR, fontSize: _commonFontSize),
            ),
            onPressed: () => IotAppBar().backIotPages(context, false),
          ),
        ],
      ),
    );
  }

  void submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    bool isValidate = true;
    _manualReportStream.getParametersMap().forEach((key, value) {
      if ((_manualReportStream.getValuesMap()[key] ?? 'X') == 'Y' &&
          (value == null || value.toString().isEmpty)) {
        isValidate = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Chưa nhập đầy đủ các thông số (*)",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
          ),
        );
        return;
      }
    });
    if (!isValidate) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return IotDetailManualReportPage(
            messageType: IOT_SPECIFIC_REPORT_KEY,
            type: widget.reportCode,
            title: widget.reportTitle,
            note: widget.reportNote,
            mapSpecReportParameters: _manualReportStream.getParametersMap(),
          );
        },
      ),
    );
  }

  List<Widget> _buildListView(List<IotManualReport> data) {
    List<Widget> list = [];
    data.forEach((element) {
      list.add(
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: _isLandscape ? 4 : 8,
          ),
          child: (element.dataType == 'D'
              ? _buildDateTextField("${element.id}", "${element.description}")
              : element.dataType == 'S'
              ? _buildDropdownTextField(
                  "${element.id}",
                  element.dropDownList!,
                  "${element.description}",
                )
              : element.dataType == 'N'
              ? _buildNumberTextField("${element.id}", "${element.description}")
              : _buildTextField("${element.id}", "${element.description}")),
        ),
      );
    });
    return list;
  }

  Widget _buildDateTextField(String id, String description) {
    String? sDate;
    DateTime date = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: description,
            children: <TextSpan>[
              TextSpan(
                text: ((_manualReportStream.getValuesMap()[id] ?? 'X') == 'Y'
                    ? ' *'
                    : ''),
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
          style: TextStyle(fontSize: _commonFontSize),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _manualReportStream.parameterStream,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<Map<String, dynamic>> snapshot,
                      ) {
                        if (snapshot.hasData) {
                          var data = snapshot.data as Map<String, dynamic>;
                          sDate = data[id];
                        } else
                          sDate = _manualReportStream.getParametersMap()[id];
                        sDate = sDate ?? '';

                        date = DateTime.now().subtract(Duration(days: 1));
                        if (sDate!.isNotEmpty) {
                          var parse = sDate!.split("/");
                          date = DateTime(
                            int.tryParse(parse[2]) ?? 2021,
                            int.tryParse(parse[1]) ?? 1,
                            int.tryParse(parse[0]) ?? 1,
                          );
                        }
                        return Text(
                          sDate!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: _fieldValueFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.date_range_outlined,
                  size: _fieldIconSize,
                  color: IOT_BG_COLOR,
                ),
                onPressed: () async {
                  var selectedDate = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2015, 01, 01),
                    lastDate: DateTime(2055),
                    helpText: description,
                    confirmText: "Đồng ý",
                    cancelText: "Đóng",
                    errorFormatText: "DD/MM/YYYY",
                    errorInvalidText: "Sai định dạng",
                    locale: const Locale('vi', 'VI'),
                    builder: (BuildContext? context, Widget? child) {
                      return Theme(
                        data: ThemeData(primarySwatch: Colors.green),
                        child: child ?? Text(""),
                      );
                    },
                  );
                  if (selectedDate == null) return;
                  _manualReportStream.setDateTextField(id, selectedDate);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTextField(
    String id,
    Map<String, dynamic> dropDownList,
    String description,
  ) {
    List<PopupMenuEntry> menuItems = [];
    dropDownList.forEach((code, name) {
      menuItems.add(
        PopupMenuItem(
          child: Text(name, style: TextStyle(color: Colors.white)),
          value: code,
        ),
      );
    });
    String? _selectedValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: description,
            children: <TextSpan>[
              TextSpan(
                text: ((_manualReportStream.getValuesMap()[id] ?? 'X') == 'Y'
                    ? ' *'
                    : ''),
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          style: TextStyle(fontSize: _commonFontSize),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _manualReportStream.parameterStream,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<Map<String, dynamic>> snapshot,
                      ) {
                        if (snapshot.hasData) {
                          var data = snapshot.data as Map<String, dynamic>;
                          _selectedValue = data[id];
                        } else
                          _selectedValue = _manualReportStream
                              .getParametersMap()[id];

                        _selectedValue = _selectedValue ?? '';

                        return Text(
                          _selectedValue!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: _fieldValueFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.arrow_drop_down_circle_outlined,
                  size: _fieldIconSize,
                  color: IOT_BG_COLOR,
                ),
                color: Colors.green,
                onSelected: (selectedItemValue) => _manualReportStream
                    .setDropdownTextField(id, selectedItemValue),
                itemBuilder: (context) => menuItems,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String id, String description) {
    String? _textValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: description,
            children: <TextSpan>[
              TextSpan(
                text: ((_manualReportStream.getValuesMap()[id] ?? 'X') == 'Y'
                    ? ' *'
                    : ''),
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          style: TextStyle(fontSize: _commonFontSize),
        ),
        StreamBuilder(
          stream: _manualReportStream.parameterStream,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<Map<String, dynamic>> snapshot,
              ) {
                if (snapshot.hasData) {
                  var data = snapshot.data as Map<String, dynamic>;
                  _textValue = data[id];
                } else
                  _textValue = _manualReportStream.getParametersMap()[id];
                _textValue = _textValue ?? '';

                return TextFormField(
                  initialValue: _textValue,
                  validator: (text) {
                    if ((_textValue ?? 'X') == 'Y' && text!.isEmpty)
                      return 'Chưa nhập ' + description;
                    if (text!.isEmpty) return null;

                    _manualReportStream.setTextField(id, text);
                    return null;
                  },
                  style: TextStyle(
                    fontSize: _fieldValueFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: IOT_BG_COLOR,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }

  Widget _buildNumberTextField(String id, String description) {
    String? _numberValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: description,
            children: <TextSpan>[
              TextSpan(
                text: ((_manualReportStream.getValuesMap()[id] ?? 'X') == 'Y'
                    ? ' *'
                    : ''),
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          style: TextStyle(fontSize: _commonFontSize),
        ),
        StreamBuilder(
          stream: _manualReportStream.parameterStream,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<Map<String, dynamic>> snapshot,
              ) {
                if (snapshot.hasData) {
                  var data = snapshot.data as Map<String, dynamic>;
                  _numberValue = data[id];
                } else
                  _numberValue = _manualReportStream.getParametersMap()[id];
                _numberValue = _numberValue ?? '';

                return TextFormField(
                  initialValue: _numberValue,
                  validator: (number) {
                    if ((_numberValue ?? 'X') == 'Y' && number!.isEmpty)
                      return 'Chưa nhập ' + description;
                    if (number!.isEmpty) return null;
                    double value = double.tryParse(number) ?? -1;
                    if (value > -1)
                      _manualReportStream.setNumberTextField(id, number);
                    else
                      return description + ' - không phải là ký tự số ';
                    return null;
                  },
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                  ],
                  style: TextStyle(
                    fontSize: _fieldValueFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: IOT_BG_COLOR,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}
