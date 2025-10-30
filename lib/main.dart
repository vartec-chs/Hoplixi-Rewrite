import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:universal_platform/universal_platform.dart';
import 'di_init.dart';
import 'app.dart';

void main() async {
  if (UniversalPlatform.isWeb) {
    throw UnsupportedError(
      'Web platform is not supported in this version. Please use a different platform.',
    );
  }

  final ensureInitialized = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize AppLogger
  await AppLogger.instance.initialize(
    config: const LoggerConfig(
      maxFileSize: 10 * 1024 * 1024, // 10MB
      maxFileCount: 5,
      bufferSize: 50,
      bufferFlushInterval: Duration(seconds: 15),
      enableDebug: true,
      enableInfo: true,
      enableWarning: true,
      enableError: true,
      enableTrace: MainConstants.isProduction
          ? false
          : true, // Disable trace logs in production
      enableFatal: true,
      enableConsoleOutput: true,
      enableFileOutput: true,
      enableCrashReports: true,
    ),
  );

  await setupDI();
  runApp(const App());
}
