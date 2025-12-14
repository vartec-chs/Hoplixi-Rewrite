import 'models/drive_list_response.dart';
import 'models/file_list_response.dart';
import 'models/gd_file.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

abstract interface class GoogleDriveApi {
  Future<FileListResponse> listFiles({
    String? name,
    String? parentId,
    String? query,
    String? orderBy,
    int? pageSize = 1,
    String? driveId,
    String? fields,
    bool onlyFolder,
    bool onlyFile,
    String? mimeType,
    String? space,
    String? nextPageToken,
  });

  Future<DriveListResponse> listDrives({String? nextPageToken});

  Future<GDFile> createFile(
    String parentId,
    String fileName,
    Stream<List<int>> dataStream, {
    String? driveId,
    DateTime? originalDate,
    int? fileSize,
    String contentType,
    OAuth2ProgressCallback? onProgress,
  });

  Future<GDFile> createFolder(
    String parentId,
    String folderName, {
    String? driveId,
  });

  Future<GDFile> getFile(String fileId);

  Future<GDFile> updateFile(
    String fileId, {
    String? fileName,
    List<String>? addParents,
    List<String>? removeParents,
  });

  Future<Stream<List<int>>> downloadFile(
    String fileId, {
    OAuth2ProgressCallback? onProgress,
  });

  Future<void> delete(String fileId);

  Future<GDFile> copyFile(String fromId, String toId);
}
