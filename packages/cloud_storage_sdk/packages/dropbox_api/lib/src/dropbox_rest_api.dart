import 'dart:async';
import 'dart:convert';

import 'package:oauth2restclient/oauth2restclient.dart';

import 'interface.dart';
import 'models/models.dart';

class DropboxRestApi implements DropboxApi {
  final OAuth2RestClient client;
  static const String _baseUrl = 'https://api.dropboxapi.com/2';

  DropboxRestApi(this.client);

  @override
  Future<Stream<List<int>>> download(
    String path, {
    OAuth2ProgressCallback? onProgress,
  }) async {
    var input = jsonEncode({'path': path});
    var arg = Uri.encodeQueryComponent(input);
    var url = 'https://content.dropboxapi.com/2/files/download?arg=$arg';
    return client.postStream(url, onProgress: onProgress);
  }

  @override
  Future<DropboxFolderContents> listFolder(
    String path, {
    int limit = 2000,
  }) async {
    final response = await client.postJson(
      '$_baseUrl/files/list_folder',
      body: OAuth2JsonBody({'path': path, 'limit': limit}),
    );
    return DropboxFolderContents.fromJson(response);
  }

  @override
  Future<DropboxFolderContents> listFolderContinue(String cursor) async {
    final response = await client.postJson(
      '$_baseUrl/files/list_folder/continue',
      body: OAuth2JsonBody({'cursor': cursor}),
    );
    return DropboxFolderContents.fromJson(response);
  }

  @override
  Future<DropboxFolder> createFolder(String path) async {
    final response = await client.postJson(
      '$_baseUrl/files/create_folder_v2',
      body: OAuth2JsonBody({'path': path, 'autorename': false}),
    );
    return DropboxFolder.fromJson(response);
  }

  @override
  Future<DropboxFile> upload(
    String path,
    Stream<List<int>> dataStream, {
    String mode = 'add',
    bool autorename = true,
    OAuth2ProgressCallback? onProgress,
  }) async {
    // Stream을 List<List<int>>로 변환
    final chunks = await dataStream.toList();
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);

    final fileBody = OAuth2FileBody(
      Stream.fromIterable(chunks),
      contentLength: totalLength,
      contentType: 'application/octet-stream',
    );

    var input = jsonEncode({
      'path': path,
      'mode': mode,
      'autorename': autorename,
    });

    var arg = Uri.encodeQueryComponent(input);
    var url = 'https://content.dropboxapi.com/2/files/upload?arg=$arg';

    final response = await client.postJson(
      url,
      body: fileBody,
      headers: {'Content-Type': 'application/octet-stream'},
      onProgress: onProgress,
    );
    return DropboxFile.fromJson(response);
  }

  @override
  Future<void> delete(String path) async {
    await client.postJson(
      '$_baseUrl/files/delete_v2',
      body: OAuth2JsonBody({'path': path}),
    );
  }

  @override
  Future<void> move(String fromPath, String toPath) async {
    await client.postJson(
      '$_baseUrl/files/move_v2',
      body: OAuth2JsonBody({'from_path': fromPath, 'to_path': toPath}),
    );
  }

  @override
  Future<void> copy(String fromPath, String toPath) async {
    await client.postJson(
      '$_baseUrl/files/copy_v2',
      body: OAuth2JsonBody({'from_path': fromPath, 'to_path': toPath}),
    );
  }

  @override
  Future<DropboxAccount> getCurrentAccount() async {
    final response = await client.postJson(
      '$_baseUrl/users/get_current_account',
      body: OAuth2JsonBody({}),
    );
    return DropboxAccount.fromJson(response);
  }
}
