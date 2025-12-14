# 📂 GoogleDriveRestClient

A Dart package that provides convenient access to the Google Drive REST API, built on top of `oauth2restclient`.

---

## ✨ Features

- 🔐 OAuth2 authentication via `oauth2restclient`
- 📄 List, upload, download, copy, move, and delete Google Drive files
- 🗂 List and create folders in My Drive or Shared Drives
- 💡 Easy access to Google Drive Streams and metadata
- 📁 Supports both personal drive and shared/team drives

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  google_drive_restclient: ^0.0.1
```

---

## 🚀 Getting Started

```dart
import 'package:google_drive_restclient/google_drive_restclient.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

void main() async {
  final account = OAuth2Account();

  // Add Google as an OAuth2 provider
  account.addProvider(Google(
    clientId: "YOUR_CLIENT_ID",
    redirectUri: "YOUR_REDIRECT_URI",
    scopes: [
      "https://www.googleapis.com/auth/drive",
      "openid", "email"
    ],
  ));

  // Login or load token
  final token = await account.newLogin("google");
  final client = await account.createClient(token);

  // Initialize API
  final drive = GoogleDrive(client);

  // List files in the root
  final files = await drive.listFiles(parentId: "root");

  for (final file in files.files) {
    print("${file.name} (${file.id})");
  }
}
```

---

## 📂 Example Operations

- **List Files**:
```dart
await drive.listFiles(parentId: 'root', onlyFile: true);
```

- **Upload File**:
```dart
await drive.createFile('root', 'example.txt', stream, fileSize: 123, contentType: 'text/plain', onProgress: (sent, total) {
  print('Uploaded $sent of $total bytes');
});
```

- **Create Folder**:
```dart
await drive.createFolder('root', 'New Folder');
```

- **Download File**:
```dart
final stream = await drive.downloadFile(fileId, onProgress: (sent, total) {
  print('Downloaded $sent of $total bytes');
});
```

- **Copy File**:
```dart
await drive.copyFile(sourceFileId, targetParentId);
```

- **Delete File**:
```dart
await drive.delete(fileId);
```

---

## 🔗 Dependencies

- [`oauth2restclient`](https://pub.dev/packages/oauth2restclient)

---

## 📄 License

MIT License © Heebaek Choi