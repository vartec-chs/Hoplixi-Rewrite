import 'dart:typed_data';
import 'package:secure_clipboard_win/secure_clipboard_win.dart';

void main() {
  // Example 1: Basic usage with String (convenience API)
  print('Example 1: Copying password with TTL');
  copySecretWithTtl('MyS3cr3tP@ss!', const Duration(seconds: 12));
  print('Password copied securely for 12 seconds');

  // Example 2: High-security usage with UTF-16 units (no String creation)
  print('\nExample 2: High-security copy with UTF-16 units');
  final secretUtf16 = Uint16List.fromList('UltraSecretKey123'.codeUnits);
  copySecretWithTtlFromUtf16(secretUtf16, const Duration(seconds: 10));
  print('Secret copied securely for 10 seconds');

  // After copying, you can safely overwrite the buffer:
  secretUtf16.fillRange(0, secretUtf16.length, 0);
  print('Secret buffer zeroed out');

  // Example 3: Early clear (before TTL expires)
  print('\nExample 3: Early clear');
  copySecretWithTtl('TempPassword', const Duration(seconds: 30));
  print('Temp password copied for 30 seconds');

  // Simulate user action: clear immediately if needed
  final cleared = clearScheduledSecretNow();
  print('Cleared early: $cleared');

  // Example 4: Cancel scheduled clear
  print('\nExample 4: Cancel scheduled clear');
  copySecretWithTtl('AnotherSecret', const Duration(seconds: 20));
  print('Secret copied for 20 seconds');

  cancelScheduledClipboardClear();
  print('Scheduled clear cancelled');

  // Example 5: Force clear (best-effort, for shutdown hooks)
  print('\nExample 5: Force clear clipboard');
  clearClipboardNow();
  print('Clipboard cleared (if accessible)');
}
