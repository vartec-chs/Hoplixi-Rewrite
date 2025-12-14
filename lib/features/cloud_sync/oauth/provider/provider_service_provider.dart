import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/cloud_sync/oauth/services/provider_service.dart';
import 'package:hoplixi/features/cloud_sync/oauth/services/token_service.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/services/oauth_apps_service.dart';

/// Провайдер для ProviderService
// @riverpod
// ProviderService providerService(ProviderServiceRef ref) {
//   final appsService = getIt<OAuthAppsService>();
//   final tokenService = getIt<TokenService>();

//   final service = ProviderService(
//     appsService: appsService,
//     tokenService: tokenService,
//   );

//   return service;
// }

final providerServiceProvider = Provider<ProviderService>((ref) {
  final appsService = getIt<OAuthAppsService>();
  final tokenService = getIt<TokenService>();

  final service = ProviderService(
    appsService: appsService,
    tokenService: tokenService,
  );

  return service;
});
