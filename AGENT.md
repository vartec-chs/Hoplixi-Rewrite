# Project Info

This project is named Hoplixi, a Flutter application designed to provide users with a seamless experience. Hoplixi is a password manager app that helps users securely store and manage their passwords.

## Features

- Secure password storage
- User-friendly interface
- Cross-platform support

## Technologies Used

- Flutter
- Dart
- SQLite
- SQLCipher
- Riverpod
- Freezed

## Error Handling

- The project utilizes the `result_dart: ^2.1.1` package for robust error handling.

- For more information on how to use `result_dart`, please refer to the [official documentation](https://pub.dev/packages/result_dart).

- For modules, write your own errors, for example:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_errors.freezed.dart';

@freezed
abstract class DatabaseError with _$DatabaseError implements Exception {
  const DatabaseError._();

  const factory DatabaseError.invalidPassword({
    @Default('DB_INVALID_PASSWORD') String code,
    @Default('Неверный пароль для базы данных') String message,
    Map<String, dynamic>? data,
    @JsonKey(includeToJson: true) StackTrace? stackTrace,
    @JsonKey(includeToJson: true) DateTime? timestamp,
  }) = InvalidPasswordError;
}
```

## MCP Servers and Advanced Scenarios

- Library documentation: query via the context7 MCP server (get up-to-date signatures and usage patterns).
- Multi-step tasks (migrations, service refactoring): use SequentialThinking MCP – it captures the plan and provides progress metrics.
- Dart/Flutter mcp: use DartMCP for code analysis and suggestions.

## Additional notes about freezed

Use the @freezed surface of an abstract sealed class.
Don't create instances of private implementations through constructors—only in the factory.
After adding, run a build (otherwise, you'll get a missing parts error).