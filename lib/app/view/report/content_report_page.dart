import 'dart:math' as math;

import 'package:dngmsp/app/resource/color/app_colors.dart';
import 'package:dngmsp/app/viewmodel/report/detail_content_report_stream.dart';
import 'package:flutter/material.dart';
import 'package:lazy_data_table/lazy_data_table.dart';

class IotReportTableMetrics {
  static const int rowHeaderMaxLines = 6;
  static const int dataCellMaxLines = 4;

  final double leftHeaderWidth;
  final double defaultCellWidth;
  final double topHeaderHeight;
  final double bodyFontSize;
  final double headerFontSize;
  final Map<int, double> customCellWidth;
  final Map<int, double> customCellHeight;

  const IotReportTableMetrics({
    required this.leftHeaderWidth,
    required this.defaultCellWidth,
    required this.topHeaderHeight,
    required this.bodyFontSize,
    required this.headerFontSize,
    required this.customCellWidth,
    required this.customCellHeight,
  });

  factory IotReportTableMetrics.calculate({
    required double viewportWidth,
    required String stickyLegend,
    required double stickyWidthFactor,
    required List<String> titleRows,
    required List<String> titleColumns,
    required List<List<String>> dataTable,
    required Map<int, double> configuredCellWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final safeViewportWidth = viewportWidth.isFinite && viewportWidth > 0
        ? viewportWidth
        : 360.0;
    final bodyFontSize = (safeViewportWidth * 0.034)
        .clamp(12.0, 16.0)
        .toDouble();
    final headerFontSize = (bodyFontSize + 0.5).clamp(12.5, 16.5).toDouble();
    final bodyStyle = TextStyle(fontSize: bodyFontSize, height: 1.3);
    final headerStyle = TextStyle(
      fontSize: headerFontSize,
      height: 1.2,
      fontWeight: FontWeight.bold,
    );

    final minimumLeftWidth = math.min(160.0, safeViewportWidth * 0.5);
    final maximumLeftWidth = math.min(360.0, safeViewportWidth * 0.55);
    final preferredLeftWidth =
        safeViewportWidth * (stickyWidthFactor > 0 ? stickyWidthFactor : 0.45);
    final leftHeaderWidth = preferredLeftWidth
        .clamp(minimumLeftWidth, maximumLeftWidth)
        .toDouble();

    final minimumCellWidth = (safeViewportWidth * 0.2)
        .clamp(56.0, 72.0)
        .toDouble();
    final maximumCellWidth = math.max(
      minimumCellWidth,
      math.min(260.0, safeViewportWidth * 0.72),
    );
    final defaultCellWidth = (safeViewportWidth * 0.22)
        .clamp(minimumCellWidth, math.min(160.0, maximumCellWidth))
        .toDouble();
    final resolvedCellWidth = <int, double>{};

    for (var column = 0; column < titleColumns.length; column++) {
      final values = column < dataTable.length
          ? dataTable[column]
          : const <String>[];
      final longestToken = _longestToken(<String>[
        titleColumns[column],
        ...values.map(visibleCellValue),
      ]);
      final tokenWidth = _measureTextWidth(
        longestToken,
        headerStyle,
        textScaler,
        textDirection,
      );
      final minimumContentWidth = math.max(minimumCellWidth, tokenWidth + 16);
      final configuredWidth = configuredCellWidth[column];
      final preferredWidth = configuredWidth == null
          ? defaultCellWidth
          : configuredWidth <= 1
          ? configuredWidth * safeViewportWidth
          : configuredWidth;
      resolvedCellWidth[column] = math
          .max(preferredWidth, minimumContentWidth)
          .clamp(minimumCellWidth, maximumCellWidth)
          .toDouble();
    }

    var headerTextHeight = _measureTextHeight(
      stickyLegend,
      headerStyle,
      math.max(1, leftHeaderWidth - 16),
      textScaler,
      textDirection,
      maxLines: 3,
    );
    for (var column = 0; column < titleColumns.length; column++) {
      headerTextHeight = math.max(
        headerTextHeight,
        _measureTextHeight(
          titleColumns[column],
          headerStyle,
          math.max(1, resolvedCellWidth[column]! - 12),
          textScaler,
          textDirection,
          maxLines: 3,
        ),
      );
    }
    final topHeaderHeight = (headerTextHeight + 12)
        .clamp(48.0, 144.0)
        .toDouble();

    final baseRowHeight = (bodyFontSize * 3.4).clamp(44.0, 56.0).toDouble();
    final resolvedRowHeight = <int, double>{};
    for (var row = 0; row < titleRows.length; row++) {
      var contentHeight = _measureTextHeight(
        titleRows[row],
        bodyStyle,
        math.max(1, leftHeaderWidth - 16),
        textScaler,
        textDirection,
        maxLines: rowHeaderMaxLines,
      );
      for (var column = 0; column < titleColumns.length; column++) {
        if (column >= dataTable.length || row >= dataTable[column].length) {
          continue;
        }
        final rawCellValue = dataTable[column][row];
        final cellValue = visibleCellValue(rawCellValue);
        if (!RegExp(r'\s').hasMatch(cellValue)) continue;
        final cellStyle = rawCellValue.contains('^')
            ? bodyStyle.copyWith(fontWeight: FontWeight.bold)
            : bodyStyle;
        contentHeight = math.max(
          contentHeight,
          _measureTextHeight(
            cellValue,
            cellStyle,
            math.max(1, resolvedCellWidth[column]! - 12),
            textScaler,
            textDirection,
            maxLines: dataCellMaxLines,
          ),
        );
      }
      resolvedRowHeight[row] = math
          .max(baseRowHeight, contentHeight + 10)
          .clamp(baseRowHeight, 240.0)
          .toDouble();
    }

    return IotReportTableMetrics(
      leftHeaderWidth: leftHeaderWidth,
      defaultCellWidth: defaultCellWidth,
      topHeaderHeight: topHeaderHeight,
      bodyFontSize: bodyFontSize,
      headerFontSize: headerFontSize,
      customCellWidth: resolvedCellWidth,
      customCellHeight: resolvedRowHeight,
    );
  }

  static String visibleCellValue(String rawValue) => rawValue.split('^').first;

  static String _longestToken(Iterable<String> values) {
    var longest = '';
    for (final value in values) {
      for (final token in value.split(RegExp(r'\s+'))) {
        if (token.length > longest.length) longest = token;
      }
    }
    return longest;
  }

  static double _measureTextWidth(
    String text,
    TextStyle style,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  static double _measureTextHeight(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler textScaler,
    TextDirection textDirection, {
    required int maxLines,
  }) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }
}

class IotContentReportPage {
  Widget buildLazyTable(
    BuildContext context,
    IotDetailContentReportsStream iotReportsViewModel,
  ) {
    const stickyColor = Color.fromARGB(255, 224, 242, 230);
    final titleRows = iotReportsViewModel.titleRows ?? const <String>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final metrics = IotReportTableMetrics.calculate(
          viewportWidth: viewportWidth,
          stickyLegend: iotReportsViewModel.stickyLegend ?? '',
          stickyWidthFactor: iotReportsViewModel.stickyWidth,
          titleRows: titleRows,
          titleColumns: iotReportsViewModel.titleColumns,
          dataTable: iotReportsViewModel.dataTable,
          configuredCellWidth: iotReportsViewModel.customCellWidth,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        );
        final bodyStyle = TextStyle(
          color: Colors.black87,
          fontSize: metrics.bodyFontSize,
          height: 1.3,
        );
        final headerStyle = TextStyle(
          color: Colors.black,
          fontSize: metrics.headerFontSize,
          height: 1.2,
          fontWeight: FontWeight.bold,
        );

        return LazyDataTable(
          key: ValueKey<String>(
            'report-table-${constraints.maxWidth.round()}x'
            '${constraints.maxHeight.round()}',
          ),
          rows: titleRows.length,
          columns: iotReportsViewModel.titleColumns.length,
          tableTheme: LazyDataTableTheme(
            columnHeaderBorder: Border.all(color: IOT_GRID_BORDER_COLOR),
            rowHeaderBorder: Border.all(
              color: IOT_GRID_BORDER_COLOR,
              width: 0.8,
            ),
            cornerBorder: Border.all(color: IOT_GRID_BORDER_COLOR, width: 0.8),
            cellBorder: Border.all(color: IOT_GRID_BORDER_COLOR, width: 0.8),
            alternateCellBorder: Border.all(
              color: IOT_GRID_BORDER_COLOR,
              width: 0.8,
            ),
            columnHeaderColor: stickyColor,
            rowHeaderColor: stickyColor,
            cornerColor: stickyColor,
            alternateRow: false,
            alternateColumn: false,
          ),
          tableDimensions: LazyDataTableDimensions(
            customCellWidth: metrics.customCellWidth,
            customCellHeight: metrics.customCellHeight,
            topHeaderHeight: metrics.topHeaderHeight,
            leftHeaderWidth: metrics.leftHeaderWidth,
            rightHeaderWidth: metrics.defaultCellWidth,
            cellWidth: metrics.defaultCellWidth,
            cellHeight: metrics.customCellHeight.values.isEmpty
                ? 48
                : metrics.customCellHeight.values.first,
          ),
          topLeftCornerWidget: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Center(
              child: Text(
                iotReportsViewModel.stickyLegend ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: headerStyle,
              ),
            ),
          ),
          topHeaderBuilder: (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Center(
              child: Text(
                iotReportsViewModel.titleColumns[i],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: headerStyle,
              ),
            ),
          ),
          leftHeaderBuilder: (i) => Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: showFullContentCell(
              context,
              titleRows[i],
              bodyStyle,
              maxLines: IotReportTableMetrics.rowHeaderMaxLines,
            ),
          ),
          dataCellBuilder: (i, j) {
            var alignment = Alignment.centerRight;
            final cellAlignment = iotReportsViewModel.customCellAlignment[j];
            if (cellAlignment == 'L') {
              alignment = Alignment.centerLeft;
            } else if (cellAlignment != null) {
              alignment = Alignment.center;
            }

            var color = Colors.black87;
            final rawValue = iotReportsViewModel.dataTable[j][i];
            final valueParts = rawValue.split('^');
            final cellValue = valueParts.first;
            if (valueParts.length == 2) {
              switch (valueParts[1]) {
                case 'R':
                  color = Colors.red;
                  break;
                case 'G':
                  color = IOT_BG_COLOR;
                  break;
                case 'O':
                  color = Colors.orange;
                  break;
              }
            }
            return Container(
              alignment: alignment,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                cellValue,
                maxLines: IotReportTableMetrics.dataCellMaxLines,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: alignment == Alignment.centerRight
                    ? TextAlign.right
                    : alignment == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                style: bodyStyle.copyWith(
                  color: color,
                  fontWeight: color != Colors.black87
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget showFullContentCell(
    BuildContext context,
    String content,
    TextStyle textStyle, {
    int? maxLines,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) => AlertDialog(
            content: SingleChildScrollView(
              child: Text(content, textAlign: TextAlign.center),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK', style: TextStyle(color: IOT_BG_COLOR)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
      child: Text(
        content,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        softWrap: true,
        style: textStyle,
      ),
    );
  }
}
