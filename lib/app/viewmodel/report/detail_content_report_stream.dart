import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IotDetailContentReportsStream {
  String? stickyLegend;
  double stickyWidth = 0;
  List<String>? titleRows;
  final List<String> titleColumns = [];
  final List<List<String>> dataTable = [];
  final Map<int, double> customCellWidth = {};
  final Map<int, String> customCellAlignment = {};
  bool _isRefreshed = false;

  void makeDataReport(var detailReports) {
    final names = detailReports[0].title.split('~');
    detailReports.removeAt(0);

    for (var i = 0; i < names.length; i++) {
      var details = names[i].split('^');

      if (i == 0) {
        stickyLegend = details[0];
        if (details.length > 1 && double.tryParse(details[1] ?? 0)! > 0) {
          stickyWidth = double.tryParse(details[1])!;
        }
      } else {
        titleColumns.add(details[0]);
        if (details.length > 1 &&
            details[1] != null &&
            double.tryParse(details[1] ?? 0)! > 0) {
          customCellWidth.putIfAbsent(i - 1, () => double.tryParse(details[1])!);
        }
        if (details.length > 2 && details[2] != null) {
          customCellAlignment.putIfAbsent(i - 1, () => details[2]);
        }
      }
    }

    titleRows = List.generate(
        detailReports.length, (index) => detailReports[index].title);
    for (int col = 0; col < titleColumns.length; col++) {
      final List<String> rows = [];
      for (int r = 0; r < titleRows!.length; r++) {
        var caps = detailReports[r].content.split('~');
        rows.add(caps[col]);
      }
      dataTable.add(rows);
    }
  }

  void resizeCustomCellWidth(BuildContext context) {
    if (!_isRefreshed) {
      customCellWidth.forEach((key, value) {
        customCellWidth.update(key, (value) => value.sw);
      });
      for (var i = 0; i < titleColumns.length; i++) {
        if (customCellWidth.containsKey(i)) continue;
        if (dataTable[i][0].contains(" ")) continue;

        int oldLength = 0;
        for (var j = 0; j < titleRows!.length; j++) {
          oldLength = (dataTable[i][j].length > oldLength
              ? dataTable[i][j].length
              : oldLength);
        }
        double cellWidth = (oldLength <= 3
            ? 0.1.sw
            : oldLength *
            0.027.sw *
            0.77 *
            MediaQuery.of(context).textScaleFactor);
        customCellWidth.putIfAbsent(i, () => cellWidth);
      }
      _isRefreshed = true;
    }
  }
}
