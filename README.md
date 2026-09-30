# Focux Personal — App

Cliente Flutter (Android, iOS e web) para personal trainers e alunos. Conecta-se à API do repositório **privado** `focux-backend`.

> **Repositório público no GitHub ≠ software livre.** Código proprietário: consulta permitida; cópia, execução em produção, modificação e distribuição **proibidas** sem autorização por escrito. Ver [LICENSE](LICENSE).

## Perfis

| Perfil | Uso |
|--------|-----|
| **Personal** | Operação do negócio, alunos, treinos, agenda, financeiro, IA e crescimento |
| **Aluno** | Treinos, check-in, evolução, saúde, chat e notificações |

Autenticação JWT, rotas por papel (GoRouter) e design system próprio. Catálogo de rotas (fonte da verdade): `lib/core/router/` — não duplicar inventário aqui.

## Estado do projeto

| | |
|---|---|
| Versão / build | Ver `pubspec.yaml` (fonte da verdade) |
| Branch principal | `main` |
| Site | [focuxpersonal.com](https://focuxpersonal.com) |
| Estágio | Pré-produção / App Store em preparação |

## Ecossistema

| Repositório | Visibilidade | Papel |
|-------------|--------------|--------|
| `focux-app` | Público | Este cliente |
| `focux-backend` | **Privado** | API REST, WebSocket e regras de negócio |
| Site | Externo | [focuxpersonal.com](https://focuxpersonal.com) |

Não documente aqui infra, URLs internas, credenciais ou detalhes do backend privado.

## Stack (resumo)

Flutter · Riverpod · GoRouter · Dio · secure storage · STOMP · Firebase (FCM/Crashlytics) · IAP · Health · l10n (só PT-BR)

## Desenvolvimento local

### Pré-requisitos

Flutter SDK (compatível com `pubspec.yaml`) · Android Studio ou Xcode · backend acessível só no **seu** ambiente autorizado

### Setup

```bash
flutter pub get
cp .env.local.example .env.local
# Edite .env.local localmente — nunca commite

cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
cp android/gradle.properties.example android/gradle.properties   # se necessário
cp android/key.properties.example android/key.properties         # só release local
```

Templates e chaves de runtime: `lib/core/config/env.dart` e arquivos `*.example` versionados.

### Rodar

```bash
flutter run \
  --dart-define=API_URL=https://your-backend.example.com \
  --dart-define=PUBLIC_WEB_URL=https://your-frontend.example.com
```

Use **sempre** placeholders ou hosts do seu ambiente de dev. Nunca cole tokens, API keys ou senhas reais em issues, PRs ou README.

### Qualidade

```bash
dart analyze --fatal-warnings --fatal-infos
flutter test
```

CI (`.github/workflows/`): analyze, testes e varredura de secrets (gitleaks).

## Segurança — nunca versionar

`.env*` · keystores (`*.jks`, `*.keystore`, `*.p12`, `*.pem`) · `key.properties` · `google-services.json` / `GoogleService-Info.plist` reais · service accounts · `e2e/.auth/` · dumps e screenshots de QA com PII · chaves Apple (`AuthKey_*.p8`, perfis de provisionamento)

Se encontrar secret no histórico: trate como comprometido, revogue no provedor e avise o mantenedor — não force-push sem alinhamento.

**Vulnerabilidades:** não abra issue pública. E-mail: **contato@focuxpersonal.com** (relato responsável).

## Licença

[LICENSE](LICENSE) — MATHEUS OLIVEIRA DOS SANTOS DESENVOLVIMENTO DE SOFTWARE LTDA. Todos os direitos reservados.
