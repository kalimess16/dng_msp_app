class IotDetailContentReportsStream {
  String? stickyLegend;
  double stickyWidth = 0;
  List<String>? titleRows;
  final List<String> titleColumns = [];
  final List<List<String>> dataTable = [];
  final Map<int, double> customCellWidth = {};
  final Map<int, String> customCellAlignment = {};

  void makeDataReport(var detailReports) {
    final names = detailReports[0].title.split('~');
    detailReports.removeAt(0);

    for (var i = 0; i < names.length; i++) {
      var details = names[i].split('^');

      if (i == 0) {
        stickyLegend = details[0];
        final configuredWidth = details.length > 1
            ? double.tryParse(details[1])
            : null;
        if (configuredWidth != null && configuredWidth > 0) {
          stickyWidth = configuredWidth;
        }
      } else {
        titleColumns.add(details[0]);
        final configuredWidth = details.length > 1
            ? double.tryParse(details[1])
            : null;
        if (configuredWidth != null && configuredWidth > 0) {
          customCellWidth.putIfAbsent(i - 1, () => configuredWidth);
        }
        if (details.length > 2 && details[2].isNotEmpty) {
          customCellAlignment.putIfAbsent(i - 1, () => details[2]);
        }
      }
    }

    titleRows = List.generate(
      detailReports.length,
      (index) => detailReports[index].title,
    );
    for (int col = 0; col < titleColumns.length; col++) {
      final List<String> rows = [];
      for (int r = 0; r < titleRows!.length; r++) {
        var caps = detailReports[r].content.split('~');
        rows.add(caps[col]);
      }
      dataTable.add(rows);
    }
  }
}
