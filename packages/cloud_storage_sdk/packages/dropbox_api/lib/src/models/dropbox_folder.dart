/// Dropbox 폴더를 나타내는 클래스입니다.
class DropboxFolder {
  final String id;
  final String name;
  final String pathLower;
  final String pathDisplay;

  DropboxFolder({
    required this.id,
    required this.name,
    required this.pathLower,
    required this.pathDisplay,
  });

  factory DropboxFolder.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>;
    return DropboxFolder(
      id: metadata['id'] as String,
      name: metadata['name'] as String,
      pathLower: metadata['path_lower'] as String,
      pathDisplay: metadata['path_display'] as String,
    );
  }
}
