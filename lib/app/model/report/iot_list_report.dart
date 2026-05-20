class IotListReport {
  final String? code;
  final String? title;
  final String? note;

  IotListReport({this.code, this.title, this.note});
  factory IotListReport.fromJson(Map<String, dynamic> json) {
    return IotListReport(
        code: json['code'], title: json['title'], note: json['note']);
  }
}