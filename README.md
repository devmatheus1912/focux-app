# Focux Personal — App

Cliente Flutter (Android, iOS e web) para personal trainers e alunos operarem treino, alunos, financeiro, agenda, IA e crescimento em um produto multi-tenant.

> **Repositório público.** Não versionar secrets, keystores, Firebase real nem `.env`. Use só arquivos `*.example` com placeholders.

## Visão geral

Duas experiências no mesmo app, conectadas à API (`focux-backend`):

| Perfil | Foco |
|---|---|
| **Personal** | Command Center, alunos, treinos, biblioteca, agenda, financeiro, IA, CRM, marca e planos |
| **Aluno** | Treinos, check-in, evolução, saúde, chat, feed, pagamentos e notificações |

Autenticação JWT, rotas por perfil (GoRouter) e design system próprio (Tokens Strip / Liquid Glass).

## Snapshot

| | |
|---|---|
| Versão | `1.2.1+67` (ver `pubspec.yaml`) |
| Flutter / Dart | SDK `^3.7` |
| Branch | `main` |
| Site | [focuxpersonal.com](https://focuxpersonal.com) |

## Ecossistema

| Repositório | Papel |
|---|---|
| `focux-app` | Este app |
| `focux-backend` | API REST, WebSocket e regras de negócio |
| `focux-website` | Site oficial e superfícies públicas |

## Stack

Flutter · Riverpod · GoRouter · Dio · Secure Storage · STOMP/WebSocket · Firebase (FCM, Crashlytics) · Google Sign-In · IAP · Health Connect / Apple Health · ML Kit · Rive · Material 3

## Estrutura

```text
lib/
├── core/          # api, auth, router, theme, widgets, security
├── features/      # domínios (dashboard, alunos, treinos, ia, …)
└── l10n/          # pt, en, es
android/ · ios/ · web/ · test/ · integration_test/ · e2e/
```

Hubs principais usam BFF `GET …/home` (first paint em um request). Rotas: `lib/core/router/`.

## Escopo funcional (resumo)

**Personal** — Command Center e Focux Score · Aluno 360 · treinos e biblioteca · IA copiloto · financeiro e PIX · agenda · chat, feed e broadcasts · leads, landing e identidade visual · alertas, analytics e planos.

**Aluno** — dashboard · execução de treino · evolução e fotos · saúde/recovery · chat e feed · financeiro · IA e gamificação.

## Desenvolvimento

### Pré-requisitos

Flutter SDK · Android Studio ou Xcode · emulador ou Chrome · backend local ou remoto

### Setup

```bash
flutter pub get
cp .env.local.example .env.local
# Edite .env.local com placeholders locais (nunca commite este arquivo)

cp android/gradle.properties.example android/gradle.properties   # se necessário
cp android/key.properties.example android/key.properties         # só para release local
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
```

Configuração de runtime via `--dart-define` (ver `lib/core/config/env.dart`).  
Modelos seguros: `.env.local.example`, `android/key.properties.example`, `*.google-services*.example`.

### Rodar (local)

```bash
# Android (emulador → host da máquina)
flutter run -d emulator-5554 \
  --dart-define=API_URL=http://10.0.2.2:8080 \
  --dart-define=PUBLIC_WEB_URL=http://10.0.2.2:8080

# Web
flutter run -d chrome --web-port 61791 \
  --dart-define=API_URL=http://localhost:8080 \
  --dart-define=PUBLIC_WEB_URL=http://localhost:61791
```

No PowerShell, use `` ` `` no lugar de `\` para continuar a linha.

### Build

```bash
flutter build apk --release \
  --dart-define=API_URL=https://your-backend.example.com \
  --dart-define=PUBLIC_WEB_URL=https://your-frontend.example.com

flutter build appbundle --release
flutter build web --release
```

Use URLs e credenciais do **seu** ambiente. Não cole tokens reais no README nem no código.

### Qualidade

```bash
dart analyze --fatal-warnings --fatal-infos
flutter test
```

E2E web (opcional): `cd e2e && npm install && npx playwright test`  
CI: analyze, testes e varredura de secrets — ver `.github/workflows/`.

### i18n

Fontes: `lib/l10n/app_{pt,en,es}.arb` · gerar: `flutter gen-l10n`

## Segurança (repo público)

| Área | Postura |
|---|---|
| Sessão | JWT com refresh; logout limpa cliente e servidor |
| Dados no device | Tokens em storage seguro no mobile |
| Release | Hardening nos builds de loja |
| Privacidade | LGPD e PII tratados no backend |
| CI | Secrets só via GitHub Actions `secrets.*` |
| Firebase client | `google-services.json` / `GoogleService-Info.plist` **fora do git**; só `*.example` |

**Nunca versionar**

- `.env`, `.env.local`, `e2e/.env`
- `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.pem`
- `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` **reais**
- service accounts, dumps de banco, senhas, PII de QA

### Alert GitHub: Google API Key em `google-services.json`

O arquivo real já está no `.gitignore` e **não** deve voltar ao índice. Helper local (SHA-1 + validação + base64):

```powershell
powershell -File tools/rotate_firebase_android_api_key.ps1
# depois de baixar o JSON novo:
powershell -File tools/rotate_firebase_android_api_key.ps1 -ExpectKeyPrefix AIzaSyDN -EncodeForCi
```

Checklist manual (Console Google / GitHub):

1. [Credentials](https://console.cloud.google.com/apis/credentials) no mesmo Project ID do Firebase → **Create credentials → API key** (não regenere a antiga ainda).
2. Edite a key nova → Application restrictions = **Android apps**, package `com.focux.focux_app` + cada SHA-1 (debug, release, Play App Signing). API restrictions = só APIs Firebase (sem Gemini/Maps). **Save**.
3. Firebase Console → Project settings → app Android → **Download `google-services.json`** → salve em `android/app/google-services.json` (só local). Confirme que `current_key` mudou.
4. Apague (ou regenere) a **key antiga** vazada. Só então feche o alerta do GitHub como **revoked**.
5. Gate: `flutter test test/core/security/firebase_config_secrets_test.dart`.

Erros de UI não devem expor detalhes técnicos internos. Em dúvida: não commitar.

## Licença

Código proprietário. O repositório pode ser público para transparência; uso, distribuição e cópia dependem de autorização do proprietário.
