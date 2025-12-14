import 'dart:async';

import 'package:oauth2restclient/oauth2restclient.dart';

import 'models/models.dart';

/// OneDrive API 클라이언트 인터페이스입니다.
abstract interface class OneDriveApi {
  /// 파일을 다운로드합니다.
  ///
  /// [path]는 OneDrive 내의 파일 경로입니다 (예: "/Documents/file.txt").
  /// Returns a stream of bytes representing the file content.
  Future<Stream<List<int>>> download(
    String path, {
    OAuth2ProgressCallback? onProgress,
  });

  /// 폴더 내용을 조회합니다.
  ///
  /// [path]는 OneDrive 내의 폴더 경로입니다 (예: "/Documents").
  /// Returns a [OneDriveDriveItems] containing the folder contents and a nextLink for pagination.
  Future<OneDriveDriveItems> listChildren(
    String path, {
    String? nextLink,
    int? top,
  });

  /// 폴더를 생성합니다.
  ///
  /// [path]는 생성할 폴더의 전체 경로입니다 (예: "/Documents/newfolder").
  /// Returns a [OneDriveDriveItem] containing the metadata of the created folder.
  Future<OneDriveDriveItem> createFolder(String path);

  /// 파일을 업로드합니다.
  ///
  /// [path]는 업로드할 파일의 전체 경로입니다 (예: "/Documents/hello.txt").
  /// [dataStream]은 파일 데이터 스트림입니다.
  /// Returns a [OneDriveDriveItem] containing the metadata of the uploaded file.
  Future<OneDriveDriveItem> upload(
    String path,
    Stream<List<int>> dataStream, {
    OAuth2ProgressCallback? onProgress,
  });

  /// 파일이나 폴더를 삭제합니다.
  ///
  /// [path]는 삭제할 파일이나 폴더의 경로입니다 (예: "/Documents/file.txt").
  Future<void> delete(String path);

  /// 파일이나 폴더를 이동합니다.
  ///
  /// [path]는 이동할 파일이나 폴더의 경로입니다 (예: "/Documents/file.txt").
  /// [newPath]는 새로운 전체 경로입니다 (예: "/Pictures/newfile.txt").
  Future<OneDriveDriveItem> move(String path, String newPath);

  /// 파일이나 폴더를 복사합니다.
  ///
  /// [path]는 복사할 파일이나 폴더의 경로입니다 (예: "/Documents/file.txt").
  /// [newPath]는 새로운 전체 경로입니다 (예: "/Backup/file_copy.txt").
  Future<void> copy(String path, String newPath);

  /// 현재 사용자의 계정 정보를 가져옵니다.
  Future<OneDriveUser> getCurrentUser();

  /// 드라이브 정보를 가져옵니다.
  Future<OneDriveDrive> getDrive();
}
