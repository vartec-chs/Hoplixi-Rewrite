import 'cloud_storage_api.dart';
import 'adapters/dropbox_adapter.dart';
import 'adapters/google_drive_adapter.dart';
import 'adapters/onedrive_adapter.dart';
import 'adapters/yandex_drive_adapter.dart';

import 'package:dropbox_api/dropbox_api.dart' as dropbox;
import 'package:google_drive_api/google_drive_api.dart' as gdrive;
import 'package:onedrive_api/onedrive_rest_api.dart' as onedrive;
import 'package:oauth2restclient/oauth2restclient.dart';
import 'package:yandex_drive_api/yandex_drive_api.dart' as yandex;

enum CloudProvider { dropbox, googleDrive, oneDrive, yandexDisk }

class CloudStorage {
  final CloudProvider provider;
  final CloudStorageApi api;

  const CloudStorage._(this.provider, this.api);

  factory CloudStorage.dropbox(dropbox.DropboxApi api) =>
      CloudStorage._(CloudProvider.dropbox, DropboxAdapter(api));

  /// Convenience factory that builds a provider API from [OAuth2RestClient].
  factory CloudStorage.dropboxClient(OAuth2RestClient client) =>
      CloudStorage.dropbox(dropbox.DropboxRestApi(client));

  factory CloudStorage.googleDrive(gdrive.GoogleDriveApi api) =>
      CloudStorage._(CloudProvider.googleDrive, GoogleDriveAdapter(api));

  /// Convenience factory that builds a provider API from [OAuth2RestClient].
  factory CloudStorage.googleDriveClient(OAuth2RestClient client) =>
      CloudStorage.googleDrive(gdrive.GoogleDrive(client));

  factory CloudStorage.oneDrive(onedrive.OneDriveApi api) =>
      CloudStorage._(CloudProvider.oneDrive, OneDriveAdapter(api));

  /// Convenience factory that builds a provider API from [OAuth2RestClient].
  factory CloudStorage.oneDriveClient(OAuth2RestClient client) =>
      CloudStorage.oneDrive(onedrive.OneDriveRestApi(client));

  factory CloudStorage.yandexDisk(yandex.YandexDriveApi api) =>
      CloudStorage._(CloudProvider.yandexDisk, YandexDriveAdapter(api));

  /// Convenience factory that builds a provider API from [OAuth2RestClient].
  factory CloudStorage.yandexDiskClient(OAuth2RestClient client) =>
      CloudStorage.yandexDisk(yandex.YandexDrive(client));
}
