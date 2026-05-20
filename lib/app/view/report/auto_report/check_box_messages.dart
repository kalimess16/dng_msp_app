import 'list_auto_report_page.dart';
import 'package:flutter/material.dart';

class IotAutoReportCheckbox extends StatefulWidget {
  final String index;
  IotAutoReportCheckbox(this.index);

  @override
  _IotAutoReportCheckboxState createState() => _IotAutoReportCheckboxState();
}

class _IotAutoReportCheckboxState extends State<IotAutoReportCheckbox> {
  bool selected = false;
  @override
  void initState() {
    super.initState();
    selected = false;
  }

  @override
  Widget build(BuildContext context) {
    return Checkbox(
        value: selected,
        onChanged: (bool? value) {
          setState(() {
            selected = value ?? false;
            IotListAutoReportPage.mapSelectedMessages
                .update(widget.index, (value) => selected);
          });
        });
  }
}
