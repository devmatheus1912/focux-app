# Focux Personal — App

> Cliente Flutter (mobile e web) para personal trainers e alunos operarem treino, alunos, financeiro, agenda, IA, comunicacao e crescimento em um unico produto multi-tenant.

## Visao geral

Duas experiencias no mesmo app, conectadas ao `focux-backend`:

| Perfil | Foco |
|---|---|
| **Personal** | Command Center, alunos, treinos, biblioteca, agenda, financeiro, IA, CRM, marca e planos |
| **Aluno** | Treinos, check-in, evolucao, saude, chat, feed, pagamentos e notificacoes |

Autenticacao JWT, rotas por perfil (GoRouter) e design system **Tokens Strip / Liquid Glass** — referencia visual: Home Personal (`/dashboard/personal`).

## Snapshot (ago/2026)

| | |
|---|---|
| Versao | `1.2.0+3` |
| Flutter / Dart | SDK `^3.7` |
| Branch | `main` |
| Site | [focuxpersonal.com](https://focuxpersonal.com) |
| Testes | ~970 casos em `test/` |
| iOS | ver `TESTFLIGHT.md` |

## Ecossistema

| Repositorio | Papel |
|---|---|
| `focux-app` | Este app |
| `focux-backend` | API REST, WebSocket e regras de negocio |
| `focux-website` | Site oficial, legal e superficies publicas |

## Stack

Flutter · Riverpod · GoRouter · Dio · Secure Storage · STOMP/WebSocket · Firebase (FCM, Crashlytics) · Google Sign-In · IAP · Health Connect / Apple Health · ML Kit · Rive · Material 3

## Estrutura

```text
lib/
├── core/          # api, auth, router, theme, widgets, security
├── features/      # dominios (dashboard, alunos, treinos, ia, …)
└── l10n/          # pt, en, es
android/ · ios/ · web/ · test/ · integration_test/ · e2e/
```

Hubs principais consomem BFF `GET …/home` (first paint em um request). Detalhe de rotas: `lib/core/router/`.

## Escopo funcional (resumo)

**Personal** — Command Center e Focux Score · Aluno 360 · treinos e biblioteca · IA copiloto · financeiro e PIX · agenda · chat, feed e broadcasts · leads, landing e identidade visual · alertas, analytics e planos.

**Aluno** — dashboard · execucao de treino · evolucao e fotos · saude/recovery · chat e feed · financeiro · IA e gamificacao.

## Desenvolvimento

### Pre-requisitos

Flutter SDK · Android Studio ou Xcode · emulador ou Chrome · backend local ou remoto

### Setup

```bash
flutter pub get
cp android/gradle.properties.example android/gradle.properties   # se necessario
```

Configuracao via `--dart-define` (ver `lib/core/config/env.dart`). Modelo local: `.env.local.example` → `.env.local` (gitignored). Scripts de release em `tools/release/` (config interna).

### Rodar

```bash
# Android (emulador → host)
flutter run -d emulator-5554 \
  --dart-define=API_URL=http://10.0.2.2:8080 \
  --dart-define=PUBLIC_WEB_URL=http://10.0.2.2:8080

# Web
flutter run -d chrome --web-port 61791 \
  --dart-define=API_URL=http://localhost:8080 \
  --dart-define=PUBLIC_WEB_URL=http://localhost:61791
```

PowerShell: use `` ` `` no lugar de `\` para continuar linha.

### Build

```bash
flutter build apk --release \
  --dart-define=API_URL=https://SEU_BACKEND \
  --dart-define=PUBLIC_WEB_URL=https://focuxpersonal.com

flutter build appbundle --release
flutter build web --release
```

Preferir `tools/release/build-android.sh` e `build-ios.sh` para builds oficiais de loja.

### Qualidade

```bash
dart analyze --fatal-warnings --fatal-infos
flutter test
flutter test integration_test
```

E2E web: `cd e2e && npm install && npx playwright test`

CI (minutos enxutos): PR = analyze + orphan + gitleaks + semgrep. Push main = + unit tests + E2E Playwright. CodeQL só semanal/manual. Ver `.github/workflows/`.

### i18n

Fontes: `lib/l10n/app_{pt,en,es}.arb` · gerar: `flutter gen-l10n`

## Seguranca e conformidade

Postura defensiva: auth centralizada, HTTPS, dados minimos na UI, tenant isolado no backend.

| Area | Postura |
|---|---|
| Sessao | JWT com refresh; logout limpa cliente e servidor |
| Dados | Tokens so em storage seguro no mobile |
| Release | Politica de hardening nos builds de loja |
| Privacidade | LGPD e PII tratados no backend |
| IA | Disclaimer de supervisao profissional |

Erros nunca expoem detalhes tecnicos ao usuario. CI inclui analise estatica e varredura de secrets.

**Nao versionar:** credenciais, keystores, `google-services.json` real, configs locais sensiveis — use arquivos `.example`.

## Roadmap

Release mobile em producao · IAP completo · E2E nas rotas criticas · habitos e enterprise · health/wearables e pose coach

## Licenca

Projeto privado/proprietario. Uso, distribuicao e copia dependem de autorizacao do proprietario.
