# secure_clipboard_win

A Dart package for securely copying sensitive data (like passwords) to the Windows clipboard with automatic TTL-based cleanup, KeePass-style.

## Features

- **Secure clipboard copying** with automatic expiration
- **High-security API** accepting UTF-16 units directly (no immutable String creation)
- **Digest-based verification** to avoid retaining secrets in memory
- **Early clear** capability (safe, digest-verified)
- **Windows clipboard markers** to exclude from history/cloud sync
- **Memory-safe** with proper FFI resource management

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  secure_clipboard_win: ^1.0.0
```

Import:

```dart
import 'package:secure_clipboard_win/secure_clipboard_win.dart';
```

## Usage

### Basic usage

```dart
import 'package:secure_clipboard_win/secure_clipboard_win.dart';

void main() {
  // Copy password for 30 seconds, then auto-clear
  copySecretWithTtl('MySecretPassword!', const Duration(seconds: 30));
}
```

### High-security usage (no String creation)

```dart
import 'dart:typed_data';
import 'package:secure_clipboard_win/secure_clipboard_win.dart';

void main() {
  // Prepare UTF-16 units
  final secretUtf16 = Uint16List.fromList('UltraSecretKey'.codeUnits);

  // Copy without creating immutable String
  copySecretWithTtlFromUtf16(secretUtf16, const Duration(seconds: 15));

  // Zero out buffer after use
  secretUtf16.fillRange(0, secretUtf16.length, 0);
}
```

### Early clear and cancellation

```dart
// Copy secret
copySecretWithTtl('TempPassword', const Duration(seconds: 60));

// Clear immediately (safe: only if clipboard still matches)
final cleared = clearScheduledSecretNow();
print('Cleared: $cleared');

// Or cancel the timer without clearing
cancelScheduledClipboardClear();

// Force clear (best-effort, for shutdown hooks)
clearClipboardNow();
```

## API Reference

### Core functions

- `void copySecretWithTtl(String secret, Duration ttl)`  
  Convenience API: copies String to clipboard with TTL cleanup.

- `void copySecretWithTtlFromUtf16(Uint16List secretUtf16, Duration ttl)`  
  High-security API: copies UTF-16 units directly, avoids String creation.

### Management functions

- `bool clearScheduledSecretNow()`  
  Safely clears clipboard before TTL if content matches scheduled secret.  
  Returns `true` if cleared.

- `void cancelScheduledClipboardClear()`  
  Cancels the pending TTL timer without clearing clipboard.

- `void clearClipboardNow()`  
  Best-effort force clear (useful for app shutdown).

## Security notes

- Uses SHA-256 digest comparison instead of retaining secrets in memory
- Sets Windows clipboard markers to exclude from history/cloud sync
- Proper FFI resource management with try/finally
- No re-entrant clipboard operations

## Platform support

Windows only (uses Win32 API).

## Additional information

For more examples, see `/example` folder.

Contributions welcome! Please file issues for bugs or feature requests.
