import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Google OAuth2
  static String get googleClientId =>
      dotenv.env['GOOGLE_CLIENT_ID'] ?? 'YOUR_GOOGLE_CLIENT_ID';
  static String get googleClientSecret =>
      dotenv.env['GOOGLE_CLIENT_SECRET'] ?? 'YOUR_GOOGLE_CLIENT_SECRET';

  // Microsoft OAuth2
  static String get microsoftClientId =>
      dotenv.env['ONEDRIVE_CLIENT_ID'] ?? 'YOUR_MICROSOFT_CLIENT_ID';
  static String get microsoftClientSecret =>
      dotenv.env['MICROSOFT_CLIENT_SECRET'] ?? '';

  // Dropbox OAuth2
  static String get dropboxClientId =>
      dotenv.env['DROPBOX_CLIENT_ID'] ?? 'YOUR_DROPBOX_CLIENT_ID';

  // Yandex OAuth2
  static String get yandexClientId =>
      dotenv.env['YANDEX_CLIENT_ID'] ?? 'YOUR_YANDEX_CLIENT_ID';
  static String get yandexClientSecret =>
      dotenv.env['YANDEX_CLIENT_SECRET'] ?? 'YOUR_YANDEX_CLIENT_SECRET';
}
