import 'package:oauth2restclient/src/provider/provider_enum.dart';

import 'oauth2_provider.dart';

class Yandex extends OAuth2ProviderF {
  Yandex({
    required super.clientId,
    super.clientSecret,
    required super.redirectUri,
    required super.scopes,
  }) : super(
         name: OAuth2ProviderE.yandex.name,
         authEndpoint: "https://oauth.yandex.ru/authorize",
         tokenEndpoint: "https://oauth.yandex.ru/token",
         getUserInfoEndpoint: "https://login.yandex.ru/info",
         authScheme: "OAuth",
       );
}
