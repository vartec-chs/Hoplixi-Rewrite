// import 'package:cloud_storage_all/cloud_storage_all.dart' show OAuth2Token;
// import 'package:hoplixi/core/logger/app_logger.dart';
// import 'package:hoplixi/features/cloud_sync/oauth/models/provider_service_errors.dart';
// import 'package:hoplixi/features/cloud_sync/oauth/provider/provider_service_provider.dart';
// import 'package:result_dart/result_dart.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'auth_provider.g.dart';

// /// Провайдер для управления авторизацией
// @riverpod
// class Auth extends _$Auth {
//   static const String _logTag = 'AuthProvider';

//   @override
//   FutureOr<void> build() async {
//     // Инициализация ProviderService
//     final service = ref.read(providerServiceProvider);
//     final result = await service.initialize();

//     result.fold(
//       (success) => logInfo('AuthProvider initialized', tag: _logTag),
//       (error) =>
//           logError('Failed to initialize AuthProvider: $error', tag: _logTag),
//     );
//   }

//   /// Выполнить вход для провайдера
//   Future<AsyncResultDart<OAuth2Token, ProviderServiceError>> login(
//     String provider,
//   ) async {
//     state = const AsyncValue.loading();

//     final service = ref.read(providerServiceProvider);
//     final result = await service.login(provider);

//     state = await AsyncValue.guard(() async => unit);

//     return result;
//   }

//   /// Попытка автоматического входа
//   Future<AsyncResultDart<OAuth2Token, ProviderServiceError>> tryAutoLogin(
//     String provider,
//     String userName,
//   ) async {
//     state = const AsyncValue.loading();

//     final service = ref.read(providerServiceProvider);
//     final result = await service.tryAutoLogin(provider, userName);

//     state = await AsyncValue.guard(() async => unit);

//     return result;
//   }

//   /// Принудительный повторный вход
//   Future<AsyncResultDart<OAuth2Token, ProviderServiceError>> forceRelogin(
//     OAuth2Token expiredToken,
//   ) async {
//     state = const AsyncValue.loading();

//     final service = ref.read(providerServiceProvider);
//     final result = await service.forceRelogin(expiredToken);

//     state = await AsyncValue.guard(() async => unit);

//     return result;
//   }

//   /// Обновить токен
//   Future<AsyncResultDart<OAuth2Token, ProviderServiceError>> refreshToken(
//     OAuth2Token expiredToken,
//   ) async {
//     state = const AsyncValue.loading();

//     final service = ref.read(providerServiceProvider);
//     final result = await service.refreshToken(expiredToken);

//     state = await AsyncValue.guard(() async => unit);

//     return result;
//   }

//   /// Удалить аккаунт
//   Future<AsyncResultDart<void, ProviderServiceError>> deleteAccount(
//     String service,
//     String userName,
//   ) async {
//     state = const AsyncValue.loading();

//     final providerService = ref.read(providerServiceProvider);
//     final result = await providerService.deleteAccount(service, userName);

//     state = await AsyncValue.guard(() async => unit);

//     // Обновляем список токенов после удаления
//     ref.invalidate(accountsProvider);

//     return result;
//   }

//   /// Перезагрузить провайдеры
//   Future<AsyncResultDart<void, ProviderServiceError>> reloadProviders() async {
//     state = const AsyncValue.loading();

//     final service = ref.read(providerServiceProvider);
//     final result = await service.reloadProviders();

//     state = await AsyncValue.guard(() async => unit);

//     return result;
//   }
// }

// /// Провайдер для получения списка всех аккаунтов
// @riverpod
// class Accounts extends _$Accounts {
//   @override
//   Future<List<(String, String)>> build({String service = ''}) async {
//     final providerService = ref.read(providerServiceProvider);
//     final result = await providerService.getAllAccounts(service: service);

//     return result.fold((accounts) => accounts, (error) {
//       logError('Failed to get accounts: $error', tag: 'AccountsProvider');
//       return [];
//     });
//   }

//   /// Обновить список аккаунтов
//   Future<void> refresh() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() => build(service: service));
//   }
// }

// /// Провайдер для загрузки конкретного аккаунта
// @riverpod
// class Account extends _$Account {
//   @override
//   Future<OAuth2Token?> build(String service, String userName) async {
//     final providerService = ref.read(providerServiceProvider);
//     final result = await providerService.loadAccount(service, userName);

//     return result.fold((token) => token, (error) {
//       logError('Failed to load account: $error', tag: 'AccountProvider');
//       return null;
//     });
//   }

//   /// Обновить аккаунт
//   Future<void> refresh() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() => build(service, userName));
//   }
// }
