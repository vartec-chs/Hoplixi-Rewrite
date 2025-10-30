import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';
import 'di_init.dart';
import 'app.dart';

void main() async {
  if (UniversalPlatform.isWeb) {
    throw UnsupportedError(
      'Web platform is not supported in this version. Please use a different platform.',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  await setupDI();
  runApp(const App());
}
