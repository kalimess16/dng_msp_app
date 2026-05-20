class IotUser {
  late final String fullName;
  late final String wsToken;
  late final String username;

  IotUser({required this.fullName, required this.wsToken, required this.username});

  factory IotUser.fromJson(Map<String, dynamic> json) {
    return IotUser(
        fullName: json['fullname'], wsToken: json['wstoken'], username: json['username']);
  }
}
