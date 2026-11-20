# Focux Personal · App

> **Quem treinou, quem pagou e quem sumiu.**
> App de gestão para personal trainer: o personal opera a assessoria (alunos, treinos, agenda, cobrança com PIX, IA e marca própria) e o aluno treina, faz check-in e fala com o personal, no mesmo app.

> **Repositório privado.** Código proprietário: cópia, execução em produção, modificação e distribuição **proibidas** sem autorização por escrito. Ver [LICENSE](LICENSE).

---

## Sumário

- [Estado em produção](#estado-em-produção)
- [Visão geral](#visão-geral)
- [Ecossistema](#ecossistema)
- [Stack](#stack)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Primeiros passos](#primeiros-passos)
- [Qualidade e testes](#qualidade-e-testes)
- [CI e release](#ci-e-release)
- [Fluxo de trabalho](#fluxo-de-trabalho)
- [Documentação](#documentação)
- [Marca e design](#marca-e-design)
- [Segurança](#segurança)
- [Licença](#licença)

---

## Estado em produção

*Atualizado em 19/11/2026.*

| | |
|---|---|
| **Status** | Em produção, publicado nas duas lojas |
| **App Store** | [Focux Personal](https://apps.apple.com/br/app/focux-personal/id6807799166) |
| **Google Play** | [Focux Personal](https://play.google.com/store/apps/details?id=com.focux.focux_app&hl=pt_BR) |
| **Versão** | `1.2.5+241` (fonte da verdade: `pubspec.yaml`) |
| **Plataformas** | iOS e Android. O target web é compilado para os testes E2E |
| **Idioma** | Somente português do Brasil |
| **Assinaturas** | Free, Pro e Enterprise, pela App Store e pelo Google Play (compra no app) |
| **Site** | [focuxpersonal.com](https://focuxpersonal.com) |
| **Branch de produção** | `main` |

---

## Visão geral

Dois perfis no mesmo app, com rotas separadas por papel:

| Perfil | O que faz no app |
|---|---|
| **Personal** | Tela Hoje (o que pede ação), alunos e Aluno 360, fichas e biblioteca de exercícios, agenda, financeiro com PIX, IA Focux, captação, relatórios e marca própria |
| **Aluno** | Treino do dia com vídeo, check-in com carga e RPE (funciona sem rede), evolução, saúde (Apple Health / Health Connect), chat e notificações |

**Marca própria (Enterprise):** o personal aplica logo, paleta e um de três estilos (Clássico, Minimalista, Cinematográfico) dentro do app do aluno. Não existe app separado nas lojas.

---

## Ecossistema

| Repositório | Visibilidade | Papel |
|---|---|---|
| **`focux-app`** | Privado | Este cliente Flutter |
| `focux-backend` | Privado | API REST, WebSocket e regras de negócio |
| `focux-website` | Privado | Site institucional [focuxpersonal.com](https://focuxpersonal.com) |

Não documente aqui infraestrutura, URLs internas, credenciais ou detalhes do backend privado.

---

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter (SDK `>=3.47`, Dart `^3.7.2`) |
| Estado | Riverpod |
| Navegação | GoRouter (catálogo de rotas em `lib/core/router/`) |
| Rede | Dio, STOMP (tempo real) |
| Autenticação | JWT, secure storage, Google Sign-In, Sign in with Apple |
| Notificações e erros | Firebase (FCM, Crashlytics), Sentry |
| Compras | In-App Purchase (StoreKit e Google Play Billing) |
| Saúde | `health` (Apple Health / Health Connect) |
| Design system | Tokens próprios em `lib/core/theme/`, tipografia Inter, ícones Phosphor (`FxIcons`) |
| Idioma | l10n, só PT-BR |

---

## Estrutura do repositório

```text
lib/
  core/           # infraestrutura compartilhada: api, auth, router, theme, design system, storage…
  features/       # um diretório por domínio (alunos, treinos, checkin, financeiro, ia, agenda…)
  l10n/           # textos (PT-BR)
  main.dart
test/             # testes unitários e de widget
integration_test/ # testes de integração
e2e/              # suíte Playwright sobre o build web (ver e2e/README.md)
brand/            # guia de marca e kit do logo (ver Marca e design)
docs/             # arquitetura, design system, produto e release
assets/           # fontes, imagens e sons empacotados
android/ ios/ web/
tool/             # verificação local, scripts de release e utilitários
```

---

## Primeiros passos

### Pré-requisitos

- Flutter SDK compatível com `pubspec.yaml`
- Xcode (iOS) e/ou Android Studio (Android)
- Backend acessível **no seu** ambiente autorizado

### Configuração

```bash
flutter pub get
cp .env.local.example .env.local                      # edite localmente, nunca commite

cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
cp android/gradle.properties.example android/gradle.properties   # se necessário
cp android/key.properties.example android/key.properties         # só para release local
```

As chaves de runtime ficam em `lib/core/config/env.dart` e nos arquivos `*.example` versionados.

### Rodar

```bash
flutter run \
  --dart-define=API_URL=https://your-backend.example.com \
  --dart-define=PUBLIC_WEB_URL=https://your-frontend.example.com
```

Use **sempre** placeholders ou hosts do seu ambiente de desenvolvimento. Nunca cole tokens, chaves de API ou senhas em issues, PRs ou neste README.

---

## Qualidade e testes

```bash
dart analyze --fatal-warnings --fatal-infos   # análise estática sem tolerância
flutter test                                   # unitários e de widget
flutter test integration_test                  # integração
```

E2E (Playwright sobre o build web): instruções em [`e2e/README.md`](e2e/README.md).

---

## CI e release

| Workflow | Quando roda | O que faz |
|---|---|---|
| `analyze.yml` | push, PR | `dart analyze` sem tolerância a avisos e busca de arquivos Dart órfãos |
| `e2e.yml` | push | Build web e suíte Playwright no Chrome |
| `security.yml` | push, PR | Varredura de secrets (gitleaks) |
| `semgrep.yml` | push, PR | Análise estática de segurança (Semgrep) |
| `codeql.yml` | agendado | CodeQL sobre o JavaScript da suíte E2E |
| `ios-release.yml` | manual ou tag `v*` | Build do IPA em macOS e envio opcional ao TestFlight, com símbolos para o Sentry |

Os testes (`flutter test`) não rodam no CI hoje: rode localmente antes do merge.

**Release:** a versão sobe em `pubspec.yaml`. O iOS sai pelo `ios-release.yml` a partir da `main` e o Android, pelo app bundle assinado enviado ao Google Play. Passo a passo em [`docs/RELEASE.md`](docs/RELEASE.md).

---

## Fluxo de trabalho

1. Todo trabalho entra na `develop`, onde o CI roda.
2. No lançamento, a `develop` é mesclada na `main`, que guarda só o que está nas lojas.
3. Bug em produção: `hotfix/<nome>` a partir da `main`, de volta na `main` e na `develop`.

Detalhes, checklist e padrão de commit em [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/PRODUTO.md`](docs/PRODUTO.md) | O que é o produto, para quem, planos e princípios |
| [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) | Estrutura, navegação, dados, privacidade e testes de contrato |
| [`docs/DESIGN-SYSTEM.md`](docs/DESIGN-SYSTEM.md) | Tipografia, ícones, cor e componentes do app |
| [`docs/RELEASE.md`](docs/RELEASE.md) | Versão, TestFlight, Google Play e hotfix |
| [`brand/brand_guidelines.md`](brand/brand_guidelines.md) | Guia de marca |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Branches, checklist e padrão de commit |
| [`SECURITY.md`](SECURITY.md) | Como relatar vulnerabilidade e o que nunca entra no Git |
| [`CHANGELOG.md`](CHANGELOG.md) | O que mudou em cada versão |
| [`e2e/README.md`](e2e/README.md) | Testes E2E |

---

## Marca e design

| | |
|---|---|
| Guia de marca | [`brand/brand_guidelines.md`](brand/brand_guidelines.md) · versão visual em [`brand/brand_guidelines.html`](brand/brand_guidelines.html) |
| Design system do app | [`docs/DESIGN-SYSTEM.md`](docs/DESIGN-SYSTEM.md) |
| Kit do logo v2 | [`brand/kit/`](brand/kit/): SVG e PNG (empilhado, horizontal, símbolo, ícones de iOS e Android, notificação, favicon) |

**Marca no app:** logo v2 e fundo sólido (paper `#F4F6F8` no claro, chão `#0A1A1F` no escuro) desde 20/11/2026. O logo anterior saiu do repositório (está no histórico do Git).

---

## Segurança

**Nunca versionar:** `.env*` · keystores (`*.jks`, `*.keystore`, `*.p12`, `*.pem`) · `key.properties` · `google-services.json` e `GoogleService-Info.plist` reais · service accounts · `e2e/.auth/` · dumps e capturas de QA com dados pessoais · chaves Apple (`AuthKey_*.p8`, perfis de provisionamento).

Secret encontrado no histórico: trate como comprometido, revogue no provedor e avise o mantenedor. Não faça force-push sem alinhamento.

**Vulnerabilidades:** não abra issue. Relato privado para **contato@focuxpersonal.com**, conforme a [política de segurança](SECURITY.md).

---

## Licença

[LICENSE](LICENSE) · MATHEUS OLIVEIRA DOS SANTOS DESENVOLVIMENTO DE SOFTWARE LTDA. Todos os direitos reservados.
