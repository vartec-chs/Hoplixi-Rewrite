import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/migration/passwords/services/password_migration_service.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

class PasswordMigrationState {
  final bool isLoading;
  final String? error;
  final String? generatedFilePath;
  final String? importFilePath;
  final List<CreatePasswordDto>? parsedPasswords;

  const PasswordMigrationState({
    this.isLoading = false,
    this.error,
    this.generatedFilePath,
    this.importFilePath,
    this.parsedPasswords,
  });

  PasswordMigrationState copyWith({
    bool? isLoading,
    String? error,
    String? generatedFilePath,
    String? importFilePath,
    List<CreatePasswordDto>? parsedPasswords,
  }) {
    return PasswordMigrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      generatedFilePath: generatedFilePath ?? this.generatedFilePath,
      importFilePath: importFilePath ?? this.importFilePath,
      parsedPasswords: parsedPasswords ?? this.parsedPasswords,
    );
  }
}

class PasswordMigrationNotifier extends AsyncNotifier<PasswordMigrationState> {
  late PasswordMigrationService _service;

  @override
  Future<PasswordMigrationState> build() async {
    final manager = await ref.watch(mainStoreManagerProvider.future);
    if (manager == null || manager.currentStore == null) {
      throw Exception('Database is not initialized');
    }
    _service = PasswordMigrationService(manager.currentStore!.passwordDao);
    return const PasswordMigrationState();
  }

  Future<void> generateTemplate(int count, String path) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, error: null));

    final result = await _service.generateTemplate(count, path);

    result.fold(
      (generatedPath) {
        state = AsyncData(
          state.value!.copyWith(
            isLoading: false,
            generatedFilePath: generatedPath,
            importFilePath: generatedPath, // Auto-set for import
          ),
        );
      },
      (error) {
        state = AsyncData(
          state.value!.copyWith(isLoading: false, error: error.toString()),
        );
      },
    );
  }

  Future<void> selectFile(String path) async {
    state = AsyncData(state.value!.copyWith(importFilePath: path, error: null));
  }

  Future<void> parseImportFile(String path) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, error: null));

    final result = await _service.parseImportFile(path);

    result.fold(
      (passwords) {
        state = AsyncData(
          state.value!.copyWith(isLoading: false, parsedPasswords: passwords),
        );
      },
      (error) {
        state = AsyncData(
          state.value!.copyWith(isLoading: false, error: error.toString()),
        );
      },
    );
  }

  Future<void> savePasswords(
    List<CreatePasswordDto> passwords,
    String filePath,
  ) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, error: null));

    final result = await _service.savePasswords(passwords);

    await result.fold(
      (_) async {
        // Delete file on success
        final _ = await _service.deleteImportFile(filePath);
        state = AsyncData(
          state.value!.copyWith(
            isLoading: false,
            parsedPasswords: null, // Clear after import
          ),
        );
      },
      (error) {
        state = AsyncData(
          state.value!.copyWith(isLoading: false, error: error.toString()),
        );
      },
    );
  }

  void clearError() {
    if (state.value != null) {
      state = AsyncData(
        PasswordMigrationState(
          isLoading: state.value!.isLoading,
          error: null,
          generatedFilePath: state.value!.generatedFilePath,
          importFilePath: state.value!.importFilePath,
          parsedPasswords: state.value!.parsedPasswords,
        ),
      );
    }
  }

  void setError(String error) {
    state = AsyncData(state.value!.copyWith(error: error));
  }
}

final passwordMigrationProvider =
    AsyncNotifierProvider.autoDispose<
      PasswordMigrationNotifier,
      PasswordMigrationState
    >(PasswordMigrationNotifier.new);
