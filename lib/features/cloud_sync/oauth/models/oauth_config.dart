class OAuthConfig {
  static const String redirectUri = 'http://localhost:8569/callback';
  static const String redirectUriMobile = 'hoplixiauth://callback';

  static const List<String> googleScopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  static const List<String> onedriveScopes = [
    'Files.ReadWrite.All',
    'User.Read',
  ];

  static const List<String> dropboxScopes = [
    'files.metadata.read',
    'files.content.read',
    'files.content.write',
  ];

  static const List<String> yandexScopes = [
    'login:info',
    'disk:info',
    'disk:read',
    'disk:write',
  ];
}
