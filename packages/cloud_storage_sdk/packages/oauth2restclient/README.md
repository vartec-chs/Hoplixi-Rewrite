# 🔐 OAuth2RestClient

A Dart/Flutter package that simplifies OAuth2 authentication and REST API interactions with automatic token management.

---

## ✨ Features

- **OAuth2 Authentication**: Easy implementation of OAuth2 login flows.
- **Account Management**: Securely store and load user accounts and tokens.
- **Automatic Token Handling**: Transparently manages access tokens in request headers.
- **Token Refresh**: Automatically refreshes expired tokens when needed.
- **Service Integration**: Simplifies integration with REST APIs like Google Drive.

---

## 📦 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  oauth2restclient: ^0.0.4
```

Then, run:

```bash
flutter pub get
```

---

## 🚀 Getting Started

Here's how to integrate `oauth2restclient` into your Flutter application:

```dart
import 'package:oauth2restclient/oauth2restclient.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  await dotenv.load(); // Load environment variables

  final account = OAuth2Account();

  var google = Google(
    redirectUri: "com.googleusercontent.apps.95012368401-j0gcpfork6j38q3p8sg37admdo086gbs:/oauth2redirect",
    scopes: [
      'https://www.googleapis.com/auth/drive',
      "https://www.googleapis.com/auth/photoslibrary",
      "openid",
      "email"
    ],
    clientId: dotenv.env["MOBILE_CLIENT_ID"]!,
  );

  if (Platform.isMacOS) {
    google = Google(
      redirectUri: "http://localhost:8713/pobpob",
      scopes: [
        'https://www.googleapis.com/auth/drive',
        "https://www.googleapis.com/auth/photoslibrary",
        "openid",
        "email"
      ],
      clientId: dotenv.env["DESKTOP_CLIENT_ID"]!,
      clientSecret: dotenv.env["DESKTOP_CLIENT_SECRET"]!,
    );
  }

  account.addProvider(google);

  // Initiate login
  var token = await account.newLogin("google");

  // Or load existing account
  token = await account.loadAccount("google", "userName");

  // Create an authenticated HTTP client
  var client = await account.createClient(token);

  // Use the client to make authenticated requests
  final response = await client.getJson('https://www.googleapis.com/drive/v3/files');
}
```

---

## 📂 Related Packages

If you're looking to access **Google Drive** using this OAuth2 client, check out:

👉 [`google_drive_api`](https://pub.dev/packages/google_drive_api)
A full-featured Dart package for interacting with the Google Drive REST API, built on top of `oauth2restclient`.

> 🔧 GitHub (development): [github.com/heebaek/google_drive_api](https://github.com/heebaek/google_drive_api)

---

## 🧪 Testing

To test the authentication flow:

1. Set up your OAuth2 provider (e.g., Google) and obtain the necessary credentials.
2. Configure the redirect URIs appropriately for your platform.
3. Run the application and initiate the login process.
4. Verify that tokens are stored securely and that authenticated requests succeed.

---

## 📄 License

MIT License © Heebaek Choi (https://github.com/yourgithub)

---

## 🙌 Contributions

Contributions are welcome! Feel free to open issues or submit pull requests to enhance the functionality of this package.