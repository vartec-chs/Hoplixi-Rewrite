import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:crypto/crypto.dart';
import 'package:win32/win32.dart';

Never _win32Error(String operation) {
  final code = GetLastError();
  throw Exception('$operation failed (GetLastError=$code)');
}

int _handleFromPointer(Pointer p) => p.address;

Pointer _pointerFromHandle(int handle) => Pointer.fromAddress(handle);

Uint8List _sha256Utf16leFromUnits(Uint16List units) {
  final bytes = Uint8List(units.length * 2);
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    bytes[i * 2] = unit & 0xFF;
    bytes[i * 2 + 1] = (unit >> 8) & 0xFF;
  }
  return Uint8List.fromList(sha256.convert(bytes).bytes);
}

Uint8List _sha256Utf16leFromNullTerminatedPtr(Pointer<Uint16> ptr) {
  var len = 0;
  while (ptr[len] != 0) {
    len++;
  }

  final bytes = Uint8List(len * 2);
  for (var i = 0; i < len; i++) {
    final unit = ptr[i];
    bytes[i * 2] = unit & 0xFF;
    bytes[i * 2 + 1] = (unit >> 8) & 0xFF;
  }

  return Uint8List.fromList(sha256.convert(bytes).bytes);
}

Timer? _pendingClearTimer;
Uint8List? _pendingClearDigest;

void _withOpenClipboard(void Function() action) {
  final opened = OpenClipboard(0);
  if (opened == 0) {
    _win32Error('OpenClipboard');
  }
  try {
    action();
  } finally {
    CloseClipboard();
  }
}

int _setClipboardDataUtf16Units(Uint16List units) {
  final byteSize = (units.length + 1) * sizeOf<Uint16>();

  final hMem = GlobalAlloc(GMEM_MOVEABLE, byteSize);
  if (hMem == nullptr) {
    _win32Error('GlobalAlloc');
  }

  var transferred = false;
  try {
    final locked = GlobalLock(hMem);
    if (locked == nullptr) {
      _win32Error('GlobalLock');
    }
    try {
      final buf = locked.cast<Uint16>();
      for (var i = 0; i < units.length; i++) {
        buf[i] = units[i];
      }
      buf[units.length] = 0;
    } finally {
      GlobalUnlock(hMem);
    }

    final result = SetClipboardData(CF_UNICODETEXT, _handleFromPointer(hMem));
    if (result == 0) {
      _win32Error('SetClipboardData(CF_UNICODETEXT)');
    }

    transferred = true;
    return result;
  } finally {
    if (!transferred) {
      GlobalFree(hMem);
    }
  }
}

void _setMarkerFormatDwordZeroOpened(String formatName) {
  final fmt = using<int>((arena) {
    final namePtr = formatName.toNativeUtf16(allocator: arena);
    return RegisterClipboardFormat(namePtr);
  });

  if (fmt == 0) {
    // Non-fatal: format couldn't be registered.
    return;
  }

  final hMem = GlobalAlloc(GMEM_MOVEABLE, sizeOf<Uint32>());
  if (hMem == nullptr) {
    _win32Error('GlobalAlloc');
  }

  var transferred = false;
  try {
    final locked = GlobalLock(hMem);
    if (locked == nullptr) {
      _win32Error('GlobalLock');
    }
    try {
      locked.cast<Uint32>().value = 0;
    } finally {
      GlobalUnlock(hMem);
    }

    final result = SetClipboardData(fmt, _handleFromPointer(hMem));
    if (result == 0) {
      _win32Error('SetClipboardData($formatName)');
    }

    transferred = true;
  } finally {
    if (!transferred) {
      GlobalFree(hMem);
    }
  }
}

/// Best-effort: clears clipboard content.
///
/// Useful for app shutdown hooks / lifecycle events.
void clearClipboardNow() {
  final opened = OpenClipboard(0);
  if (opened == 0) return;
  try {
    EmptyClipboard();
  } finally {
    CloseClipboard();
  }
}

/// Cancels the scheduled TTL-based clipboard clear (if any).
void cancelScheduledClipboardClear() {
  _pendingClearTimer?.cancel();
  _pendingClearTimer = null;
  _pendingClearDigest = null;
}

/// Attempts to clear the clipboard *before* TTL expires.
///
/// This is safe-by-default: it only clears the clipboard if the current
/// `CF_UNICODETEXT` digest matches the secret that was last scheduled for TTL
/// cleanup.
///
/// Returns `true` if the clipboard was cleared.
bool clearScheduledSecretNow() {
  final expected = _pendingClearDigest;
  cancelScheduledClipboardClear();
  if (expected == null) return false;

  final currentDigest = _getClipboardUtf16leSha256Digest();
  if (currentDigest == null) return false;

  if (_bytesEqual(currentDigest, expected)) {
    clearClipboardNow();
    return true;
  }

  return false;
}

Uint8List? _getClipboardUtf16leSha256Digest() {
  Uint8List? digest;

  final opened = OpenClipboard(0);
  if (opened == 0) return null;

  try {
    final hData = GetClipboardData(CF_UNICODETEXT);
    if (hData == 0) return null;

    final locked = GlobalLock(_pointerFromHandle(hData));
    if (locked == nullptr) return null;

    try {
      digest = _sha256Utf16leFromNullTerminatedPtr(locked.cast<Uint16>());
    } finally {
      GlobalUnlock(_pointerFromHandle(hData));
    }
  } finally {
    CloseClipboard();
  }

  return digest;
}

/// High-security API: accepts UTF-16 code units directly.
///
/// This avoids creating an immutable Dart [String] for the secret.
/// Caller can overwrite [secretUtf16] after the call.
void copySecretWithTtlFromUtf16(Uint16List secretUtf16, Duration ttl) {
  final originalDigest = _sha256Utf16leFromUnits(secretUtf16);

  _withOpenClipboard(() {
    if (EmptyClipboard() == 0) {
      _win32Error('EmptyClipboard');
    }

    _setClipboardDataUtf16Units(secretUtf16);

    _setMarkerFormatDwordZeroOpened('CanIncludeInClipboardHistory');
    _setMarkerFormatDwordZeroOpened('CanUploadToCloudClipboard');
    _setMarkerFormatDwordZeroOpened(
      'ExcludeClipboardContentFromMonitorProcessing',
    );
    _setMarkerFormatDwordZeroOpened('Clipboard Viewer Ignore');
  });

  _pendingClearTimer?.cancel();
  _pendingClearDigest = originalDigest;
  _pendingClearTimer = Timer(ttl, () {
    final currentDigest = _getClipboardUtf16leSha256Digest();
    if (currentDigest == null) return;

    if (_bytesEqual(currentDigest, originalDigest)) {
      clearClipboardNow();
    }
  });
}

/// Public API: copy secret with TTL (KeePass-like)
void copySecretWithTtl(String secret, Duration ttl) {
  // Convenience wrapper. Still creates a Dart String (by definition), but
  // avoids retaining it in the TTL timer and compares clipboard content
  // without creating a new String.
  copySecretWithTtlFromUtf16(Uint16List.fromList(secret.codeUnits), ttl);
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.lengthInBytes != b.lengthInBytes) return false;
  var diff = 0;
  for (var i = 0; i < a.lengthInBytes; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
