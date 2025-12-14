import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/setup_tray.dart';
import 'package:toastification/toastification.dart';
import 'package:universal_platform/universal_platform.dart';
import 'di_init.dart';

import 'app.dart';

Future<void> main() async {
  if (UniversalPlatform.isWeb) {
    throw UnsupportedError(
      'Web platform is not supported in this version. Please use a different platform.',
    );
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load(fileName: ".env");

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
          // Crash report settings
          maxCrashReportCount: 50,
          maxCrashReportFileSize: 5 * 1024 * 1024, // 5MB
          crashReportRetentionPeriod: Duration(days: 30),
        ),
      );

      setupErrorHandling();
      await WindowManager.initialize();
      await setupDI();
      await setupTray();

      final app = ProviderScope(
        observers: [LoggingProviderObserver()],
        child: setupToastificationWrapper(const App()),
      );

      runApp(app);
    },
    (error, stackTrace) {
      // Записываем краш-репорт для неперехваченных ошибок
      logCrash(
        message: 'Uncaught error',
        error: error,
        stackTrace: stackTrace,
        errorType: 'UncaughtError',
      );

      Toaster.error(title: 'Глобальная ошибка', description: error.toString());
    },
  );
}

Widget setupToastificationWrapper(Widget app) {
  return ToastificationWrapper(
    config: ToastificationConfig(
      maxTitleLines: 2,
      clipBehavior: Clip.hardEdge,
      maxDescriptionLines: 5,
      maxToastLimit: 3,
      itemWidth: UniversalPlatform.isDesktop ? 400 : double.infinity,
      alignment: UniversalPlatform.isDesktop
          ? Alignment.bottomRight
          : Alignment.topCenter,
      marginBuilder: (context, alignment) {
        if (UniversalPlatform.isDesktop) {
          return const EdgeInsets.only(right: 8, bottom: 28);
        } else {
          return EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
          );
        }
      },
    ),
    child: app,
  );
}

void setupErrorHandling() {
  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore specific debugNeedsLayout assertion error WoltModalSheet Flutter issue
    if (details.exceptionAsString().contains(
      "Failed assertion: line 3047 pos 12: '!debugNeedsLayout': is not true.",
    )) {
      return;
    }

    // Записываем краш-репорт для Flutter ошибок
    logCrash(
      message: 'Flutter error',
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      errorType: 'FlutterError',
    );

    Toaster.error(
      title: 'Ошибка Flutter',
      description: details.exceptionAsString(),
    );
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    // Записываем краш-репорт для платформенных ошибок
    logCrash(
      message: 'Platform error',
      error: error,
      stackTrace: stackTrace,
      errorType: 'PlatformError',
    );

    Toaster.error(title: 'Ошибка платформы', description: error.toString());
    return true;
  };

  // Optional: Catch errors in the widget tree
  ErrorWidget.builder = (errorDetails) {
    logCrash(
      message: 'Widget error',
      error: errorDetails.exception,
      stackTrace: errorDetails.stack ?? StackTrace.current,
      errorType: 'WidgetError',
    );
    Toaster.error(
      title: 'Ошибка виджета',
      description: errorDetails.exceptionAsString(),
    );
    return ErrorWidget(errorDetails.exception);
  };
}
