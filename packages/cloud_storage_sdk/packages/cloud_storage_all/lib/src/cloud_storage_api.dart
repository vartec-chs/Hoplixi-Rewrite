import 'dart:async';

import 'package:oauth2restclient/oauth2restclient.dart';

import 'models/cloud_item.dart';
import 'models/cloud_page.dart';
import 'models/cloud_ref.dart';

abstract interface class CloudStorageApi {
  Future<CloudPage<CloudItem>> listChildren(
    CloudRef folder, {
    String? pageToken,
    int? pageSize,
  });

  Future<Stream<List<int>>> download(
    CloudRef file, {
    OAuth2ProgressCallback? onProgress,
  });

  Future<CloudItem> upload(
    CloudRef folder,
    String name,
    Stream<List<int>> bytes, {
    int? contentLength,
    String contentType = 'application/octet-stream',
    OAuth2ProgressCallback? onProgress,
    bool? overwrite,
  });

  Future<CloudItem> createFolder(CloudRef parentFolder, String name);

  Future<void> delete(CloudRef target, {bool? permanently});

  Future<void> move(
    CloudRef from,
    CloudRef destinationFolder, {
    String? newName,
  });

  Future<void> copy(
    CloudRef from,
    CloudRef destinationFolder, {
    String? newName,
  });
}
