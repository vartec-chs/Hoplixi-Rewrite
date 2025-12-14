# Changelog

## 0.0.2

*API parameters simplified to use full paths
  * `createFolder(parentPath, name)` → `createFolder(path)`
  * `move(path, newParentPath, newName)` → `move(path, newPath)`
  * `copy(path, newParentPath, newName)` → `copy(path, newPath)`

## 0.0.1

* Initial release of the OneDrive API client
* Features:
  - OAuth2 authentication via oauth2restclient
  - Path-based API for intuitive file operations
  - File operations (upload, download, copy, move, delete)
  - Folder operations (list, create)
  - User and drive information retrieval
  - Microsoft Graph API integration
  - Automatic path encoding for special characters
  - Support for both personal and business OneDrive 