class OAuthConfig {
  static const String redirectUri = 'http://localhost:8569/callback';
  static const String redirectUriMobile = 'hoplixiauth://callback';

  static const List<String> googleScopes = [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'openid',
  ];

  static const List<String> onedriveScopes = [
    'openid',
    'profile',
    'email',
    'User.Read',
  ];

  static const List<String> dropboxScopes = [
    "account_info.read",
    "files.content.read",
    "files.content.write",
    "files.metadata.write",
    "files.metadata.read",
    'openid',
    'email',
    "profile",
  ];

  static const List<String> yandexScopes = [
    'login:info',
    'disk:info',
    'disk:read',
    'disk:write',
  ];
}
