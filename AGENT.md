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

- The project utilizes the `result_dart: ^2.1.1` package for robust error handling. Exemples: 

```dart
import 'dart:io';

import 'package:result_dart/result_dart.dart';

void main(List<String> args) {
  final result = getTerminalInput() //
      .map(removeSpecialCharacteres)
      .flatMap(parseNumbers)
      .map(validateCPF);

  print('CPF Validator: ${result.isSuccess()}');
}

Result<String> getTerminalInput() {
  final text = stdin.readLineSync();
  if (text == null || text.isEmpty) {
    return const Failure(ValidatorException('Incorrect input'));
  }

  return Success(text);
}

String removeSpecialCharacteres(String input) {
  final reg = RegExp(r'(\D)');
  return input.replaceAll(reg, '');
}

Result<List<int>> parseNumbers(String input) {
  if (input.isEmpty) {
    return const Failure(ValidatorException('Input is Empty'));
  }

  try {
    final list = input.split('').map(int.parse).toList();
    return Success(list);
  } catch (e) {
    return const Failure(ValidatorException('Parse error'));
  }
}

bool validateCPF(List<int> numberDigits) {
  final secondRef = numberDigits.removeLast();
  final secondDigit = calculateDigit(numberDigits);
  if (secondRef != secondDigit) {
    return false;
  }

  final firstRef = numberDigits.removeLast();
  final firstDigit = calculateDigit(numberDigits);
  return firstRef == firstDigit;
}

int calculateDigit(List<int> digits) {
  final digitSum = sumDigits(digits.reversed.toList());
  final rest = digitSum % 11;
  if (rest < 2) {
    return 0;
  } else {
    return 11 - rest;
  }
}

int sumDigits(List<int> digits) {
  var multiplier = 2;
  var sum = 0;
  for (var d = 0; d < digits.length; d++, multiplier++) {
    sum += digits[d] * multiplier;
  }
  return sum;
}

class ValidatorException implements Exception {
  final String message;
  const ValidatorException(this.message);
}
```

Async operations example:

```dart

AsyncResult<String> fetchProducts() async {
    try {
      final response = await dio.get('/products');
      final products = ProductModel.fromList(response.data);
      return Success(products);
    } on DioError catch (e) {
      return Failure(ProductException(e.message));
    }
}

...

final state = await fetch()
    .map((products) => LoadedState(products))
    .mapLeft((failure) => ErrorState(failure))
```


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