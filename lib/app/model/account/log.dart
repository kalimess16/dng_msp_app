class IotAccountLog {
  String? gmail;
  String? fullName;
  String? lastLogTime;

  IotAccountLog({this.gmail, this.fullName, required this.lastLogTime});

  factory IotAccountLog.fromJson(Map<String, dynamic> json) {
    return IotAccountLog(fullName: json['fullname'], gmail: json['gmail'], lastLogTime: json['lastLogTime']);
  }
}