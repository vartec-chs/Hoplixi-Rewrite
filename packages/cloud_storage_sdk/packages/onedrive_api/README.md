# 📂 OneDriveRestApi

A Dart package that provides convenient access to the OneDrive API, built on top of `oauth2restclient`.

---

## ✨ Features

- 🔐 OAuth2 authentication via `oauth2restclient`
- 📄 List, upload, download, copy, move, and delete OneDrive files
- 🗂 List and create folders
- 💡 Easy access to OneDrive Streams and metadata
- 📁 Supports both personal and business OneDrive
- 🛤 Path-based API for intuitive file operations

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  onedrive_rest_api: ^0.0.2
```

---

## 🚀 Getting Started

```dart
import 'package:onedrive_rest_api/onedrive_rest_api.dart';

void main() async {
  final account = OAuth2Account();

  // Microsoft OAuth2 provider 등록
  account.addProvider(Microsoft(
    clientId: "YOUR_CLIENT_ID",
    redirectUri: "YOUR_REDIRECT_URI",
    scopes: [
      "User.Read",
      "Files.ReadWrite.All",
      "Files.Read.All",
      "openid",
      "email",
      "offline_access",
    ],
  ));

  // 로그인 또는 토큰 로드
  final token = await account.newLogin("microsoft");
  final client = await account.createClient(token);

  // API 인스턴스 생성
  final onedrive = OneDriveRestApi(client);

  // 드라이브 정보 가져오기
  final drive = await onedrive.getDrive();
  print("Drive ID: ${drive.id}");

  // 루트 폴더 파일 목록 조회
  final items = await onedrive.listChildren("/");

  for (final item in items.value) {
    print("${item.name} (${item.id})");
  }
}
```

---

## 📂 Example Operations

- **List Files**:
```dart
// 루트 디렉토리 내용 조회
await onedrive.listChildren("/", top: 20);

// 특정 폴더 내용 조회
await onedrive.listChildren("/Documents", top: 20);
```

- **Upload File**:
```dart
// 루트에 파일 업로드
await onedrive.upload("/example.txt", fileStream);

// 특정 폴더에 파일 업로드
await onedrive.upload("/Documents/report.pdf", fileStream);
```

- **Create Folder**:
```dart
// 루트에 폴더 생성
await onedrive.createFolder("/New Folder");

// 특정 폴더 안에 하위 폴더 생성
await onedrive.createFolder("/Documents/Work");
```

- **Download File**:
```dart
// 파일 다운로드
final stream = await onedrive.download("/Documents/file.txt");
```

- **Copy File**:
```dart
// 파일 복사 (같은 이름)
await onedrive.copy("/Documents/file.txt", "/Backup/file.txt");

// 파일 복사 (다른 이름)
await onedrive.copy("/Documents/file.txt", "/Backup/file_copy.txt");
// ⚠️ 복사는 비동기 작업입니다. 복사 완료까지 시간이 걸릴 수 있습니다.
```

- **Move/Rename File**:
```dart
// 파일 이동 (같은 이름)
await onedrive.move("/Documents/file.txt", "/Pictures/file.txt");

// 파일 이동하면서 이름 변경
await onedrive.move("/Documents/file.txt", "/Pictures/new_name.txt");

// 같은 폴더에서 이름만 변경
await onedrive.move("/Documents/file.txt", "/Documents/new_name.txt");
```

- **Delete File**:
```dart
// 파일 삭제
await onedrive.delete("/Documents/file.txt");

// 폴더 삭제
await onedrive.delete("/Documents/Old Folder");
```

---

## 🛤 Path-based API

- 모든 주요 함수는 **경로(path)만** 받습니다. (ID 기반 아님)
- 루트로 복사/이동/생성 시 경로는 `/` 또는 `""`(빈 문자열)로 처리하면 됩니다.
- copy/move는 반환값이 없으며, copy는 비동기 작업이므로 바로 복사본이 보이지 않을 수 있습니다.

### 경로 예제

```dart
// 루트 디렉토리
"/"

// 폴더
"/Documents"
"/Pictures"
"/Documents/Work"

// 파일
"/Documents/file.txt"
"/Pictures/photo.jpg"
"/Documents/Work/report.pdf"
```


