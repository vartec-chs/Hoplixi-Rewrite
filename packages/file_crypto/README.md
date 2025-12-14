# File Crypto Module

Модуль `file_crypto` объединяет сервисы для шифрования файлов и директорий на базе
современных криптографических примитивов. Он скрывает детали gzip/zip-архивации,
потокового шифрования и множественной проверки целостности за удобным API.

## Основные возможности

* **AEAD + потоковые чанки:** XChaCha20-Poly1305 шифрует данные чанками
  с уникальными nonce, каждый фрагмент сопровождается Poly1305-меткой, а весь
  файл защищён отдельным HMAC-SHA256.
* **Архивация и сжатие:** `ArchiveEncryptor` умеет упаковывать директории в ZIP,
  сжимать gzip и обрабатывать файлы любого размера с минимальной памятью.
* **Метаданные:** Заголовок содержит `uuid`, оригинальное имя, расширение,
  флаг директории и размеры до/после сжатия, что позволяет восстановить структуру.
* **Пакетная обработка:** `BatchEncryptionService` шифрует/дешифрует сотни файлов
  с отслеживанием прогресса, отчётом по каждому пути и контролем параллелизма.
* **Безопасная генерация ключей:** `KeyDerivationService` использует Argon2id,
  возвращая отдельные ключи для AEAD и HMAC, а также встраивает проверку параметров.
* **Работа с метаданными:** В любое время можно прочитать заголовок через
  `ArchiveEncryptor.readHeader`, не расшифровывая содержимое полностью.

## Структура модуля

* **`interfaces/`**: `IEncryptor`, `ProgressCallback`, `EncryptionOperationResult` и
  `DecryptionOperationResult` описывают контракт для шифрования/дешифрования.
* **`models/`**: `ArchiveEncryptionHeader`, стриминговая поддержка (`ChunkBufferArchive`,
  `StreamingHmacArchive`), параметры (Argon2) и исключения
  (`EncryptionExceptionArchive`, `DecryptionExceptionArchive`, `AuthenticationExceptionArchive`).
* **`services/`**:
  * `ArchiveEncryptor` — основной класс для шифрования файлов/директорий,
    потоковой обработки чанков и работы с заголовком/сжатым потоком.
  * `BatchEncryptionService` — групповые операции с прогрессом, отчётами и
    ограничением числа параллельных задач.
  * `KeyDerivationService` — Argon2id, выделяющий ключи для AEAD и HMAC + утилиты.

## Основные сервисы

### ArchiveEncryptor

`ArchiveEncryptor` работает с файлами и папками, упаковывает директории в ZIP,
сжимает поток gzip, разбивает данные на чанки, шифрует их XChaCha20-Poly1305 и
считает HMAC на лету. Для больших файлов включается `Isolate` (порог 100 МБ) и
данные пишутся в выходной файл блоками фиксированного размера.

```dart
import 'package:file_enc/src/file_crypto/services/encryptor.dart';

final encryptor = ArchiveEncryptor();

final result = await encryptor.encrypt(
  inputPath: 'documents/report.pdf',
  outputPath: 'documents/report.enc',
  password: 'user-secure-password',
  onProgress: (processed, total) {
    print('Encrypted $processed / $total bytes');
  },
);

final header = await encryptor.readHeader(
  inputPath: result.outputPath,
  password: 'user-secure-password',
);

await encryptor.decrypt(
  inputPath: result.outputPath,
  outputPath: 'documents/decrypted/',
  password: 'user-secure-password',
  onProgress: (processed, total) {
    print('Decrypted $processed / $total bytes');
  },
);
```

`readHeader` позволяет получить `originalName`, `wasDirectory`, `compressedSize` и
`uuid`, чтобы, например, показать пользователю детализацию до фактической декрипции.

### BatchEncryptionService

