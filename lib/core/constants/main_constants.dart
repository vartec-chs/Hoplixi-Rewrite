import 'package:flutter/services.dart';

class MainConstants {
  static const String appName = 'Hoplixi';
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String appFolderName = 'hoplixi';

  static const Size defaultWindowSize = Size(650, 720);
  static const Size minWindowSize = Size(400, 500);
  static const Size maxWindowSize = Size(1000, 1000);
  static const bool isCenter = true;

  static const int databaseSchemaVersion = 1;
}
