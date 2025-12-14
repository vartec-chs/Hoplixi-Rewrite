# OAuth2RestClient AI Coding Instructions

You are working on `oauth2restclient`, a Dart/Flutter package for OAuth2 authentication and REST API interactions.

## 🏗 Project Architecture

- **Core Components**:
  - `OAuth2Account` ([../lib/src/oauth2_account.dart](../lib/src/oauth2_account.dart)): The central manager for providers and tokens. Handles login flows and token persistence.
  - `OAuth2Provider` ([../lib/src/provider/oauth2_provider.dart](../lib/src/provider/oauth2_provider.dart)): Abstract interface for auth providers. `OAuth2ProviderF` is the concrete implementation handling PKCE and redirects.
  - `OAuth2TokenStorage` ([../lib/src/token/oauth2_token_storage.dart](../lib/src/token/oauth2_token_storage.dart)): Abstract storage interface.
    - `OAuth2TokenStorageSecure`: Uses `flutter_secure_storage` (Mobile).
    - `OAuth2TokenStorageShared`: Uses `shared_preferences` (Desktop/Web).
  - `OAuth2RestClient` ([../lib/src/rest_client/oauth2_rest_client.dart](../lib/src/rest_client/oauth2_rest_client.dart)): Interface for authenticated HTTP requests.

## 🚀 Key Workflows & Patterns

### 1. Authentication Flow
- **Setup**: Instantiate `OAuth2Account` and add `OAuth2Provider` instances (e.g., `Google`, `Microsoft`).
- **Login**: Call `account.newLogin("provider_name")`.
  - **Desktop**: Spawns a local `HttpServer` to listen for the redirect callback.
  - **Mobile**: Relies on deep linking (via `app_links`) to capture the redirect.
- **Token Management**: Tokens are automatically saved using the appropriate storage strategy based on the platform.

### 2. Making Requests
- **Client Creation**: Use `account.createClient(token)` to get an `OAuth2RestClient`.
- **Usage**: Use methods like `getJson`, `postJson`, `getStream` on the client.
- **Auto-Refresh**: The client implementation automatically handles token expiration and refreshing transparently.

### 3. Adding New Providers
- Extend `OAuth2Provider` or instantiate `OAuth2ProviderF` with specific configuration (endpoints, scopes).
- Register the provider with `account.addProvider()`.

## 🛠 Development Guidelines

- **Platform Specifics**: Always consider platform differences (Mobile vs Desktop) when touching auth flows or storage.
  - Check `Platform.isAndroid || Platform.isIOS` for mobile-specific logic.
- **File Structure**:
  - Public API: Exported via `../lib/oauth2restclient.dart`.
  - Implementation: Kept in `../lib/src/`.
- **Naming**:
  - `*F` suffix (e.g., `OAuth2ProviderF`) often denotes the concrete/Flutter implementation of an interface.
- **Token Keys**: Follow the pattern `$appPrefix-$tokenPrefix-$service-$userName` for storage keys.

## 🧪 Testing & Debugging
- **Example App**: Use `../example/lib/main.dart` to test changes in a real Flutter environment.
- **Local Server**: When debugging desktop auth, ensure the local server port matches the redirect URI configuration.
