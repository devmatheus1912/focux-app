# Scripts — Focux app

Helpers to run/build Flutter with Google Sign-In + backend env in one command.

## Setup (1x só)

```powershell
cd "D:\Projetos\Focux Personal\focux-app"
Copy-Item .env.local.example .env.local
# editar .env.local com GOOGLE_WEB_CLIENT_ID real
```

## Scripts

### `get-sha1.ps1`
Extrai SHA-1 do debug keystore Android. Necessário pra cadastrar no Firebase
e habilitar Google Sign-In no APK debug.

```powershell
.\scripts\get-sha1.ps1
```

Cola SHA-1 em https://console.firebase.google.com/project/focux-personal/settings/general
→ app Android → Add fingerprint → Save → re-baixa `google-services.json`.

### `run-android.ps1`
Roda app no emulador Pixel 8 (`emulator-5554`) com `--dart-define`.

```powershell
.\scripts\run-android.ps1
```

### `run-web.ps1`
Roda app no Chrome em `http://localhost:61791`.

```powershell
.\scripts\run-web.ps1
```

### `build-android.ps1`
Build APK release.

```powershell
.\scripts\build-android.ps1
# saída: build/app/outputs/flutter-apk/app-release.apk
```

### `build-web.ps1`
Build web release.

```powershell
.\scripts\build-web.ps1
# saída: build/web/
```

## Variáveis suportadas em `.env.local`

| Var | Default | Onde usa |
|---|---|---|
| `GOOGLE_WEB_CLIENT_ID` | obrigatório | Sign-In Google (FE + BE validation) |
| `API_URL` | Railway prod | Backend HTTP base |
| `WEB_PORT` | `61791` | Porta `flutter run -d chrome` |

## Não commitar

`.env.local` está no `.gitignore` raiz. Nunca commitar credenciais.
