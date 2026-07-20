import 'package:dngmsp/app/model/report/manual_report.dart';
import 'package:dngmsp/app/viewmodel/report/manual_report/manual_report_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps dropdown selection when report parameters initialize again', () {
    final stream = IotManualReportStream();
    addTearDown(() {
      stream.disposeParameterStream();
      stream.disposeValueStream();
    });

    final reports = <IotManualReport>[
      IotManualReport(
        id: 'searchBy',
        description: 'Tìm theo',
        dataType: 'S',
        required: 'Y',
        dropDownList: const <String, dynamic>{
          'CMT': 'Số CMT',
          'MAKH': 'Mã số KH (CIF)',
        },
        value: '',
      ),
    ];

    stream.initializeMapReportParameters(reports);
    stream.setDropdownTextField('searchBy', 'CMT');

    // A widget rebuild must not reset values to the API defaults.
    stream.initializeMapReportParameters(reports);

    expect(stream.getParametersMap()['searchBy'], 'CMT');
  });
}
