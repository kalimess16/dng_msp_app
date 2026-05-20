import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lazy_data_table/lazy_data_table.dart';

class IotContentReportPage {
  Widget buildLazyTable(BuildContext context, dynamic iotReportsViewModel) {
    const Color _stickyColor = Color.fromRGBO(110, 110, 110, 250);
    double _stickyWidth = iotReportsViewModel.stickyWidth;
    return LazyDataTable(
      rows: iotReportsViewModel.titleRows.length,
      columns: iotReportsViewModel.titleColumns.length,
      tableTheme: LazyDataTableTheme(
          columnHeaderBorder: Border.all(color: IOT_GRID_BORDER_COLOR),
          rowHeaderBorder: Border.all(color: IOT_GRID_BORDER_COLOR, width: 0.8),
          cornerBorder: Border.all(color: IOT_GRID_BORDER_COLOR, width: 0.8),
          cellBorder: Border.all(color: IOT_GRID_BORDER_COLOR, width: 0.8),
          alternateCellBorder: Border.all(color: IOT_GRID_BORDER_COLOR, width: 0.8),
          columnHeaderColor: _stickyColor,
          rowHeaderColor: _stickyColor,
          cornerColor: _stickyColor,
          alternateRow: false,
          alternateColumn: false,
      ),
      tableDimensions: LazyDataTableDimensions(
        customCellWidth: iotReportsViewModel.customCellWidth ?? {},
        leftHeaderWidth:
            (iotReportsViewModel.stickyWidth == 0 ? 0.45.sw : _stickyWidth.sw),
        rightHeaderWidth: 0.085.sh,
        cellWidth: 0.25.sw,
        cellHeight: 0.075.sh
      ),
      topLeftCornerWidget: Center(
          child: RichText(
        text: TextSpan(
            text: iotReportsViewModel.stickyLegend,
            style: TextStyle(
                color: Colors.black,
                fontSize: 37.sp,
                fontWeight: FontWeight.bold)),
        textAlign: TextAlign.center,
        softWrap: true,
      )),
      topHeaderBuilder: (i) => Center(
          child: RichText(
        text: TextSpan(
            text: iotReportsViewModel.titleColumns[i],
            style: TextStyle(
                color: Colors.black,
                fontSize: 37.sp,
                fontWeight: FontWeight.bold)),
        textAlign: TextAlign.center,
        softWrap: true,
      )),
      leftHeaderBuilder: (i) {
        return Container(
          child: showFullContentCell(context, iotReportsViewModel.titleRows[i],
              TextStyle(fontSize: 37.sp)),
          padding: EdgeInsets.only(left: 5),
          alignment: Alignment.centerLeft,
        );
      },
      dataCellBuilder: (i, j) {
        Alignment _alignment;
        EdgeInsets _padding = EdgeInsets.zero;

        if (iotReportsViewModel.customCellAlignment == null ||
            iotReportsViewModel.customCellAlignment[j] == null) {
          _alignment = Alignment.centerRight;
          _padding = EdgeInsets.only(right: 5);
        } else if (iotReportsViewModel.customCellAlignment[j] == 'L') {
          _alignment = Alignment.centerLeft;
          _padding = EdgeInsets.only(left: 5);
        } else
          _alignment = Alignment.center;

        Color _color = Colors.black87;
        var _listColors = iotReportsViewModel.dataTable[j][i].split('^');
        var _cellValue = _listColors[0];

        if (_listColors != null && _listColors.length == 2) {
          switch (_listColors[1]) {
            case 'R':
              _color = Colors.red;
              break;
            case 'G':
              _color = IOT_BG_COLOR;
              break;
            case 'O':
              _color = Colors.orange;
              break;
          }
        }
        return Container(
          child: Text(_cellValue,
              style: TextStyle(
                  color: _color,
                  fontWeight: (_color != Colors.black87
                      ? FontWeight.bold
                      : FontWeight.normal),
                  fontSize: 37.sp)),
          alignment: _alignment,
          padding: _padding,
        );
      },
    );

  }

  Widget showFullContentCell(
      BuildContext context, String content, TextStyle textStyle) {
    return GestureDetector(
        child: Text(content, style: textStyle),
        onDoubleTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) => AlertDialog(
              content: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'OK',
                    style: TextStyle(color: IOT_BG_COLOR),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        });
  }
}
