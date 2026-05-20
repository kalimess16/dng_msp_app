import 'dart:async';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/report/auto_report.dart';
import 'package:dngmsp/app/service/report/auto_report/list_auto_report_service.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:flutter/material.dart';

class IotListAutoReportStream extends ChangeNotifier {
  final List<IotAutoReport> autoReports = [];

  Future<List<IotAutoReport>> initIotAutoReports(BuildContext context, bool _hasInitiation) async {
    if (!_hasInitiation) {
      autoReports.clear();
      await IotListAutoReportService()
          .fetchAutoReports(DateTime.now().millisecondsSinceEpoch)
          .then((value) async {
        autoReports.addAll(value);
      });
    }
    return autoReports;
  }

  Future<int> loadMoreIotAutoReports(BuildContext context, int startTime) async {
    if (!await IotUtility().checkInternetConnection(context)) return -1;
    return await IotListAutoReportService().fetchAutoReports(startTime).then((value) {
      autoReports.addAll(value);
      notifyListeners();
      return (value.isEmpty ? 1 : 0);
    }).catchError((onError) {
      if (onError is IotException) if (onError.code == 101) return -2;
      return -9;
    });
  }

  Future<IotAutoReport> parseIotFirebaseMessage(Map<String, dynamic> message) async {
    final dynamic data = message['data'] ?? message;
    autoReports.removeWhere((element) =>
        element.id == (int.tryParse(data['id']) ?? 0) &&
        element.reportType == data['reportType']);

    IotAutoReport _ar = IotAutoReport(
        id: int.tryParse(data['id']) ?? 0,
        title: data['title'],
        status: int.tryParse(data['status']) ?? 0,
        creator: data['creator'],
        time: int.tryParse(data['time']) ?? 0,
        reportDate: data['reportDate'],
        reportType: data['reportType'],
        note: data['note'] ?? '',
        notificationId: int.tryParse(data['id']) ?? 0);
    autoReports.add(_ar);
    autoReports.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
    return _ar;
  }

  Future<bool> readAutoReport(int id, String type) async {
    bool _isSuccess = await IotListAutoReportService().readAutoReport(id, type);
    if (_isSuccess) {
      autoReports.forEach((element) {
        if (element.id == id && element.reportType == type) element.status = 1;
      });
    }
    notifyListeners();
    return _isSuccess;
  }

  Future<int> countUnreadAutoReports() async {
    return await IotListAutoReportService().countUnreadAutoReports();
  }
}
