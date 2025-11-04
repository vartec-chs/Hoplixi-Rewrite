import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store_manager.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/provider/db_history_provider.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';

/// Провайдер для MainStoreManager (AsyncNotifier версия)
final mainStoreProvider =
    AsyncNotifierProvider<MainStoreAsyncNotifier, DatabaseState>(
      MainStoreAsyncNotifier.new,
    );

/// state provider
final mainStoreStateProvider = FutureProvider<DatabaseState>((ref) async {
  final state = await ref.watch(mainStoreProvider.future);
  return state;
});

/// Провайдер для получения MainStoreManager по готовности
///
/// Отслеживает состояние БД и предоставляет менеджер только когда хранилище открыто.
/// Возвращает null если хранилище не открыто или находится в процессе открытия/закрытия.
final mainStoreManagerProvider = FutureProvider<MainStoreManager?>((ref) async {
  final asyncState = await ref.watch(mainStoreProvider.future);

  return asyncState.isOpen
      ? ref.read(mainStoreProvider.notifier).currentMainStoreManager
      : null;
});

/// AsyncNotifier для управления состоянием хранилища MainStore
///
/// Предоставляет методы для:
/// - Создания нового хранилища
/// - Открытия существующего хранилища
/// - Закрытия хранилища
/// - Блокировки хранилища
/// - Обновления метаданных
/// - Удаления хранилища
class MainStoreAsyncNotifier extends AsyncNotifier<DatabaseState> {
  static const String _logTag = 'MainStoreAsyncNotifier';

  MainStoreManager? _manager;
  DatabaseHistoryService? _dbHistoryService;

  Future<MainStoreManager> get _getManager async {
    // Если сервис еще не инициализирован, ждем его
    _dbHistoryService ??= await ref.read(dbHistoryProvider.future);

    // Если менеджер еще не создан, создаем его
    _manager ??= MainStoreManager(_dbHistoryService!);

    return _manager!;
  }

  /// Получить текущее значение состояния или дефолтное
  DatabaseState get _currentState {
    return state.value ?? const DatabaseState(status: DatabaseStatus.idle);
  }

  /// Установить новое состояние
  void _setState(DatabaseState newState) {
    state = AsyncValue.data(newState);
  }

  @override
  Future<DatabaseState> build() async {
    // Инициализация с idle состоянием

    _dbHistoryService = await ref.watch(dbHistoryProvider.future);

    logInfo('MainStoreAsyncNotifier initialized', tag: _logTag);
    return const DatabaseState(status: DatabaseStatus.idle);
  }

