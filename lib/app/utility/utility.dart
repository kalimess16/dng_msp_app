import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class IotUtility {
  Future<bool> checkInternetConnection(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      "MẤT KẾT NỐI INTERNET",
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.bold),
    )));
    return false;
  }

  String parseTimeMessage(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var now = DateTime.now();
    return (now.year == date.year && now.month == date.month
        ? '${date.day}/${date.month} ' ' ${date.hour}:${date.minute < 9 ? '0' : ''}${date.minute}'
        : '${date.day}/${date.month}/${date.year}');
  }

  String parseTimeAutoReport(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    var now = DateTime.now();

    var diff = now.difference(date);
    return diff.inDays == 0 && date.day == now.day
        ? ((date.hour <= 9 ? '0' : '') +
            '${date.hour}:' +
            (date.minute <= 9 ? '0' : '') +
            '${date.minute}')
        : (now.year == date.year
            ? ((date.day <= 9 ? '0' : '') +
                '${date.day}/' +
                (date.month <= 9 ? '0' : '') +
                '${date.month}')
            : '${date.day}/${date.month}/${date.year}');
  }

  String applicationMineType(String _mimeType) {
    switch (_mimeType) {
      case 'application/vnd.ms-excel':
        return 'XLS';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'DOC';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return 'PPT';
      case 'application/pdf':
        return 'PDF';
      default:
        return '';
    }
  }

  Future<DateTime> chooseDate(context, date) async {
    var _selectedDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2021, 01, 01),
      lastDate: DateTime(2055),
      confirmText: "Đồng ý",
      cancelText: "Đóng",
      errorFormatText: "DD/MM/YYYY",
      errorInvalidText: "Sai định dạng",
      locale: const Locale('vi', 'VI'),
      builder: (BuildContext? context, Widget? child) {
        return Theme(
          data: ThemeData(primarySwatch: Colors.green),
          child: child ?? Text(""),
        );
      },
    );
    return _selectedDate ?? date;
  }
}
