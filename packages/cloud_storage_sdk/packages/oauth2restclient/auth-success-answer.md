# Auth success answer

## Dropbox

### Обмен кода на токен (ответ успешный)

```json
{
	"access_token": "sl.BCj...Yg",
	"token_type": "bearer",
	"expires_in": 14400,
	"scope": "files.metadata.read files.content.write",
	"account_id": "dbid:AAC...5g",
	"team_id": "dbtid:AAH...1Q",
	"refresh_token": "sl.r...Q",
	"id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
	"uid": "123456789"
}
```

### Получения информации об аккаунте (ответ успешный)

https://api.dropboxapi.com/2/users/get_current_account

```json
{
   "account_id":"dbid:AACAtcC_rW7VGRffdfdrlX2O6gqRdSiJTUCqbRSE",
   "name":{
      "given_name":"Кирилл",
      "surname": "",
      "familiar_name":"Кирилл",
      "display_name":"Кирилл",
      "abbreviated_name":"К"
   },
   "email":"mieerrvm@gmail.com",
   "email_verified":true,
   "disabled":false,
   "country":"FI",
   "locale":"ru",
   "referral_link":"https://www.dropbox.com/referrals/AAB4R1PirdD3Il4LcSQ7lFohBIvNoKEH0w8?src=app9-7685185",
   "is_paired":false,
   "account_type":{
      ".tag":"basic"
   },
   "root_info":{
      ".tag":"user",
      "root_namespace_id":12983435521,
      "home_namespace_id":12983435521
   }
}
```

## Microsoft (OneDrive)

### Обмен кода на токен (ответ успешный)

```json
{
  "token_type":"bearer",
  "expires_in": 3600,
  "scope":"wl.basic onedrive.readwrite",
  "access_token":"EwCo...AA==",
  "refresh_token":"eyJh...9323"
}
```

### Получения информации об аккаунте (ответ успешный)

https://graph.microsoft.com/v1.0/me

```json
{
    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users/$entity",
    "businessPhones": [],
    "displayName": "Adele Vance",
    "givenName": "Adele",
    "jobTitle": null,
    "mail": "AdeleV@M365x63639251.OnMicrosoft.com",
    "mobilePhone": null,
    "officeLocation": null,
    "preferredLanguage": null,
    "surname": "Vance",
    "userPrincipalName": "AdeleV@M365x63639251.OnMicrosoft.com",
    "id": "3a2bc284-f11c-4676-a9e1-6310eea60f26"
}
```

## Google

### Обмен кода на токен (ответ успешный)

```json
{
  "access_token": "ya29.a0AfH6SM...Q",
  "expires_in": 3599,
  "refresh_token": "1//0gL...Y",
  "scope": "https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/photoslibrary openid",
  "token_type": "Bearer",
  "id_token": "eyJhbGciOi",
  "refresh_token_expires_in": 604799
}
```

### Получения информации об аккаунте (ответ успешный)

https://www.googleapis.com/oauth2/v3/userinfo

```json
{
   "sub":112522847156150765666,
   "picture":"https://lh3.googleusercontent.com/a-/ALV-UjX8_NG6PG45xUiEV3DWHUj6kpvNHvbS2eJm8LJOtEZ4EVXZdQ=s96-c",
   "email":"mieerrvm@gmail.com",
   "email_verified":true
}
```

## Yandex

### Обмен кода на токен (ответ успешный)

```json
{
  "token_type": "bearer",
  "access_token": "gffdsfe-iIpnDxIs",
  "expires_in": 124234123534,
  "refresh_token": "1:GN686QVt0mmakDd9:cddddddddddfrrrrrrt:A-2dHOmBxiXgajnD-kYOwQ",
  "scope": "login:info login:email login:avatar"
}
```

### Получения информации об аккаунте (ответ успешный)

https://login.yandex.ru/info

`with email scope`

```json
{
   "login": "ivan",
   "old_social_login": "uid-mmzxrnry",
   "default_email": "test@yandex.ru",
   "id": "1000034426",
   "client_id": "4760187d81bc4b779dfdfdfgfgb5103713",
   "emails": [
      "test@yandex.ru",
      "other-test@yandex.ru"
   ],
   "psuid": "1.AAceCw.tbHgw5DtJ9_zeqPrk-Ba2w.hghrrrrrgreererre"
}
```