Сервис упрощает шифрование/дешифрование сотен файлов. Он создаёт `BatchFileResult` для
каждого пути, не прерывает пакет при ошибках и вызывает `onProgress` после
каждого обработанного файла. Можно гибко настраивать `concurrency`, `outputExtension`
и `fileFilter` для папок.

```dart
import 'package:file_enc/src/file_crypto/services/batch_encryption_service.dart';

final batchService = BatchEncryptionService();
final files = <String>[...];

final summary = await batchService.encryptFiles(
  inputPaths: files,
  outputDirectory: 'encrypted/',
  password: 'password123',
  concurrency: 4,
  onProgress: (processed, total, path) {
    print('Processing $path ($processed/$total)');
  },
);

if (!summary.allSucceeded) {
  for (final failure in summary.failures) {
    print('Failed: ${failure.originalPath} — ${failure.error}');
  }
}
```

### KeyDerivationService

Оборачивает Argon2id с хорошими дефолтами (19 MiB, 2 итерации, `keyLength = 32`)
и возвращает `DerivedKeyPair` с отдельными ключами для шифрования и HMAC. Экспорт
предоставляет `deriveKeyPair`, `deriveKeyPairWithSalt`, `validateParameters` и
устаревшие утилиты, если нужно работать с сырыми байтами.

```dart
final keyPair = await KeyDerivationService.deriveKeyPair(
  password: 'user-password',
);

await KeyDerivationService.validateParameters(
  memory: 19 * 1024,
  parallelism: 1,
  iterations: 2,
);

final sameKeyPair = await KeyDerivationService.deriveKeyPairWithSalt(
  password: 'user-password',
  salt: keyPair.salt,
);
```

`DerivedKeyPair` хранит соль и предоставляет `destroy` по мере возможности для
мягкой очистки ключей.

## Формат зашифрованного файла

Файл строится из следующих блоков:

1. **Magic и версия:** `AENC` + `0x01`, чтобы быстро отвергать несовместимые
  файлы.
2. **Соль (16 байт):** используется для Argon2id, она сохраняется в начале,
  чтобы расшифровать заголовок и содержимое.
3. **Зашифрованный заголовок:** длина (4 байта, big endian), шифротекст и
  Poly1305-тег (16 байт). Заголовок содержит `uuid`, `originalName`,
  расширение, флаги директории и размеры.
4. **Chunk metadata:** `chunkSize` (4 байта) и `chunkCount` (8 байт) определяют
  размер и количество чанков.
5. **Чанки:** каждый состоит из `nonce` (24 байта) + шифротекста (равный
  размеру чанка) + `auth tag` (16 байт). Последний чанк может быть меньше
  `chunkSize`, в соответствии с `compressedSize` в заголовке.
6. **HMAC-SHA256 (32 байта):** считается по всем предыдущим байтам,
  включая nonce, ciphertext и тестовые теги, чтобы гарантировать, что данные
  не были изменены.

Заголовок можно передать в клиент (UI/CLI) чтобы отобразить оригинальное имя и
расширение до расшифровки, а `chunkSize` даёт гарантию на размер буфера для
дешифровки.

## Обработка ошибок и проверка целостности

* `EncryptionExceptionArchive` и `DecryptionExceptionArchive` сопровождаются
  поясняющими сообщениями.
* `AuthenticationExceptionArchive` выбрасывается, если Poly1305 или HMAC
  не прошли проверку.
* `BatchFileResult.failure` сохраняет строку ошибки и не прерывает обработку
  всего пакета, что удобно для CLI или UI.

## Зависимости

* `cryptography`: AEAD, HMAC, SecretKey и Argon2id.
* `archive`: код для ZIP и gzip.
* `uuid`: генерация уникальных UUID для заголовка.
* `path`: построение выходных путей и выделение расширений.

## AI Integration

For detailed usage patterns and context optimized for AI assistants, please refer to [AI_SDK_GUIDE.md](AI_SDK_GUIDE.md).
