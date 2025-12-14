import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final file = File('./oauth2_account.json');
  final account = OAuth2Account(
    appPrefix: 'oauth2restclientexample',
    tokenStorage: OAuth2TokenStorageJson(file: file),
  );
  final provider = Yandex(
    clientId: env['YANDEX_CLIENT_ID']!,
    clientSecret: env['YANDEX_CLIENT_SECRET']!,
    redirectUri: 'http://localhost:8569/callback',
    scopes: [
      'login:email',
      'login:info',
      "cloud_api:disk.write",
      "cloud_api:disk.read",
      'cloud_api:disk.app_folder',
      'cloud_api:disk.info',
    ],
  );
  final serviceName = provider.name;

  account.addProvider(provider);

  print('Открываю браузер для авторизации...');
  final token = await account.newLogin(serviceName);
  if (token != null) {
    print('Токен получен и сохранен!');
  } else {
    print('Ошибка: токен не получен.');
  }
}
