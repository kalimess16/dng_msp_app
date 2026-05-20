class IotPosition {
  final String id;
  final String name;
  final int countMembers;
  String? shortName;
  bool? selected;

  IotPosition(
      {required this.id,
      required this.name,
      required this.countMembers,
      this.shortName,
      this.selected});
  factory IotPosition.fromJson(Map<String, dynamic> json) {
    return IotPosition(
        id: json['id'],
        name: json['name'],
        countMembers: json['countMembers'],
        shortName: json['shortName'],
        selected: false);
  }
}
