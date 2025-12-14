enum OAuth2ProviderE { google, microsoft, yandex, dropbox }

extension OAuth2ProviderExtension on OAuth2ProviderE {
  String get name {
    switch (this) {
      case OAuth2ProviderE.google:
        return "google";
      case OAuth2ProviderE.microsoft:
        return "microsoft";
      case OAuth2ProviderE.yandex:
        return "yandex";
      case OAuth2ProviderE.dropbox:
        return "dropbox";
    }
  }
}
