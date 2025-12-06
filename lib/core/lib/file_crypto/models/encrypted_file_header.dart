import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

/// Encrypted file header containing metadata.
///
/// The header is encrypted along with the file content for security.
/// Structure (before encryption):
/// - UUID v4 (36 bytes as string)
/// - File extension length (2 bytes, big-endian)
/// - File extension (variable length, UTF-8)
/// - Original file size (8 bytes, big-endian)
class EncryptedFileHeader {
  /// UUID v4 identifier for database storage.
  final String uuid;

  /// Original file extension (e.g., 'pdf', 'jpg').
  final String fileExtension;

  /// Original file size in bytes.
  final int originalFileSize;

  /// Header version for future compatibility.
  static const int version = 1;

  /// Creates a new encrypted file header.
  const EncryptedFileHeader({
    required this.uuid,
    required this.fileExtension,
    required this.originalFileSize,
  });

  /// Creates a new header with auto-generated UUID v4.
  factory EncryptedFileHeader.create({
    required String fileExtension,
    required int originalFileSize,
  }) {
    return EncryptedFileHeader(
      uuid: const Uuid().v4(),
      fileExtension: fileExtension.toLowerCase().replaceAll('.', ''),
      originalFileSize: originalFileSize,
    );
  }

  /// Serializes the header to bytes.
  Uint8List toBytes() {
    final uuidBytes = utf8.encode(uuid);
    final extBytes = utf8.encode(fileExtension);

    if (uuidBytes.length != 36) {
      throw ArgumentError('UUID must be exactly 36 characters');
    }

    if (extBytes.length > 65535) {
      throw ArgumentError('File extension too long');
    }

    final buffer = BytesBuilder();

    // Version (1 byte)
    buffer.addByte(version);

    // UUID (36 bytes)
    buffer.add(uuidBytes);

    // Extension length (2 bytes, big-endian)
    buffer.addByte((extBytes.length >> 8) & 0xFF);
    buffer.addByte(extBytes.length & 0xFF);

    // Extension bytes
    buffer.add(extBytes);

    // Original file size (8 bytes, big-endian)
    final sizeBytes = Uint8List(8);
    final sizeView = ByteData.view(sizeBytes.buffer);
    sizeView.setInt64(0, originalFileSize, Endian.big);
    buffer.add(sizeBytes);

    return buffer.toBytes();
  }

  /// Deserializes the header from bytes.
  factory EncryptedFileHeader.fromBytes(Uint8List data) {
    // Minimum size: 1 (version) + 36 (UUID) + 2 (ext length) + 0 (empty ext) + 8 (size) = 47
    if (data.length < 47) {
      throw FormatException(
        'Header data too short: ${data.length} bytes, minimum 47 required',
      );
    }

    int offset = 0;

    // Version (1 byte)
    final headerVersion = data[offset];
    offset += 1;

    if (headerVersion != version) {
      throw FormatException('Unsupported header version: $headerVersion');
    }

    // UUID (36 bytes)
    final uuidBytes = data.sublist(offset, offset + 36);
    final uuid = utf8.decode(uuidBytes);
    offset += 36;

    // Extension length (2 bytes, big-endian)
    final extLength = (data[offset] << 8) | data[offset + 1];
    offset += 2;

    if (offset + extLength + 8 > data.length) {
      throw FormatException('Header data truncated');
    }

    // Extension bytes
    final extBytes = data.sublist(offset, offset + extLength);
    final fileExtension = utf8.decode(extBytes);
    offset += extLength;

    // Original file size (8 bytes, big-endian)
    final sizeView = ByteData.view(data.buffer, data.offsetInBytes + offset, 8);
    final originalFileSize = sizeView.getInt64(0, Endian.big);

    return EncryptedFileHeader(
      uuid: uuid,
      fileExtension: fileExtension,
      originalFileSize: originalFileSize,
    );
  }

  /// Returns the size of the serialized header.
  int get serializedSize => 1 + 36 + 2 + fileExtension.length + 8;

  @override
  String toString() {
    return 'EncryptedFileHeader(uuid: $uuid, extension: $fileExtension, '
        'size: $originalFileSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EncryptedFileHeader &&
        other.uuid == uuid &&
        other.fileExtension == fileExtension &&
        other.originalFileSize == originalFileSize;
  }

  @override
  int get hashCode => Object.hash(uuid, fileExtension, originalFileSize);
}
