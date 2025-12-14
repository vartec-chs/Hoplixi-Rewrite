# Yandex Drive API Example

Это демонстрационное приложение для пакета `yandex_drive_api`.

## Настройка

1. Убедитесь, что у вас есть `.env` файл с вашими ключами Yandex OAuth:
   ```
   YANDEX_CLIENT_ID=ваш_client_id
   YANDEX_CLIENT_SECRET=ваш_client_secret
   ```

2. Запустите приложение:
   ```bash
   flutter run
   ```

3. Нажмите "Авторизоваться" - откроется браузер для входа в Yandex аккаунт.

4. После авторизации вы сможете:
   - Получить информацию о диске
   - Просмотреть список файлов

## Примечания

- Токен сохраняется в `oauth2_account.json` для повторных запусков.
- Убедитесь, что redirect URI настроен как `http://localhost:8569/callback` в вашем приложении Yandex.