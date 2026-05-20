class IotEmotionUser {
  final String name;
  final String isCreator;
  final String description;
  IotEmotionUser(
      {required this.name,
      required this.isCreator,
      required this.description});

  factory IotEmotionUser.fromJson(Map<String, dynamic> json) {
    return IotEmotionUser(
        name: json['name'],
        isCreator: json['isCreator'],
        description: json['description']);
  }
}
