# Yandex Disk API Endpoints

## 1. Disk Information

### Get Disk Data
**Description:** Returns general information about the user's Yandex Disk: available space, system folder paths, etc.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/`
**Input Parameters:** None
**Output:**
```json
{
  "trash_size": 4631577437,
  "total_space": 319975063552,
  "used_space": 26157681270,
  "system_folders":
  {
    "applications": "disk:/Приложения",
    "downloads": "disk:/Загрузки/"
  }
}
```

## 2. File and Folder Meta Information

### Get Meta Information
**Description:** Get meta information for a file or folder.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources`
**Input Parameters:**
*   `path` (required): Path to the resource (e.g., `/foo/bar`).
*   `fields`: List of properties to include in the response.
*   `limit`: Max number of resources in a folder (default 20).
*   `offset`: Offset from the beginning of the list.
*   `preview_size`: Size of the preview image (S, M, L, XL, XXL, XXXL or 120x120).
*   `preview_crop`: `true`/`false`.
*   `sort`: Sort field (`name`, `path`, `created`, `modified`, `size`). Use `-` for descending.
**Output:** `Resource` object.
```json
{
  "public_key": "string",
  "_embedded": {
    "sort": "string",
    "path": "string",
    "items": [ "Resource object" ],
    "limit": "number",
    "offset": "number",
    "total": "number"
  },
  "name": "string",
  "created": "string (ISO 8601)",
  "custom_properties": "object",
  "public_url": "string",
  "modified": "string (ISO 8601)",
  "path": "string",
  "type": "string (dir/file)",
  "mime_type": "string",
  "size": "number"
}
```

### Update Meta Information (Add Custom Properties)
**Description:** Add or update custom properties for a resource.
**Method:** `PATCH`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources`
**Input Parameters:**
*   `path` (required): Path to the resource.
*   `fields`: Properties to include in response.
**Request Body:**
```json
{
  "custom_properties": {
    "key": "value"
  }
}
```
**Output:** Updated `Resource` object.

## 3. Files Lists

### Flat List of All Files
**Description:** Returns a flat list of all files on Disk, useful for searching.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/files`
**Input Parameters:**
*   `limit`: Number of files (default 20).
*   `media_type`: Filter by type (audio, video, image, document, etc.).
*   `offset`: Offset.
*   `fields`: Response fields.
*   `preview_size`: Preview size.
*   `preview_crop`: Crop flag.
**Output:**
```json
{
  "items": [ "Resource object" ],
  "limit": "number",
  "offset": "number"
}
```

### Last Uploaded Files
**Description:** Returns the list of most recently uploaded files.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/last-uploaded`
**Input Parameters:**
*   `limit`: Number of files.
*   `media_type`: Filter by type.
*   `fields`: Response fields.
*   `preview_size`: Preview size.
*   `preview_crop`: Crop flag.
**Output:**
```json
{
  "items": [ "Resource object" ],
  "limit": "number"
}
```

### Добавление метаинформации для ресурса
Для любого файла или папки, доступной на запись, можно задать дополнительные произвольные атрибуты. Эти атрибуты будут возвращаться в ответ на все запросы метаинформации о ресурсах (список всех файлов, последние загруженные и т. д.)
Формат запроса
Запрос добавления метаинформации следует отправлять с помощью метода PATCH.
```
https://cloud-api.yandex.net/v1/disk/resources/
 ? path=<путь к ресурсу>
 & [fields=<свойства, которые нужно включить в ответ>]
```
Output: 
```json
{
  "public_key": "HQsmHLoeyBlJf8Eu1jlmzuU+ZaLkjPkgcvmokRUCIo8=",
  "_embedded": {
    "sort": "",
    "path": "disk:/foo",
    "items": [
      {
        "path": "disk:/foo/bar",
        "type": "dir",
        "name": "bar",
        "modified": "2014-04-22T10:32:49+04:00",
        "created": "2014-04-22T10:32:49+04:00"
      },
      {
        "name": "photo.png",
        "preview": "https://downloader.disk.yandex.ru/preview/...",
        "created": "2014-04-21T14:57:13+04:00",
        "modified": "2014-04-21T14:57:14+04:00",
        "path": "disk:/foo/photo.png",
        "md5": "4334dc6379c8f95ddf11b9508cfea271",
        "type": "file",
        "mime_type": "image/png",
        "size": 34567
      }
    ],
    "limit": 20,
    "offset": 0
  },
  "name": "foo",
  "created": "2014-04-21T14:54:42+04:00",
  "custom_properties": {"foo":"1", "bar":"2"},
  "public_url": "https://yadi.sk/d/AaaBbb1122Ccc",
  "modified": "2014-04-22T10:32:49+04:00",
  "path": "disk:/foo",
  "type": "dir"
}
```

