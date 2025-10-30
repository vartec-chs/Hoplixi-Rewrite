import 'dart:io';

import 'package:hoplixi/core/constants/main_constants.dart';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppPaths {
  static Future<String> get appStoragePath async =>
      await _getApplicationStoragePath();
  static Future<String> get tempPath async => await _getTempPath();
  static Future<String> get boxDbPath async => await _getBoxDbPath();
  static Future<void> clearTempDirectory() async => await _clearTempDirectory();
  static Future<Directory> get appPath async => await _getAppPath();
  static Future<String> get appLogsPath async => await _getAppLogsPath();
  static Future<String> get appCrashReportsPath async =>
      await _getAppCrashReportsPath();
  static Future<String> get exportStoragesPath async =>
      await _getExportStoragesPath();
  static Future<String> get cloudSyncFilePath async =>
      await _getCloudSyncFilePath();
}

/// Получение пути к директории приложения
Future<Directory> _getAppPath() async {
  // final appDir = await getApplicationSupportDirectory();
  Directory appDir;
  if (Platform.isAndroid) {
    appDir = await getApplicationSupportDirectory();
  } else if (Platform.isIOS) {
    appDir = await getApplicationSupportDirectory();
  } else {
    appDir = await getApplicationDocumentsDirectory();
  }
  final basePath = p.join(appDir.path, MainConstants.appFolderName);

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return directory;
}

/// Logs directory
Future<String> _getAppLogsPath() async {
  final appDir = await _getAppPath();
  final logPath = p.join(appDir.path, 'logs');

  // Создаем директорию если её нет
  final directory = Directory(logPath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return logPath;
}

/// Crash reports directory extend logs
Future<String> _getAppCrashReportsPath() async {
  final appDir = await _getAppLogsPath();
  final crashPath = p.join(appDir, 'crash_reports');

  // Создаем директорию если её нет
  final directory = Directory(crashPath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return crashPath;
}

/// Получение пути к директории для хранения данных приложения
Future<String> _getApplicationStoragePath() async {
  final appDir = await _getAppPath();
  final basePath = p.join(appDir.path, 'storages');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}

/// Cloud sync file json
Future<String> _getCloudSyncFilePath() async {
  final appDir = Directory(await _getApplicationStoragePath());
  final basePath = p.join(appDir.path, 'cloud_sync.json');

  return basePath;
}

/// Export storages path
Future<String> _getExportStoragesPath() async {
  final appDir = Directory(await _getApplicationStoragePath());
  final basePath = p.join(appDir.path, 'exports');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}

/// Получение пути к временной директории приложения
Future<String> _getTempPath() async {
  final tempDir = await getTemporaryDirectory();
  final basePath = p.join(tempDir.path, MainConstants.appFolderName, 'temp');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}

/// Очистка временной директории приложения
Future<void> _clearTempDirectory() async {
  try {
    final tempPath = await _getTempPath();
    final tempDir = Directory(tempPath);

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create(recursive: true);
      logInfo('Временная директория очищена', tag: 'AppFiles');
    }
  } catch (e) {
    logError('Ошибка при очистке временной директории: $e', tag: 'AppFiles');
  }
}

/// Получение пути к директории для хранения базы данных Box
Future<String> _getBoxDbPath() async {
  final appDir = await _getAppPath();
  final basePath = p.join(appDir.path, 'box');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}
