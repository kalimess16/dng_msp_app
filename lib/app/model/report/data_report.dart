class IotDataReport {
  final String? code;
  final String? title;
  final String? content;

  IotDataReport({this.code, this.title, this.content});
  factory IotDataReport.fromJson(Map<String, dynamic> json) {
    return IotDataReport(
        code: json['code'], title: json['title'], content: json['content']);
  }
}