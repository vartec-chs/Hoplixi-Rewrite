import 'dart:async';

import 'package:oauth2restclient/oauth2restclient.dart';

import 'models/models.dart';

/// Dropbox API 클라이언트 인터페이스입니다.
abstract class DropboxApi {
  /// 파일을 다운로드합니다.
  ///
  /// Returns a stream of bytes representing the file content.
  Future<Stream<List<int>>> download(
    String path, {
    OAuth2ProgressCallback? onProgress,
  });

  /// 폴더 내용을 조회합니다.
  ///
  /// Returns a [DropboxFolderContents] containing the folder contents and a cursor for pagination.
  Future<DropboxFolderContents> listFolder(String path, {int limit});

  /// 이전 list_folder 호출의 결과를 계속 가져옵니다.
  ///
  /// Returns a [DropboxFolderContents] containing the folder contents and a cursor for pagination.
  Future<DropboxFolderContents> listFolderContinue(String cursor);

  /// 폴더를 생성합니다.
  ///
  /// Returns a [DropboxFolder] containing the metadata of the created folder.
  Future<DropboxFolder> createFolder(String path);

  /// 파일을 업로드합니다.
  ///
  /// Returns a [DropboxFile] containing the metadata of the uploaded file.
  Future<DropboxFile> upload(
    String path,
    Stream<List<int>> dataStream, {
    String mode = 'add',
    bool autorename = true,
    OAuth2ProgressCallback? onProgress,
  });

  /// 파일이나 폴더를 삭제합니다.
  Future<void> delete(String path);

  /// 파일이나 폴더를 이동합니다.
  Future<void> move(String fromPath, String toPath);

  /// 파일이나 폴더를 복사합니다.
  Future<void> copy(String fromPath, String toPath);

  /// 현재 사용자의 계정 정보를 가져옵니다.
  Future<DropboxAccount> getCurrentAccount();
}
