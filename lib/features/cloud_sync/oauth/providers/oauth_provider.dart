import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoplixi/features/cloud_sync/oauth/providers/token_service_provider.dart';
import 'package:hoplixi/features/cloud_sync/oauth/services/oauth_providers_service.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/providers/oauth_apps_service_provider.dart';

final oauthProviderServiceProvider = Provider<OauthProvidersService>((ref) {
  final appsService = ref.watch(oauthAppsServiceProvider);
  final tokenService = ref.watch(tokenServiceProvider);

  final service = OauthProvidersService(
    appsService: appsService,
    tokenService: tokenService,
  );

  return service;
});
