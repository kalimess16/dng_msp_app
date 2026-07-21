import 'package:dngmsp/app/view/report/manual_report/list_manual_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses compact manual-report menu metrics in landscape', () {
    final portrait = IotManualReportMenuMetrics.fromViewport(
      const Size(411, 731),
    );
    final landscape = IotManualReportMenuMetrics.fromViewport(
      const Size(731, 411),
    );

    expect(landscape.fontSize, lessThan(portrait.fontSize));
    expect(landscape.fontSize, lessThanOrEqualTo(16));
    expect(landscape.verticalPadding, lessThan(portrait.verticalPadding));
    expect(landscape.iconExtent, lessThan(portrait.iconExtent));
    expect(landscape.itemSpacing, lessThan(portrait.itemSpacing));
  });

  test('keeps menu font within readable bounds on common viewports', () {
    for (final viewport in <Size>[
      const Size(320, 568),
      const Size(568, 320),
      const Size(411, 731),
      const Size(731, 411),
      const Size(800, 1280),
      const Size(1280, 800),
    ]) {
      final metrics = IotManualReportMenuMetrics.fromViewport(viewport);

      expect(metrics.fontSize, inInclusiveRange(14, 18));
      if (viewport.width > viewport.height) {
        expect(metrics.fontSize, lessThanOrEqualTo(16));
      }
    }
  });
}
