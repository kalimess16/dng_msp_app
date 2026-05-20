import 'package:dngmsp/app/view/report/auto_report/auto_report_page.dart';
import 'package:dngmsp/app/viewmodel/report/auto_report/list_auto_report_stream.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IotNavigatorAutoReportPage {
  Future<void> onTap(BuildContext context, int id, String type, String date,
      String title, bool onBackground) async {
    context.read<IotListAutoReportStream>().readAutoReport(id, type);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => IotAutoReportPage(
                code: id, type: type, date: date, title: title)));
  }
}
