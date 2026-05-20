class IotAutoReport {
  final int id;
  final String title;
  int? status;
  final String creator;
  final int time;
  final String reportDate;
  final String reportType;
  final String? note;
  final int? notificationId;

  IotAutoReport(
      {required this.id,
      required this.title,
      this.status,
      required this.creator,
      required this.time,
      required this.reportDate,
      required this.reportType,
      this.note,
      this.notificationId});

  factory IotAutoReport.fromJson(Map<String, dynamic> json) {
      return IotAutoReport(
        id: json['id'],
        title: json['title'],
        status: json['status'] ?? 0,
        creator: json['creator'],
        time: json['time'],
        reportDate: json['reportDate'],
        reportType: json['type'],
      );
  }

}
