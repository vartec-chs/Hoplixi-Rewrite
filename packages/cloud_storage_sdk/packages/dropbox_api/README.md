# 📂 DropboxApi

A Dart package that provides convenient access to the Dropbox API, built on top of `oauth2restclient`.

---

## ✨ Features

- 🔐 OAuth2 authentication via `oauth2restclient`
- 📄 List, upload, download, copy, move, rename, and delete Dropbox files
- 🗂 List and create folders
- 💡 Easy access to Dropbox Streams and metadata
- 📁 Supports only personal and not teams

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dropbox_api: ^0.0.1
```

---

## 🚀 Getting Started

```dart
import 'package:dropbox_api/dropbox_api.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

void main() async {
  final account = OAuth2Account();

  // Add Dropbox as an OAuth2 provider
  account.addProvider(Dropbox(
    clientId: "YOUR_CLIENT_ID",
    redirectUri: "YOUR_REDIRECT_URI",
    scopes: [
      "files.metadata.read",
      "files.content.read",
      "files.content.write"
    ],
  ));

  // Login or load token
  final token = await account.newLogin("dropbox");
  final client = await account.createClient(token);

  // Initialize API
  final dropbox = DropboxApi(client);

  // List files in the root
  final contents = await dropbox.listFolder("");

  for (final entry in contents.entries) {
    print("${entry.name} (${entry.path})");
  }
}
```

---

## 📂 Example Operations

- **List Files**:
```dart
await dropbox.listFolder("", limit: 20);
```

- **Upload File**:
```dart
await dropbox.upload("/example.txt", fileStream, mode: "add", autorename: true);
```

- **Create Folder**:
```dart
await dropbox.createFolder("/New Folder");
```

- **Download File**:
```dart
final stream = await dropbox.download("/example.txt");
```

- **Copy File**:
```dart
await dropbox.copy("/source.txt", "/target.txt");
```

- **Move/Rename File**:
```dart
await dropbox.move("/oldname.txt", "/newname.txt");
```

- **Delete File**:
```dart
await dropbox.delete("/example.txt");
```

---

## 🔗 Dependencies

- [`oauth2restclient`](https://pub.dev/packages/oauth2restclient)

---

## 📄 License

MIT License © Heebaek Choi