import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Efficient buffer for collecting chunk data without excessive copying.
///
/// Uses a fixed-size buffer with write pointer for O(1) operations.
class ChunkBufferArchive {
  final int _chunkSize;
  late Uint8List _buffer;
  int _writePos = 0;

  ChunkBufferArchive(this._chunkSize) {
    // Allocate slightly larger buffer to handle incoming data efficiently
    _buffer = Uint8List(_chunkSize * 2);
  }

  /// Returns true if buffer contains at least one full chunk.
  bool get hasFullChunk => _writePos >= _chunkSize;

  /// Returns true if buffer has any data.
  bool get isNotEmpty => _writePos > 0;

  /// Adds data to the buffer.
  void addAll(List<int> data) {
    // Ensure capacity
    if (_writePos + data.length > _buffer.length) {
      final newBuffer = Uint8List((_writePos + data.length) * 2);
      newBuffer.setRange(0, _writePos, _buffer);
      _buffer = newBuffer;
    }
    _buffer.setRange(_writePos, _writePos + data.length, data);
    _writePos += data.length;
  }

  /// Takes one full chunk from the buffer.
  Uint8List takeChunk() {
    if (_writePos < _chunkSize) {
      throw StateError('Not enough data for a full chunk');
    }

    final chunk = Uint8List(_chunkSize);
    chunk.setRange(0, _chunkSize, _buffer);

    // Shift remaining data to start
    final remaining = _writePos - _chunkSize;
    if (remaining > 0) {
      _buffer.setRange(0, remaining, _buffer, _chunkSize);
    }
    _writePos = remaining;

    return chunk;
  }

  /// Takes all remaining data from the buffer.
  Uint8List takeRemaining() {
    final data = Uint8List(_writePos);
    data.setRange(0, _writePos, _buffer);
    _writePos = 0;
    return data;
  }
}

/// Streaming HMAC calculator using MacSink.
///
/// Computes HMAC incrementally without storing all data in memory.
/// Uses the cryptography package's MacSink for true streaming.
class StreamingHmacArchive {
  final MacSink _sink;
  bool _closed = false;

  StreamingHmacArchive._(this._sink);

  /// Creates a new streaming HMAC calculator with the given key.
  static Future<StreamingHmacArchive> create(SecretKey hmacKey) async {
    final hmac = Hmac.sha256();
    final sink = await hmac.newMacSink(secretKey: hmacKey);
    return StreamingHmacArchive._(sink);
  }

  /// Adds data to the HMAC calculation incrementally.
  void add(List<int> data) {
    if (_closed) {
      throw StateError('Cannot add data to closed HMAC sink');
    }
    _sink.add(data);
  }

  /// Finalizes and returns the HMAC.
  Future<Mac> finalize() async {
    if (_closed) {
      throw StateError('HMAC sink already closed');
    }
    _closed = true;
    _sink.close();
    return _sink.mac();
  }

  /// Clears state (sink handles cleanup automatically on close).
  void clear() {
    // MacSink handles cleanup when closed
    if (!_closed) {
      _sink.close();
      _closed = true;
    }
  }
}
