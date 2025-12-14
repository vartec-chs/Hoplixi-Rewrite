import 'cloud_ref.dart';

class CloudItem {
  final CloudRef ref;
  final String name;
  final bool isFolder;
  final int? size;
  final DateTime? created;
  final DateTime? modified;

  const CloudItem({
    required this.ref,
    required this.name,
    required this.isFolder,
    this.size,
    this.created,
    this.modified,
  });
}