## 4. Upload and Download

### Get Upload URL
**Description:** Request a URL to upload a file.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/upload`
**Input Parameters:**
*   `path` (required): Destination path (e.g., `/folder/file.txt`).
*   `overwrite`: `true`/`false` (default `false`).
*   `fields`: Response fields.
**Output:**
```json
{
  "operation_id": "cbb77e87cc43bcdcdd2de397cd05b43368b9e2bda78eab1f94037c9c38a31e43",
  "href": "https://uploader1d.dst.yandex.net:443/upload-target/...",
  "method": "PUT",
  "templated": false
}
```
*Note: Upload the file content to the returned `href` using `PUT`.*

### Сохранение файла из интернета на Диск
Яндекс Диск может скачать файл на Диск пользователя. Для этого следует передать в запросе URL файла и следить за ходом операции. Если при скачивании возникла ошибка, Диск не будет пытаться скачать файл еще раз.
Метод: POST.
https://cloud-api.yandex.net/v1/disk/resources/upload
 ? url=<ссылка на скачиваемый файл>
 & path=<путь к папке, в которую нужно скачать файл>
 & [fields=<свойства, которые нужно включить в ответ>]
 & [disable_redirects=<признак запрета редиректов>]

**Output:**
```json
{
  "href": "https://cloud-api.yandex.net/v1/disk/operations?id=33ca7d03ab21ct41b4a40182e78d828a3f8b72cdb5f4c0e94cc4b1449a63a2fe",
  "method": "GET",
  "templated": false
}
```

### Get Download URL
**Description:** Request a URL to download a file.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/download`
**Input Parameters:**
*   `path` (required): Path to the file.
*   `fields`: Response fields.
**Output:**
```json
{
  "href": "string (download url)",
  "method": "string (GET)",
  "templated": "boolean"
}
```

Скачивание файла по полученному URL
Скачивать файл следует с помощью метода GET.

Пример URL для скачивания:

https://downloader.dst.yandex.ru/disk/53139aa0et584d3bac7eeab405d3574b/535320b4/YyjTJtEHob8R5WbpojJbiiUuU2HC_2JSTU0gW9qE0NHGW2uncmBjM_-IXun3Msyij96FTHQGSX-fDL-XwokDvA%3D%3D?uid=202727674&filename=photo.png&disposition=attachment&hash=&limit=0&content_type=application%2Fx-www-form-urlencoded&fsize=34524&hid=93528043563b8r55723a253f4730290a&media_type=document

Если запрос был обработан без ошибок, API отвечает одним из способов:

Кодом 200 OK с телом ответа, в котором содержится скачиваемый файл.
Кодом 302 Found с заголовком Location. Заголовок содержит адрес вида *.storage.yandex.net, с которого происходит скачивание файла.


Путь в значении параметра следует кодировать в URL-формате.

## 5. File Operations

### Create Folder
**Description:** Create a new folder.
**Method:** `PUT`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources`
**Input Parameters:**
*   `path` (required): Path to the new folder.
*   `fields`: Response fields.
**Output:** `Link` object.

### Copy Resource
**Description:** Copy a file or folder.
**Method:** `POST`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/copy`
**Input Parameters:**
*   `from` (required): Source path.
*   `path` (required): Destination path.
*   `overwrite`: `true`/`false`.
*   `fields`: Response fields.
**Output:** `Link` object (if async operation, returns link to operation status).

