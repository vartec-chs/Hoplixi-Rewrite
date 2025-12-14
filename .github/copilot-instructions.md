# Hoplixi AI Guide
- **Boot flow** `lib/main.dart` blocks web, loads `.env`, initializes `AppLogger`, DI, `WindowManager`, and tray before running `App` inside a `ProviderScope` with `LoggingProviderObserver`.
- **Crash funnel** Errors already pass through `runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`, and `Toaster.*`; reuse `logError` + `Toaster` instead of ad-hoc handlers.
- **Logging stack** `core/logger/app_logger.dart` buffers JSONL sessions via `LogBuffer`; always call `logInfo/logWarning/...` so `LoggerConfig` switches and crash reports stay in sync with the log viewer.
- **Storage layout** `core/app_paths.dart` owns OS-specific directories (`appLogsPath`, `appCrashReportsPath`, `exportStoragesPath`, etc.); ask it for paths before reading/writing the filesystem.
- **Dependency graph** `setupDI()` wires `PreferencesService`, `FlutterSecureStorage`, `HiveBoxManager`, and `DatabaseHistoryService`; fetch long-lived services through `getIt` instead of new instances.
- **Secure Hive** `core/services/hive_box_manager.dart` manages AES keys in secure storage; open boxes through it (not `Hive.openBox`) or you will desynchronize encryption.
- **Database lifecycle** `main_store/main_store_manager.dart` wraps Drift + SQLCipher, returning `AsyncResultDart<StoreInfoDto, DatabaseError>`; propagate those results all the way up, never throw.
- **History service** `main_store/services/db_history_services.dart` records stores keyed by path and drives tray/recent lists; update via the service so Hive stays consistent.
- **Schema changes** `main_store/main_store.dart` hosts tables/DAOs; bump `MainConstants.databaseSchemaVersion` and rerun `build_runner` whenever schema or Freezed models move.
- **Domain errors** Extend `main_store/models/db_errors.dart` so Riverpod + `result_dart` pipelines can pattern-match without custom exception types.
- **Main store state** `main_store/provider/main_store_provider.dart` keeps the authoritative `DatabaseState`; update through notifier methods (`createStore`, `lockStore`, etc.) and rely on `AsyncNotifier` state flags (`isOpen`, `hasError`).
- **Routing** `routing/router.dart` uses `go_router` with `routerRefreshNotifier` and `RootOverlayObserver`; desktop routes render inside `DesktopShell`, and redirects also adjust window sizing via `WindowManager`.
- **Chrome overlay** `shared/ui/desktop_shell.dart` just reserves space, while `RootBarsOverlay` injects `TitleBar`/`StatusBar` into the root overlay—toggle visibility via `titlebarStateProvider` and `statusBarStateProvider`.
- **Status bar** `shared/ui/status_bar.dart` mirrors DB status by watching `mainStoreProvider`; update the notifier instead of mutating widgets when showing progress or inline actions.
- **Theming** `core/theme/theme_provider.dart` reads/writes preferences through DI and feeds `AnimatedThemeSwitcher`; switch themes via notifier helpers (`setDarkTheme`, `toggleTheme`) to persist selections.
- **Tray behavior** `setup_tray.dart` binds menu keys to `AppTrayMenuItemKey`; extend the enum/switch when adding tray actions and guard with `UniversalPlatform.isDesktop`.
- **Window controls** `core/utils/window_manager.dart` hides the native frame on Windows; wrap new window APIs with explicit platform checks to avoid mobile crashes.
- **Toast UX** `core/utils/toastification.dart` centralizes toast theming and clipboard copy; prefer `Toaster.success/error/info` over bespoke snackbars.
 - **UI components guidance** Prefer shared UI primitives and high-level widgets from `lib/shared/ui` instead of ad-hoc controls:
	 - Use `primaryInputDecoration` (in `lib/shared/ui/text_field.dart`) as the standard `InputDecoration` for all text fields. It centralizes colors, paddings, disabled styles and accessibility. Example use:
		 - TextField(decoration: primaryInputDecoration(context, labelText: 'Name', hintText: 'Enter name'))
	 - For confirmation-style actions prefer `SliderButton` (in `lib/shared/ui/slider_button.dart`) instead of plain buttons for destructive/confirm flows. It supports async callbacks, loading state and optional reset behavior. Example:
		 - SliderButton(type: SliderButtonType.confirm, text: 'Confirm', onSlideCompleteAsync: () async { await doConfirm(); })
	 - Use `NotificationCard` (in `lib/shared/ui/notification_card.dart`) when you need an in-tree notification widget (errors, warnings, info, success). It replaces ad-hoc container+icon patterns and supports dismiss handlers. Example:
		 - NotificationCard(type: NotificationType.error, text: 'Failed to save', onDismiss: () => close())
	 - Replace raw `ElevatedButton`/`TextButton` usages with the app's `SmoothButton` (in `lib/shared/ui/button.dart`) for consistent padding, sizes and variants. Example:
		 - SmoothButton(label: 'Save', onPressed: save, type: SmoothButtonType.filled, variant: SmoothButtonVariant.normal)
	 - Replace `ScaffoldMessenger`/`SnackBar` usages with `Toaster` static helpers (in `lib/core/utils/toastification.dart`) for toasts: `Toaster.success`, `Toaster.error`, `Toaster.infoDebug`, `Toaster.warning`, `Toaster.info`, and `Toaster.custom`. They use `NotificationCard`-style visuals and central theming. Example:
		 - Toaster.success(title: 'Saved', description: 'Your settings were saved')

 These changes improve visual consistency, accessibility, and reduce duplicated UI logic across features.
- **Result patterns** Features (e.g., `features/password_manager/create_store`) expect Riverpod notifiers to map `AsyncResult` into UI state; keep UI logic declarative and avoid mutable fields.
- **Logging hygiene** When adding structured keys with secrets, call `logInfoWithSecretData` so production builds auto-mask sensitive fields.
- **Build/test** Typical cycle: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run -d windows`; `build_ranner.bat` wraps `flutter pub run build_runner build --delete-conflicting-outputs` for codegen.
- **Platform limits** Web is unsupported—mirroring `main.dart`, gate platform-specific code with `UniversalPlatform` and early exits.
- **Secrets** Persist sensitive values inside `SecureStorageService`; never log raw passwords or attachment keys.
- **ref.listen** Use `ref.listen` in UI widgets only in build methods not use in initState, dispose, or outside widgets to avoid missing updates. 
- **Riverpod Notifiers** Use `AsyncNotifier` and `AsyncNotifierProvider`  for async operations instead of `Notifier` to get built-in loading/error states. and use Notifier in other cases if there is a state. StateNotifier, StateNotifierProvider, ChangeNotifier are deprecated.

- For modules, write your own errors, for example:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_errors.freezed.dart';

@freezed
abstract class DatabaseError with _$DatabaseError implements Exception {
  const DatabaseError._();

  const factory DatabaseError.invalidPassword({
    @Default('DB_INVALID_PASSWORD') String code,
    @Default('Неверный пароль для базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = InvalidPasswordError;
}
```
## MCP Servers and Advanced Scenarios
- Library documentation: query via the context7 MCP server (get up-to-date signatures and usage patterns).
- Multi-step tasks (migrations, service refactoring): use SequentialThinking MCP – it captures the plan and provides progress metrics.
- Dart/Flutter mcp: use DartMCP for code analysis and suggestions.
## Additional notes about freezed
Use the @freezed surface of an abstract sealed class.
Don't create instances of private implementations through constructors—only in the factory.
After adding, run a build (otherwise, you'll get a missing parts error).