  /// Создать новое хранилище
  ///
  /// [dto] - данные для создания (имя, описание, пароль)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> createStore(CreateStoreDto dto) async {
    try {
      logInfo('Creating store: ${dto.name}', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем создание хранилища
      final manager = await _getManager;
      final result = await manager.createStore(dto);

      return result.fold(
        (storeInfo) {
          // Успех - обновляем состояние
          _setState(
            DatabaseState(
              path: manager.currentStorePath,
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );

          logInfo(
            'Store created successfully: ${storeInfo.name}',
            tag: _logTag,
          );
          return true;
        },
        (error) {
          // Ошибка - сохраняем в состоянии
          _setState(DatabaseState(status: DatabaseStatus.error, error: error));

          logError('Failed to create store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error creating store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при создании хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Открыть существующее хранилище
  ///
  /// [dto] - данные для открытия (путь, пароль)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> openStore(OpenStoreDto dto) async {
    try {
      logInfo('Opening store at: ${dto.path}', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем открытие хранилища
      final manager = await _getManager;
      final result = await manager.openStore(dto);

      return result.fold(
        (storeInfo) {
          // Успех - обновляем состояние
          _setState(
            DatabaseState(
              path: manager.currentStorePath,
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );

          logInfo('Store opened successfully: ${storeInfo.name}', tag: _logTag);
          return true;
        },
        (error) {
          // Ошибка - сохраняем в состоянии
          _setState(DatabaseState(status: DatabaseStatus.error, error: error));

          logError('Failed to open store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error opening store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при открытии хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Закрыть текущее хранилище
  ///
  /// Возвращает true если успешно, false если ошибка
  Future<bool> closeStore() async {
    try {
      logInfo('Closing store', tag: _logTag);

      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot close', tag: _logTag);
        return false;
      }

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем закрытие хранилища
      final manager = await _getManager;
      final result = await manager.closeStore();

      return result.fold(
        (_) {
          // Успех - переводим в idle состояние
          _setState(const DatabaseState(status: DatabaseStatus.idle));

          logInfo('Store closed successfully', tag: _logTag);
          return true;
        },
        (error) {
          // Ошибка - возвращаем предыдущее состояние с ошибкой
          _setState(
            _currentState.copyWith(status: DatabaseStatus.error, error: error),
          );

          logError('Failed to close store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error closing store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        _currentState.copyWith(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при закрытии хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Блокировать текущее хранилище
  ///
  /// Блокирует хранилище без закрытия соединения.
  /// Пользователь должен будет ввести пароль для разблокировки.
  void lockStore() {
    if (!_currentState.isOpen) {
      logWarning('Store is not open, cannot lock', tag: _logTag);
      return;
    }

    logInfo('Locking store', tag: _logTag);

    _setState(
      _currentState.copyWith(status: DatabaseStatus.locked, error: null),
    );

    logInfo('Store locked successfully', tag: _logTag);
  }

  /// Разблокировать хранилище
  ///
  /// [password] - пароль для разблокировки
  /// Возвращает true если успешно, false если неверный пароль
  Future<bool> unlockStore(String password) async {
    try {
      if (!_currentState.isLocked) {
        logWarning('Store is not locked, cannot unlock', tag: _logTag);
        return false;
      }

      logInfo('Unlocking store', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Проверяем пароль через повторное открытие
      final currentPath = _currentState.path;
      if (currentPath == null) {
        _setState(
          _currentState.copyWith(
            status: DatabaseStatus.error,
            error: DatabaseError.notInitialized(
              message: 'Путь к хранилищу не найден',
              timestamp: DateTime.now(),
            ),
          ),
        );
        return false;
      }

      // Закрываем текущее соединение
      final manager = await _getManager;
      await manager.closeStore();

      // Пытаемся открыть заново с паролем
      final result = await manager.openStore(
        OpenStoreDto(path: currentPath, password: password),
      );

      return result.fold(
        (storeInfo) {
          // Успех - разблокируем
          _setState(
            _currentState.copyWith(
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );

          logInfo('Store unlocked successfully', tag: _logTag);
          return true;
        },
        (error) {
          // Неверный пароль - остаемся заблокированными
          _setState(
            _currentState.copyWith(status: DatabaseStatus.locked, error: error),
          );

          logError('Failed to unlock store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error unlocking store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        _currentState.copyWith(
          status: DatabaseStatus.locked,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при разблокировке: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Обновить метаданные хранилища
  ///
  /// [dto] - данные для обновления (имя, описание, пароль)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> updateStore(UpdateStoreDto dto) async {
    try {
      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot update', tag: _logTag);
        return false;
      }

      logInfo('Updating store metadata', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем обновление хранилища
      final manager = await _getManager;
      final result = await manager.updateStore(dto);

      return result.fold(
        (storeInfo) {
          // Успех - обновляем состояние
          _setState(
            _currentState.copyWith(
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );

          logInfo('Store updated successfully', tag: _logTag);
          return true;
        },
        (error) {
          // Ошибка - возвращаем открытое состояние с ошибкой
          _setState(
            _currentState.copyWith(status: DatabaseStatus.open, error: error),
          );

          logError('Failed to update store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error updating store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        _currentState.copyWith(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при обновлении хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Удалить хранилище
  ///
  /// [path] - путь к хранилищу
  /// [deleteFromDisk] - удалить файлы с диска (по умолчанию true)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> deleteStore(String path, {bool deleteFromDisk = true}) async {
    try {
      logInfo('Deleting store at: $path', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем удаление хранилища
      final manager = await _getManager;
      final result = await manager.deleteStore(
        path,
        deleteFromDisk: deleteFromDisk,
      );

      return result.fold(
        (_) {
          // Успех - переводим в idle состояние
          _setState(const DatabaseState(status: DatabaseStatus.idle));

          logInfo('Store deleted successfully', tag: _logTag);
          return true;
        },
        (error) {
          // Ошибка - сохраняем в состоянии
          _setState(DatabaseState(status: DatabaseStatus.error, error: error));

          logError('Failed to delete store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error deleting store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при удалении хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Получить путь к папке вложений
  ///
  /// Возвращает null если хранилище не открыто или ошибка
  Future<String?> getAttachmentsPath() async {
    try {
      if (!_currentState.isOpen) {
        logWarning(
          'Store is not open, cannot get attachments path',
          tag: _logTag,
        );
        return null;
      }

      final manager = await _getManager;
      final result = await manager.getAttachmentsPath();

      return result.fold((path) => path, (error) {
        logError(
          'Failed to get attachments path: ${error.message}',
          tag: _logTag,
        );
        return null;
      });
    } catch (e, stackTrace) {
      logError(
        'Unexpected error getting attachments path: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Создать подпапку в текущем хранилище
  ///
  /// [folderName] - имя подпапки
  /// Возвращает путь к созданной папке или null при ошибке
  Future<String?> createSubfolder(String folderName) async {
    try {
      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot create subfolder', tag: _logTag);
        return null;
      }

      final manager = await _getManager;
      final result = await manager.createSubfolder(folderName);

      return result.fold(
        (path) {
          logInfo('Subfolder created: $path', tag: _logTag);
          return path;
        },
        (error) {
          logError(
            'Failed to create subfolder: ${error.message}',
            tag: _logTag,
          );
          return null;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error creating subfolder: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Очистить ошибку из состояния
  void clearError() {
    _setState(_currentState.copyWith(error: null));
  }

  /// Get Current MainStoreManager
  MainStoreManager? get currentMainStoreManager {
    if (_manager == null) {
      logWarning('MainStoreManager is not initialized', tag: _logTag);
    }
    return _manager;
  }

  /// Получить MainStoreManager по готовности
  Future<MainStoreManager> getManager() async => await _getManager;
}
