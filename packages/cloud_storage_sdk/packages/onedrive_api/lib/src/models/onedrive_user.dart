/// OneDrive 사용자 정보를 나타내는 클래스입니다.
class OneDriveUser {
  final String id;
  final String displayName;
  final String? givenName;
  final String? surname;
  final String? mail;
  final String? userPrincipalName;

  OneDriveUser({
    required this.id,
    required this.displayName,
    this.givenName,
    this.surname,
    this.mail,
    this.userPrincipalName,
  });

  factory OneDriveUser.fromJson(Map<String, dynamic> json) {
    return OneDriveUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      givenName: json['givenName'] as String?,
      surname: json['surname'] as String?,
      mail: json['mail'] as String?,
      userPrincipalName: json['userPrincipalName'] as String?,
    );
  }
}
