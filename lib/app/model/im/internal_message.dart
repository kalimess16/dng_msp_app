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

  IotInternalMessage({
    required this.originalId,
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
    this.groupName,
  });

  factory IotInternalMessage.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    String parseString(dynamic value, [String defaultValue = '']) {
      return value?.toString() ?? defaultValue;
    }

    return IotInternalMessage(
      originalId: parseInt(json['originalId']),
      originalCreator: parseString(json['originalCreator']),
      id: parseInt(json['id']),
      creator: parseString(json['creator']),
      title: parseString(json['title']),
      time: parseInt(json['time']),
      status: parseInt(json['status']),
      creatorName: parseString(json['creatorName']),
      emotion: parseInt(json['emotion']),
      notificationId: parseInt(json['notificationId']),
      hasFile: parseString(json['hasFile'], 'N'),
      groupName: parseString(json['groupName'], ' '),
    );
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
    'emotion': message.emotion ?? 0,
  };
}
