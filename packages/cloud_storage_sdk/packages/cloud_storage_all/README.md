# cloud_storage_all

Универсальный фасад для популярных облачных дисков (Dropbox, Google Drive,
OneDrive, Yandex.Disk). Предоставляет единый интерфейс `CloudStorageApi` и
адаптеры для каждого провайдера, чтобы упростить типовые операции: листинг
папок, загрузка/скачивание файлов, создание папок, удаление, перемещение и
копирование.

Этот пакет полезен, когда приложение должно работать с несколькими провайдерами
через единый код, не зависящий от специфики API каждого сервиса.

## Возможности

- Единый интерфейс `CloudStorageApi` и модели: `CloudItem`, `CloudRef`, `CloudPage`.
- Адаптеры: `DropboxAdapter`, `GoogleDriveAdapter`, `OneDriveAdapter`, `YandexDriveAdapter`.
- Поддержка потоковой загрузки/скачивания и отслеживания прогресса через
	`OAuth2ProgressCallback` из `oauth2restclient`.
- Согласованная пагинация (`CloudPage.nextToken`).

## Быстрый старт

Добавьте в зависимости рабочей области (в рамках mono-repo уже подключено через `path`).

Пример использования (предполагается, что у вас уже есть авторизованный
клиент провайдера). Можно передавать как готовый API (например `DropboxApi`),
так и только `OAuth2RestClient` через удобные фабрики `*Client(...)`:

```dart
import 'package:cloud_storage_all/cloud_storage_all.dart';
import 'package:dropbox_api/dropbox_api.dart' as dropbox;

void example(dropbox.DropboxApi dropboxApi) async {
	final storage = CloudStorage.dropbox(dropboxApi);

	// Список элементов в папке
	final page = await storage.api.listChildren(CloudPath('/Documents'));
	for (final item in page.items) {
		print('${item.name}  folder=${item.isFolder}  ref=${item.ref}');
	}

	// Загрузка файла (получаем поток байтов)
	final stream = await storage.api.download(CloudPath('/Documents/file.txt'));
	await for (final chunk in stream) {
		// записываем в локальный файл или обрабатываем
	}

	// Загрузка файла на диск
	final fileStream = Stream.fromIterable([[1,2,3]]);
	final uploaded = await storage.api.upload(
		CloudPath('/Documents'),
		'hello.txt',
		fileStream,
		contentLength: 3,
	);

	// Создать папку
	await storage.api.createFolder(CloudPath('/Documents'), 'new-folder');

	// Удалить
	await storage.api.delete(CloudPath('/Documents/old.txt'));
}

void example2(OAuth2RestClient client) async {
	// Создаст DropboxRestApi(client) внутри
	final storage = CloudStorage.dropboxClient(client);
	await storage.api.listChildren(CloudPath('/'));
}
```

### Примечания по провайдерам

- Google Drive использует идентификаторы (`CloudId`) для обращений к файлам и
	папкам. При вызове `upload` для Google необходимо передавать `contentLength`.
- Dropbox/OneDrive/Yandex — преимущественно работают с путями (`CloudPath`).
- Адаптеры конвертируют нативные модели провайдеров в `CloudItem`.

## Детали API

- `CloudRef` — абстракция ссылки на объект в облаке: `CloudPath` (путь) или
	`CloudId` (идентификатор).
- `CloudItem` — информация об элементе (имя, папка/файл, размер, даты).
- `CloudPage<T>` — список элементов с `nextToken` для последующей пагинации.

Если требуется доступ к специфичным методам провайдера (например, публикация
ресурса в Yandex.Disk), используйте нативный клиент напрямую — он экспортируется
из пакета (`package:yandex_drive_api/yandex_drive_api.dart` и т.д.).

## Примеры

Пример изменения имени при копировании (Google Drive требует дополнительных
запросов, пример в адаптере):

```dart
// copy + переименование
await storage.api.copy(fromRef, toFolderRef, newName: 'new-name.ext');
```

## Вклад и тесты

PR и issue приветствуются. Запустите анализатор и тесты в корне mono-repo:

```bash
melos bootstrap
melos run analyze
melos test
```

## Лицензия

Этот пакет распространяется под лицензией проекта (см. корневой `LICENSE`).

---
Если хотите, могу добавить мини-пример в `example/` и тесты, показывающие
основные операции через каждый адаптер.
