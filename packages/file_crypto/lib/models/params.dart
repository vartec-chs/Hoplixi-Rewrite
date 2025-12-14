import 'dart:isolate';

class EncryptionParams {
  final String inputPath;
  final String outputPath;
  final String password;
  final String? customUuid;
  final int chunkSize;
  final SendPort? sendPort;
  final int originalSize;
  final bool enableGzip;

  EncryptionParams({
    required this.inputPath,
    required this.outputPath,
    required this.password,
    this.customUuid,
    required this.chunkSize,
    this.sendPort,
    required this.originalSize,
    required this.enableGzip,
  });
}

class DecryptionParams {
  final String inputPath;
  final String outputPath;
  final String password;
  final SendPort? sendPort;

  DecryptionParams({
    required this.inputPath,
    required this.outputPath,
    required this.password,
    this.sendPort,
  });
}
