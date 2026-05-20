import 'dart:async';

import 'package:dngmsp/app/model/report/manual_report.dart';
import 'package:dngmsp/app/service/report/manual_report/manual_report_service.dart';

class IotManualReportStream {

  Map<String, dynamic> _mapReportParameters = Map();
  Map<String, dynamic> _mapRequiredValues = Map();

  var _parameterController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get parameterStream => _parameterController.stream;
  void disposeParameterStream() => _parameterController.close();

  var _valueController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get valueStream => _valueController.stream;
  void disposeValueStream() => _valueController.close();

  Future<List<IotManualReport>> fetchIotReports(String reportCode) async {
    return await IotManualReportService().fetchIotReports(reportCode);
  }

  Map<String, dynamic> getParametersMap() {
    return _mapReportParameters;
  }

  Map<String, dynamic> getValuesMap() {
    return _mapRequiredValues;
  }

  void setMapReportParameters(List<IotManualReport> list) {
    _mapReportParameters = Map();
    _mapRequiredValues = Map();
    list.forEach((element) {
      _mapReportParameters.putIfAbsent(element.id!, () => element.value);
      _mapRequiredValues.putIfAbsent(element.id!, () => element.required);
    });
    _parameterController.sink.add(_mapReportParameters);
    _valueController.sink.add(_mapRequiredValues);
  }

  void setDateTextField(String id, DateTime selectedDate) {
    _mapReportParameters.update(id, (value) =>
    "${selectedDate.day <= 9 ? '0' : ''}${selectedDate.day}/"
        "${selectedDate.month <= 9 ? '0' : ''}${selectedDate.month}/"
        "${selectedDate.year}");
    _parameterController.sink.add(_mapReportParameters);
  }

  void setDropdownTextField(String id, dynamic selectedItemValue) {
    _mapReportParameters.update(id, (value) => selectedItemValue);
    _parameterController.sink.add(_mapReportParameters);
  }

  void setTextField(String id, String text) {
    _mapReportParameters.update(id, (value) => text);
    _parameterController.sink.add(_mapReportParameters);
  }

  void setNumberTextField(String id, String number) {
    _mapReportParameters.update(id, (value) => number);
    _parameterController.sink.add(_mapReportParameters);
  }
}