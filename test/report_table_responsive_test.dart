import 'package:dngmsp/app/view/report/content_report_page.dart';
import 'package:dngmsp/app/viewmodel/report/detail_content_report_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_data_table/lazy_data_table.dart';

void main() {
  const longCriterion =
      '(CN)03 - Danh sách người được ủy quyền và người ủy quyền (03/KTNB)';
  const columns = <String>['PQ.NAM', 'PT.PHƯỚC', 'PN.GIANG'];
  const data = <List<String>>[
    <String>['0', '66'],
    <String>['49', '69'],
    <String>['5', '8'],
  ];

  IotReportTableMetrics calculate({
    required double width,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return IotReportTableMetrics.calculate(
      viewportWidth: width,
      stickyLegend: 'Tiêu chí',
      stickyWidthFactor: 0.45,
      titleRows: const <String>['Ngắn', longCriterion],
      titleColumns: columns,
      dataTable: data,
      configuredCellWidth: const <int, double>{0: 0.145, 1: 0.145, 2: 0.145},
      textScaler: textScaler,
      textDirection: TextDirection.ltr,
    );
  }

  test('expands long rows instead of clipping them on a narrow screen', () {
    final metrics = calculate(width: 320);

    expect(metrics.leftHeaderWidth, 160);
    expect(metrics.customCellHeight[1]!, greaterThan(44));
    expect(
      metrics.customCellHeight[1]!,
      greaterThan(metrics.customCellHeight[0]!),
    );
    expect(
      metrics.customCellWidth.values,
      everyElement(greaterThanOrEqualTo(64)),
    );
  });

  test('recalculates dimensions for wide screens and large system text', () {
    final narrow = calculate(width: 320);
    final wide = calculate(width: 800);
    final largeText = calculate(
      width: 320,
      textScaler: const TextScaler.linear(2),
    );

    expect(wide.leftHeaderWidth, greaterThan(narrow.leftHeaderWidth));
    expect(wide.bodyFontSize, greaterThan(narrow.bodyFontSize));
    expect(
      largeText.customCellHeight[1]!,
      greaterThan(narrow.customCellHeight[1]!),
    );
  });

  test('keeps sane dimensions at common phone and tablet widths', () {
    for (final width in <double>[320, 375, 768, 1024, 1440]) {
      final metrics = calculate(width: width);

      expect(metrics.leftHeaderWidth, lessThan(width));
      expect(metrics.bodyFontSize, inInclusiveRange(12, 16));
      expect(metrics.customCellHeight.values, everyElement(greaterThan(0)));
      expect(metrics.customCellWidth.values, everyElement(greaterThan(0)));
    }
  });

  testWidgets('renders the report table without overflow at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final report = IotDetailContentReportsStream()
      ..stickyLegend = 'Tiêu chí'
      ..stickyWidth = 0.45
      ..titleRows = const <String>['Ngắn', longCriterion]
      ..titleColumns.addAll(columns)
      ..dataTable.addAll(data)
      ..customCellWidth.addAll(const <int, double>{
        0: 0.145,
        1: 0.145,
        2: 0.145,
      });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                IotContentReportPage().buildLazyTable(context, report),
          ),
        ),
      ),
    );
    await tester.pump();

    final table = tester.widget<LazyDataTable>(find.byType(LazyDataTable));
    expect(tester.takeException(), isNull);
    expect(find.text(longCriterion), findsOneWidget);
    expect(
      table.tableDimensions.customCellHeight[1]!,
      greaterThan(table.tableDimensions.customCellHeight[0]!),
    );

    await tester.binding.setSurfaceSize(const Size(568, 320));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(longCriterion), findsOneWidget);
  });
}
