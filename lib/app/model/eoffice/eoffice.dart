class Eoffice {
  final int id;
  final String title;
  final int localNo;
  final String date;
  final String creator;
  String filename;

  Eoffice(
      {required this.id,
      required this.title,
      required this.localNo,
      required this.date,
      required this.creator,
      required this.filename});

  factory Eoffice.fromJson(Map<String, dynamic> json) {
    return Eoffice(
        id: json['id'],
        title: json['title'],
        localNo: json['localNo'] ?? 0,
        date: json['date'],
        creator: json['creator'],
        filename: json['filename'] ?? '');
  }


}
