/// Dropbox 계정 정보를 나타내는 클래스입니다.
class DropboxAccount {
  final String accountId;
  final String email;
  final String name;
  final String? profilePhotoUrl;
  final bool disabled;
  final String? country;

  DropboxAccount({
    required this.accountId,
    required this.email,
    required this.name,
    this.profilePhotoUrl,
    required this.disabled,
    this.country,
  });

  factory DropboxAccount.fromJson(Map<String, dynamic> json) {
    return DropboxAccount(
      accountId: json['account_id'] as String,
      email: json['email'] as String,
      name: json['name']['display_name'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      disabled: json['disabled'] as bool,
      country: json['country'] as String?,
    );
  }
}
