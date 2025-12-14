import 'models/disk_info.dart';
import 'models/link.dart';
import 'models/resource.dart';
import 'models/resource_list.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

abstract interface class YandexDriveApi {
  /// Get general information about the user's Yandex Disk.
  Future<DiskInfo> getDiskInfo();

  /// Get meta information for a file or folder.
  Future<Resource> getResource(
    String path, {
    List<String>? fields,
    int? limit,
    int? offset,
    String? previewSize,
    bool? previewCrop,
    String? sort,
  });

  /// Add or update custom properties for a resource.
  Future<Resource> updateResource(
    String path, {
    Map<String, dynamic>? customProperties,
    List<String>? fields,
  });

  /// Returns a flat list of all files on Disk.
  Future<ResourceList> getFiles({
    int? limit,
    String? mediaType,
    int? offset,
    List<String>? fields,
    String? previewSize,
    bool? previewCrop,
  });

  /// Returns the list of most recently uploaded files.
  Future<ResourceList> getLastUploadedFiles({
    int? limit,
    String? mediaType,
    List<String>? fields,
    String? previewSize,
    bool? previewCrop,
  });

  /// Request a URL to upload a file.
  Future<Link> getUploadLink(
    String path, {
    bool? overwrite,
    List<String>? fields,
  });

  /// Upload a file from a URL.
  Future<Link> uploadFileFromUrl(
    String url,
    String path, {
    List<String>? fields,
    bool? disableRedirects,
    OAuth2ProgressCallback? onProgress,
  });

  /// Request a URL to download a file.
  Future<Link> getDownloadLink(String path, {List<String>? fields});

  /// Upload a file to the specified path with progress callback.
  Future<void> uploadFile(
    String path,
    Stream<List<int>> fileStream,
    int contentLength, {
    bool? overwrite,
    OAuth2ProgressCallback? onProgress,
  });

  /// Download a file from the specified path with progress callback.
  Future<Stream<List<int>>> downloadFile(
    String path, {
    OAuth2ProgressCallback? onProgress,
  });

  /// Create a new folder.
  Future<Link> createFolder(String path, {List<String>? fields});

  /// Copy a file or folder.
  Future<Link> copyResource(
    String from,
    String path, {
    bool? overwrite,
    List<String>? fields,
  });

  /// Move a file or folder.
  Future<Link> moveResource(
    String from,
    String path, {
    bool? overwrite,
    List<String>? fields,
  });

  /// Delete a file or folder.
  Future<dynamic> deleteResource(
    String path, {
    bool? permanently,
    List<String>? fields,
  });

  /// Publish a resource (make it public).
  Future<Link> publishResource(String path);

  /// Revoke public access to a resource.
  Future<Link> unpublishResource(String path);

  /// Check the status of an async operation.
  Future<String> getOperationStatus(String operationId);

  /// Get meta information for files in Trash.
  Future<Resource> getTrashResources({
    String? path,
    int? limit,
    int? offset,
    String? sort,
    String? previewSize,
    bool? previewCrop,
  });

  /// Restore a file or folder from Trash.
  Future<Link> restoreFromTrash(String path, {String? name, bool? overwrite});

  /// Empty the Trash or delete a specific resource from it.
  Future<dynamic> deleteFromTrash({String? path});

  /// Get meta information for a public resource.
  Future<Resource> getPublicResource(
    String publicKey, {
    String? path,
    String? sort,
    int? limit,
    int? offset,
    String? previewSize,
    bool? previewCrop,
  });

  /// Get a download link for a public resource.
  Future<Link> getPublicDownloadLink(String publicKey, {String? path});

  /// Save a public resource to the user's "Downloads" folder.
  Future<Link> savePublicResourceToDisk(
    String publicKey, {
    String? path,
    String? name,
  });
}
