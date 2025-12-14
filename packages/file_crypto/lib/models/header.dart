import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

/// Extended header for archive encryption.
///
/// Contains additional metadata about the original content.
class ArchiveEncryptionHeader {
  /// Unique identifier for the encrypted content.
  final String uuid;

  /// Original file or directory name.
  final String originalName;

  /// Whether the source was a directory.
  final bool wasDirectory;

  /// Original file extension (if file).
  final String originalExtension;

  /// Original size before compression.
  final int originalSize;

  /// Size after compression (before encryption).
  final int compressedSize;

  /// Whether the content is compressed with gzip.
  final bool isCompressed;

  const ArchiveEncryptionHeader({
    required this.uuid,
    required this.originalName,
    required this.wasDirectory,
    required this.originalExtension,
    required this.originalSize,
    required this.compressedSize,
    this.isCompressed = true,
  });

  /// Serializes the header to bytes.
  Uint8List toBytes() {
    final uuidBytes = utf8.encode(uuid);
    final nameBytes = utf8.encode(originalName);
    final extBytes = utf8.encode(originalExtension);

    // Format:
    // [UUID length (1 byte)]
    // [UUID (variable)]
    // [Name length (2 bytes)]
    // [Name (variable)]
    // [Extension length (1 byte)]
    // [Extension (variable)]
    // [wasDirectory (1 byte)]
    // [isCompressed (1 byte)]
    // [originalSize (8 bytes)]
    // [compressedSize (8 bytes)]

    final totalLength =
        1 +
        uuidBytes.length +
        2 +
        nameBytes.length +
        1 +
        extBytes.length +
        1 +
        1 + // isCompressed
        8 +
        8;

    final bytes = Uint8List(totalLength);
    final view = ByteData.view(bytes.buffer);
    var offset = 0;

    // UUID length and data
    bytes[offset++] = uuidBytes.length;
    bytes.setRange(offset, offset + uuidBytes.length, uuidBytes);
    offset += uuidBytes.length;

    // Name length (2 bytes) and data
    view.setUint16(offset, nameBytes.length, Endian.big);
    offset += 2;
    bytes.setRange(offset, offset + nameBytes.length, nameBytes);
    offset += nameBytes.length;

    // Extension length and data
    bytes[offset++] = extBytes.length;
    bytes.setRange(offset, offset + extBytes.length, extBytes);
    offset += extBytes.length;

    // wasDirectory
    bytes[offset++] = wasDirectory ? 1 : 0;

    // isCompressed
    bytes[offset++] = isCompressed ? 1 : 0;

    // originalSize
    view.setInt64(offset, originalSize, Endian.big);
    offset += 8;

    // compressedSize
    view.setInt64(offset, compressedSize, Endian.big);

    return bytes;
  }

  /// Deserializes the header from bytes.
  factory ArchiveEncryptionHeader.fromBytes(Uint8List bytes) {
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var offset = 0;

    // UUID
    final uuidLength = bytes[offset++];
    final uuid = utf8.decode(bytes.sublist(offset, offset + uuidLength));
    offset += uuidLength;

    // Name
    final nameLength = view.getUint16(offset, Endian.big);
    offset += 2;
    final originalName = utf8.decode(
      bytes.sublist(offset, offset + nameLength),
    );
    offset += nameLength;

    // Extension
    final extLength = bytes[offset++];
    final originalExtension = utf8.decode(
      bytes.sublist(offset, offset + extLength),
    );
    offset += extLength;

    // wasDirectory
    final wasDirectory = bytes[offset++] == 1;

    // isCompressed
    final isCompressedByte = bytes[offset++];
    final isCompressed = isCompressedByte == 1;

    // originalSize
    final originalSize = view.getInt64(offset, Endian.big);
    offset += 8;

    // compressedSize
    final compressedSize = view.getInt64(offset, Endian.big);

    return ArchiveEncryptionHeader(
      uuid: uuid,
      originalName: originalName,
      wasDirectory: wasDirectory,
      originalExtension: originalExtension,
      originalSize: originalSize,
      compressedSize: compressedSize,
      isCompressed: isCompressed,
    );
  }

  /// Creates a new header with a generated UUID.
  factory ArchiveEncryptionHeader.create({
    required String originalName,
    required bool wasDirectory,
    required String originalExtension,
    required int originalSize,
    required int compressedSize,
    bool isCompressed = true,
  }) {
    return ArchiveEncryptionHeader(
      uuid: const Uuid().v4(),
      originalName: originalName,
      wasDirectory: wasDirectory,
      originalExtension: originalExtension,
      originalSize: originalSize,
      compressedSize: compressedSize,
      isCompressed: isCompressed,
    );
  }
}
