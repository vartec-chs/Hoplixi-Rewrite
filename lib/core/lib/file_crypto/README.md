# File Crypto Module

Модуль `file_crypto` предоставляет надежные возможности шифрования и дешифрования файлов с использованием современных криптографических стандартов. Он поддерживает шифрование отдельных файлов, пакетную обработку, потоковую передачу для больших файлов и шифрование архивов.

## Основные возможности

*   **Надежное шифрование:** Использует алгоритм **XChaCha20-Poly1305** для аутентифицированного шифрования (AEAD).
*   **Безопасная генерация ключей:** Использует **Argon2id** для деривации ключей из паролей, обеспечивая защиту от атак перебором.
*   **Потоковая обработка:** Эффективно обрабатывает файлы любого размера с минимальным потреблением памяти.
*   **Пакетная обработка:** Поддерживает одновременное шифрование/дешифрование множества файлов.
*   **Архивация:** Сжимает и шифрует директории или группы файлов в единый защищенный архив.
*   **Защита метаданных:** Шифрует метаданные файла (оригинальное имя, расширение) внутри заголовка.
*   **Проверка целостности:** Использует тег аутентификации Poly1305 и дополнительный HMAC-SHA256 для верификации данных.

## Структура модуля

*   **`interfaces/`**: Интерфейсы и абстракции.
*   **`models/`**: Модели данных (заголовки, результаты операций).
*   **`services/`**: Реализация логики шифрования.
    *   `FileEncryptionService`: Базовый сервис шифрования файлов.
    *   `StreamingEncryptionService`: Сервис для потокового шифрования больших файлов.
    *   `BatchEncryptionService`: Сервис для пакетной обработки файлов.
    *   `ArchiveEncryptor`: Сервис для создания и шифрования архивов.
    *   `KeyDerivationService`: Сервис генерации криптографических ключей.

## Формат зашифрованного файла

Зашифрованный файл имеет следующую структуру:

```
[Salt (16 bytes)]           - Соль для деривации ключа
[Nonce (24 bytes)]          - Уникальный номер (IV) для XChaCha20
[Encrypted Header + Content]- Зашифрованные данные (включая метаданные)
[Auth Tag (16 bytes)]       - Тег аутентификации Poly1305
[HMAC (32 bytes)]           - Дополнительная подпись HMAC-SHA256
```

## Примеры использования

### 1. Шифрование одного файла (Streaming)

Используйте `StreamingEncryptionService` для эффективного шифрования файлов любого размера.

```dart
import 'package:file_enc/src/file_crypto/services/streaming_encryption_service.dart';

final service = StreamingEncryptionService();

try {
  final result = await service.encryptFile(
    inputPath: 'path/to/document.pdf',
    outputPath: 'path/to/document.enc',
    password: 'user-secure-password',
    onProgress: (bytes, total) {
      print('Progress: ${(bytes / total * 100).toStringAsFixed(1)}%');
    },
  );
  print('File encrypted: ${result.outputPath}');
} catch (e) {
  print('Encryption failed: $e');
}
```

### 2. Дешифрование файла

```dart
try {
  final result = await service.decryptFile(
    inputPath: 'path/to/document.enc',
    outputPath: 'path/to/document_decrypted.pdf',
    password: 'user-secure-password',
    onProgress: (bytes, total) {
      print('Progress: ${(bytes / total * 100).toStringAsFixed(1)}%');
    },
  );
  print('File decrypted: ${result.outputPath}');
} catch (e) {
  print('Decryption failed: $e');
}
```

### 3. Пакетная обработка

Используйте `BatchEncryptionService` для обработки списка файлов.

```dart
import 'package:file_enc/src/file_crypto/services/batch_encryption_service.dart';

final batchService = BatchEncryptionService();
final files = ['file1.txt', 'file2.jpg', 'file3.doc'];

final results = await batchService.encryptFiles(
  filePaths: files,
  password: 'password123',
  outputDirectory: 'encrypted_files/',
);

for (var result in results) {
  if (result.success) {
    print('Encrypted: ${result.originalPath}');
  } else {
    print('Error encrypting ${result.originalPath}: ${result.error}');
  }
}
```

### 4. Шифрование архива (директории)

Используйте `ArchiveEncryptor` для сжатия и шифрования папок.

```dart
import 'package:file_enc/src/file_crypto/services/archive_encryptor.dart';

final archiveEncryptor = ArchiveEncryptor();

await archiveEncryptor.encryptDirectory(
  directoryPath: 'path/to/my_folder',
  outputPath: 'path/to/archive.enc',
  password: 'secure-password',
  onProgress: (bytes, total) {
    print('Archiving... $bytes / $total');
  },
);
```

## Безопасность

*   **Алгоритмы:** XChaCha20-Poly1305 (IETF), Argon2id, HMAC-SHA256.
*   **Ключи:** Для каждой операции генерируется уникальная соль. Ключи шифрования и аутентификации разделены.
*   **Память:** `KeyDerivationService` реализует best-effort очистку ключей из памяти (насколько это позволяет Dart GC).

## Зависимости

*   `cryptography`: Реализация криптографических примитивов.
*   `archive`: Работа с ZIP архивами.
*   `uuid`: Генерация уникальных идентификаторов.
*   `path`: Работа с путями файловой системы.
