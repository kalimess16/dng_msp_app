class IotInternalMessage {
  final int originalId;
  final String originalCreator;
  final int id;
  final String creator;
  late final String title;
  final int time;
  int? status;
  final String creatorName;
  int? emotion;
  int? notificationId;
  String? hasFile;
  String? groupName;

  IotInternalMessage(
      {required this.originalId,
      required this.originalCreator,
      required this.id,
      required this.creator,
      required this.title,
      required this.time,
      this.status,
      required this.creatorName,
      this.emotion,
      this.notificationId,
      this.hasFile,
      this.groupName});

  factory IotInternalMessage.fromJson(Map<String, dynamic> json) {
    return IotInternalMessage(
        originalId: json['originalId'],
        originalCreator: json['originalCreator'],
        id: json['id'],
        creator: json['creator'],
        title: json['title'],
        time: json['time'],
        status: json['status'] ?? 0,
        creatorName: json['creatorName'],
        emotion: json['emotion'] ?? 0,
        hasFile: json['hasFile'] ?? 'N',
        groupName: json['groupName'] ?? ' ');
  }

  Map<String, dynamic> toJson(IotInternalMessage message) => {
        'originalId': message.originalId,
        'originalCreator': message.originalCreator,
        'id': message.id,
        'creator': message.creator,
        'title': message.title,
        'time': message.time,
        'status': message.status,
        'creatorName': message.creatorName,
        'emotion': message.emotion ?? 0
      };
}