### Move Resource
**Description:** Move a file or folder.
**Method:** `POST`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/move`
**Input Parameters:**
*   `from` (required): Source path.
*   `path` (required): Destination path.
*   `overwrite`: `true`/`false`.
*   `fields`: Response fields.
**Output:** `Link` object (if async operation, returns link to operation status).

### Delete Resource
**Description:** Delete a file or folder.
**Method:** `DELETE`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources`
**Input Parameters:**
*   `path` (required): Path to the resource.
*   `permanently`: `true` (skip trash) / `false` (move to trash, default).
*   `fields`: Response fields.
**Output:** `Link` object (if async) or 204 No Content.

### Publish Resource
**Description:** Publish a resource (make it public).
**Method:** `PUT`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/publish`
**Input Parameters:**
*   `path` (required): Path to the resource.
**Output:** `Link` object containing `href` to meta info.

### Unpublish Resource
**Description:** Revoke public access to a resource.
**Method:** `PUT`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources/unpublish`
**Input Parameters:**
*   `path` (required): Path to the resource.
**Output:** `Link` object.

### Operation Status
**Description:** Check the status of an async operation.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/operations/{operation_id}`
**Output:**
```json
{
  "status": "string (success, failed, in-progress)"
}
```

### App Folder
**Description:** Для доступа к собственной папке можно использовать схему адреса app:/. Например, список ресурсов в своей корневой папке приложение может получить таким запросом
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/resources?path=app:/`
В ответах API пути указываются в схеме disk:/, с абсолютными путями к ресурсам. Например, приложение Foo получает ответ о своем файле photo.png:
```json
{
  "name": "photo.png",
  "created": "2014-04-21T14:57:13+04:00",
  "modified": "2014-04-21T14:57:14+04:00",
  "path": "disk:/Приложения/Foo/photo.png",
  "md5": "4334dc6379c8f95ddf11b8508cfea271",
  "type": "file",
  "mime_type": "application/x-www-form-urlencoded",
  "size": 34567
}
```

## 6. Trash

### Get Trash Contents
**Description:** Get meta information for files in Trash.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/trash/resources`
**Input Parameters:**
*   `path`: Path relative to Trash root.
*   `limit`, `offset`, `sort`, `preview_size`, `preview_crop`.
**Output:** `Resource` object (with `origin_path` field).

### Restore from Trash
**Description:** Restore a file or folder from Trash.
**Method:** `PUT`
**URL:** `https://cloud-api.yandex.net/v1/disk/trash/resources/restore`
**Input Parameters:**
*   `path` (required): Path in Trash.
*   `name`: New name (optional).
*   `overwrite`: `true`/`false`.
**Output:** `Link` object.

### Empty Trash
**Description:** Empty the Trash or delete a specific resource from it.
**Method:** `DELETE`
**URL:** `https://cloud-api.yandex.net/v1/disk/trash/resources`
**Input Parameters:**
*   `path`: Path to resource to delete. If omitted, empties entire Trash.
**Output:** `Link` object (if async) or 204 No Content.

## 7. Public Resources

### Get Public Resource Meta
**Description:** Get meta information for a public resource.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/public/resources`
**Input Parameters:**
*   `public_key` (required): Public key or URL.
*   `path`: Relative path within public folder.
*   `sort`, `limit`, `offset`, `preview_size`, `preview_crop`.
**Output:** `Resource` object.

### Get Public Download Link
**Description:** Get a download link for a public resource.
**Method:** `GET`
**URL:** `https://cloud-api.yandex.net/v1/disk/public/resources/download`
**Input Parameters:**
*   `public_key` (required): Public key or URL.
*   `path`: Relative path to file.
**Output:** `Link` object with download URL.

### Save Public Resource to Disk
**Description:** Save a public resource to the user's "Downloads" folder.
**Method:** `POST`
**URL:** `https://cloud-api.yandex.net/v1/disk/public/resources/save-to-disk`
**Input Parameters:**
*   `public_key` (required): Public key or URL.
*   `path`: Relative path within public folder.
*   `name`: Name to save as.
**Output:** `Link` object (if async operation, returns link to operation status).