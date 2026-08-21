# Focux Personal - App Flutter

> App mobile/web do Focux Personal: a interface do personal trainer e do aluno para operar treinos, alunos, financeiro, agenda, IA, comunicacao, recovery, crescimento e marca pessoal.

## Visao geral

O Focux Personal e o sistema operacional do personal trainer moderno. O app Flutter entrega duas experiencias no mesmo produto:

- **Personal Trainer**: cockpit operacional para gerir alunos, treinos, biblioteca, agenda, financeiro, IA, chat, feed, CRM, relatorios, identidade visual, planos e growth.
- **Aluno**: aplicativo de acompanhamento para executar treinos, fazer check-in, conversar com o personal, consumir conteudo, acompanhar evolucao, sincronizar saude, pagar mensalidades e receber notificacoes.

O app se conecta ao `focux-backend`, usa JWT para sessao, aplica rotas por perfil e consome a mesma API multi-tenant que isola cada personal e seus alunos.

## Estado atual (ago/2026)

| Item | Valor |
|---|---|
| Versao | `1.2.0+3` |
| Flutter / Dart | SDK `^3.7` |
| Branch | `main` |
| API | Backend Focux (Railway) — URL configuravel no app |
| Site legal/marketing | [focuxpersonal.com](https://focuxpersonal.com) |
| Testes | suite em `test/` (~350 arquivos / ~970 casos) |
| Padrao visual | Home Personal como referencia 10/10 |

### Destaques recentes

- **Home / Command Center** como fonte da verdade visual e de UX (modo foco, next-actions, quiet chrome, sticky).
- **Hubs com BFF `/home`**: first paint em um GET (agenda, alunos, financeiro, perfil, IA, leads, chat, habitos, loja, paywall, picker de treino, etc.).
- **Aluno Home SSOT** + **Aluno 360** (Operacao, Evolucao, Ferramentas) alinhados ao padrao Home.
- **Perfil** elevado ao padrao Home: strip header, sticky Hoje, Operacao/Conta quiet colapsaveis, freshness e telemetria.
- **FeatureGate** reusa cache da Home (sem GET extra de `/planos/me` no caminho quente).
- **Sessao**: logout limpa tokens, caches locais e leftovers de entitlement; web nao persiste JWT em storage persistente.
- **TLS**: builds de loja exigem certificate pinning da API (Dio + WebSocket/STOMP).
- **Seguranca automatizada**: catalogo `FocuxSecurity` (`lib/core/security/focux_security.dart`) + testes de contrato nos hubs e hardening Android (`test/core/security/`).
- **Design system**: tokens Strip / Liquid Glass em `lib/core/theme` (+ docs de produto quando presentes no repo).
- **Repo enxuto**: `scripts/`, `android/gradle.properties` e l10n gerados sao locais (gitignored); use os `.example`.

### Areas em evolucao

- IAP com contas pagas App Store / Play (verify + notificacoes de lifecycle);
- NFS-e real em producao (fora do escopo atual de loja);
- E2E / smoke de rotas criticas;
- iOS apos base Android consolidada;
- habitos, recorrencia e ofertas enterprise;
- health/recovery e pose coach.

## Stack

| Area | Tecnologia |
|---|---|
| Framework | Flutter |
| Linguagem | Dart |
| Estado | Flutter Riverpod + Provider onde necessario |
| Rotas | GoRouter com shells separados para Personal e Aluno |
| HTTP | Dio |
| Storage seguro | `flutter_secure_storage` |
| Cache local | `shared_preferences` + cache/offline sync proprio |
| Realtime | STOMP over WebSocket |
| Push | Firebase Messaging |
| Crash | Firebase Crashlytics |
| Auth social | Google Sign-In |
| Purchases | In-app purchase |
| Midia | Image Picker, Video Player, Just Audio, Camera |
| IA/Texto | Flutter Markdown |
| PDF | `pdf` + `printing` |
| Graficos | `fl_chart` |
| Animacoes | Flutter Animate + Rive |
| Saude | Apple Health / Google Fit via `health` |
| Widgets nativos | `home_widget` |
| ML/Camera | Google ML Kit Pose Detection |
| Design | Material 3 + Focux Design System |

## Identidade visual

O app usa uma linguagem visual premium chamada internamente de **Tokens Strip / Liquid Glass**.

### Paleta Focux

| Token | Hex |
|---|---|
| Brand | `#13C2C2` |
| Brand default | `#18B5B5` |
| Secondary default | `#007D8A` |
| Brand ink / hover | `#0D9494` |
| Brand soft | `#D9F2F2` |
| Brand softer | `#EDF8F8` |
| Brand deep | `#0A2E2E` |
| Brand glow | `#4DD0E1` |
| Light paper | `#F4F6F8` |
| Light card | `#FFFFFF` |
| Light text | `#1A1A2E` |
| Muted text | `#6B7280` |
| Border | `#E5E7EB` |
| Dark background | `#0B0E14` |
| Dark surface | `#121820` |
| Dark elevated | `#1A2330` |
| Dark line | `#1E2830` |
| Dark text | `#E8EDF2` |
| Dark muted | `#7A8A96` |
| Success | `#1B8C54` |
| Warning | `#B5760A` |
| Error / risk | `#C73A3A` |
| Gold premium | `#E5B84C` |

### Tipografia

- **Outfit** para titulos, UI e corpo.
- **JetBrains Mono** para numeros, labels tecnicos e microcopy operacional.

### Temas e personalizacao

- Tema claro e escuro.
- Cor primaria dinamica por personal.
- Paletas premium curadas:
  - Focux Original;
  - Midnight Gold;
  - Graphite Copper;
  - Deep Navy Pearl;
  - Forest Sage;
  - Charcoal Platinum;
  - Royal Indigo;
  - Obsidian Amber;
  - Slate Teal;
  - Burgundy Rose.
- White-label/identidade visual com logo, cores, slogan e preview no app.

## Estrutura

```text
lib/
|- main.dart
|- l10n/
|- core/
|  |- analytics/
|  |- animations/
|  |- api/
|  |- auth/
|  |- cache/
|  |- config/
|  |- fcm/
|  |- health/
|  |- providers/
|  |- router/
|  |- screens/
|  |- storage/
|  |- theme/
|  |- utils/
|  |- widgets/
|- features/
|  |- admin/
|  |- agenda/
|  |- alertas/
|  |- alimentar/
|  |- alunos/
|  |- analytics/
|  |- anamnese/
|  |- assinatura/
|  |- auth/
|  |- avaliacao/
|  |- broadcasts/
|  |- busca/
|  |- chat/
|  |- checkin/
|  |- convites/
|  |- dashboard/
|  |- depoimentos/
|  |- evolucao/
|  |- exercicios/
|  |- feed/
|  |- feedback/
|  |- financeiro/
|  |- galeria/
|  |- gamificacao/
|  |- growth/
|  |- health/
|  |- ia/
|  |- leads/
|  |- notificacoes/
|  |- onboarding/
|  |- perfil/
|  |- planos/
|  |- plano_sucesso/
|  |- qa/
|  |- ranking/
|  |- relatorio/
|  |- subscription/
|  |- suporte/
|  |- treinos/
|  |- trilhas/
android/
ios/
web/
assets/
brand/
test/
integration_test/
e2e/
# scripts/ — local only (gitignored; copie de backup ou recrie a partir dos comandos abaixo)
```

## Rotas principais

### Publicas e auth

| Rota | Tela |
|---|---|
| `/` | Splash |
| `/login` | Login |
| `/register` | Cadastro personal |
| `/register/aluno` | Cadastro aluno por slug/convite |
| `/onboarding` | Onboarding |
| `/esqueci-senha` | Solicitar reset |
| `/resetar-senha` | Resetar senha |
| `/aluno/definir-senha` | Definir senha definitiva do aluno |

### Shell do personal

| Rota | Tela |
|---|---|
| `/dashboard/personal` | Dashboard personal |
| `/alunos` | Lista de alunos |
| `/treinos` | Lista de treinos |
| `/agenda` | Agenda |
| `/ia/copiloto` | IA Copiloto |

### Sub-rotas do personal

| Rota | Funcao |
|---|---|
| `/dashboard/qualidade` | Qualidade operacional |
| `/dashboard/command-center/copiloto` | Acoes do copiloto |
| `/alunos/novo` | Novo aluno |
| `/alunos/acoes-massa` | Acoes em massa |
| `/alunos/:id` | Detalhe do aluno |
| `/alunos/:id/editar` | Editar aluno |
| `/alunos/:id/equipamentos` | Equipamentos do aluno |
| `/alunos/:id/relatorio` | Relatorio individual |
| `/alunos/:id/evolucao` | Evolucao |
| `/alunos/:id/plano-sucesso` | Plano de sucesso |
| `/alunos/:id/fotos` | Fotos de evolucao |
| `/alunos/:id/anamnese` | Anamnese |
| `/alunos/:id/alimentar` | Plano alimentar |
| `/alunos/:id/treinos-list` | Treinos do aluno |
| `/alunos/:id/ia/progressao` | Progressao de carga |
| `/alunos/:id/chat` | Chat com aluno |
| `/alunos/:id/feedback-video` | Feedback de video |
| `/alunos/:id/engajamento` | Engajamento |
| `/alunos/:id/evolucao-comparativo` | Comparativo de evolucao |
| `/alunos/:id/trilhas` | Trilhas |
| `/treinos/novo` | Criar treino |
| `/treinos/:id` | Detalhe do treino |
| `/treinos/:id/exercicios/add` | Adicionar exercicio |
| `/treino-presencial/:id` | Modo presencial |
| `/exercicios` | Biblioteca de exercicios |
| `/exercicios/novo` | Novo exercicio |
| `/exercicios/biblioteca-wizard` | Wizard de biblioteca |
| `/exercicios/:id` | Detalhe do exercicio |
| `/financeiro` | Financeiro |
| `/perfil` | Perfil |
| `/perfil/editar` | Editar perfil |
| `/perfil/wallet` | Wallet |
| `/identidade-visual` | Identidade visual |
| `/white-label` | Alias para identidade visual |
| `/setup/identidade` | Setup de identidade |
| `/ia/chat` | Chat IA |
| `/ia/progressao/aceitar` | Aceitar progressao |
| `/chat/inbox` | Inbox |
| `/feed` | Feed do personal |
| `/leads` | Leads |
| `/alertas` | Alertas |
| `/alertas/aluno/:id` | Detalhe do alerta |
| `/alertas/config` | Configurar alertas |
| `/relatorios/global` | Relatorio global |
| `/convites` | Convites |
| `/planos` | Planos |
| `/paywall` | Paywall |
| `/assinatura` | Assinatura |
| `/migracao-magica` | Migracao magica |
| `/promo-enterprise` | Promocao enterprise |
| `/ranking` | Ranking |
| `/suporte` | Suporte |
| `/broadcasts` | Broadcasts |
| `/depoimentos` | Depoimentos do personal |
| `/galeria` | Galeria |
| `/feedback-videos` | Feedback videos |
| `/busca` | Busca global |
| `/analytics` | Analytics |
| `/admin/rbac` | RBAC admin |
| `/gamificacao` | Gamificacao |

### Shell do aluno

| Rota | Tela |
|---|---|
| `/dashboard/aluno` | Dashboard aluno |
| `/checkin/treinos` | Meus treinos |
| `/saude` | Health/recovery |
| `/aluno/perfil` | Perfil aluno |

### Sub-rotas do aluno

| Rota | Tela |
|---|---|
| `/aluno/ativacao` | Ativacao |
| `/notificacoes` | Notificacoes |
| `/checkin/executar` | Executar treino |
| `/checkin/historico` | Historico |
| `/agenda/aluno` | Agenda do aluno |
| `/financeiro/aluno` | Financeiro do aluno |
| `/chat/aluno` | Chat do aluno |
| `/feed/aluno` | Feed do aluno |
| `/ia/aluno` | IA do aluno |
| `/depoimentos-aluno` | Depoimento do aluno |

## Funcionalidades do personal

### Operacao e dashboard

- Dashboard do personal.
- Command Center com agenda do dia, alunos em risco, cobrancas pendentes, gargalos, fila de acoes e modo de operacao.
- Focux Score com score, ritmo, risco, proxima acao, narrativa, prioridade, objetivo e sugestao de IA.
- Historico de snapshots do Focux Score.
- Qualidade operacional.
- Notificacoes internas.
- Busca global.
- Feature gates por plano.

### Alunos

- Lista de alunos com filtros.
- Cadastro, edicao e exclusao.
- **Aluno 360** (`aluno_detail_screen.dart`):
  - **Operacao**: status operacional, aderencia semanal, proxima acao, follow-up, copiloto IA com execucao de tarefas, modo foco (sync BE), recovery e banner de risco financeiro.
  - **Evolucao**: evolucao inteligente, peso/atividade, timeline 360 paginada, Focux Score e insights.
  - **Ferramentas**: atalhos para treinos, chat, anamnese, financeiro, fotos, trilhas, engajamento e demais modulos do aluno.
- Dados de objetivo, status, foto, contato, genero, consultoria, status financeiro, peso, altura, idade e equipamentos.
- Senha provisoria.
- Providers principais: `aluno360Provider`, `aluno360OperacaoProvider`, `alunoOperacaoFocusStore`.
- Acoes em massa:
  - excluir selecionados;
  - marcar mensalidades como pagas;
  - atualizar status;
  - atribuir treino.

### Treinos

- Listagem de treinos.
- Criacao de treino.
- Detalhe de treino.
- Adicionar exercicios.
- Series, repeticoes, carga, descanso e observacoes.
- Tipo de serie normal, superset e dropset.
- Presets:
  - Hipertrofia;
  - Forca;
  - Resistencia;
  - Superset;
  - Drop set.
- Reordenar exercicios.
- Duplicar exercicio.
- Remover exercicio.
- Atribuir treino ao aluno.
- Desvincular treino do aluno.
- Salvar como template.
- Duplicar treino.
- Clonar treino para aluno.
- Modo presencial.

### Biblioteca de exercicios

- Biblioteca com 190 exercicios curados na seed v2.
- Wizard para importar por modalidade e ambiente.
- Preview de importacao.
- Modalidades: musculacao, mobilidade e cardio.
- Padroes de movimento completos para forca, core, mobilidade e cardio.
- Grupos musculares completos.
- Equipamentos e espacos de treino.
- Dificuldade.
- Upload de video.
- Upload de GIF/imagem.
- Remocao de video.
- Favoritos.
- Curadoria editorial individual e em lote.
- Curadoria de midias.
- Historico de importacao de midias.
- Motor de substituicao inteligente por padrao, grupo e equipamento.
- Templates de split:
  - Full body iniciante;
  - Upper / Lower;
  - Push / Pull / Legs;
  - Bro split;
  - Casa sem equipamento.

### IA Copiloto

- Gerar treino.
- Gerar dieta.
- Dieta estruturada como preview.
- Confirmar publicacao de conteudo gerado por IA.
- Chat IA.
- Progressao de carga.
- Exportacao de progressao em PDF.
- Sugestoes de progressao para aceitar ou rejeitar.
- Resumo semanal.
- Proxima acao por aluno.
- Insights por modo:
  - geral;
  - treino;
  - dieta;
  - progressao.
- Analise de performance.
- Salvar acao do copiloto no command center.
- Tratamento de indisponibilidade, retry e referencias de erro.
- Disclaimer de seguranca.

### Financeiro

- Mensalidades.
- Criar, editar e marcar como pago.
- Historico por aluno.
- Dashboard financeiro.
- Receita do mes.
- Receita acumulada.
- Ticket medio.
- Total de inadimplentes.
- Previsao de receita.
- Vencimentos proximos.
- Top alunos.
- Evolucao mensal.
- Resumo mensal.
- Atualizar atrasos.
- Registrar contato de cobranca.
- Cobrar via chat.
- Gerar PIX com QR Code e copia e cola.
- Wallet do personal.

### Agenda

- Agenda do personal.
- Criar agendamento.
- Excluir agendamento.
- Agenda por periodo.
- Semana.
- Ocupacao.
- Status de atendimento.
- Confirmacao de presenca.

### Comunicacao e conteudo

- Chat personal-aluno.
- Inbox.
- Historico paginado.
- Busca.
- Marcar como lido.
- Enviar texto.
- Enviar midia.
- Reacoes.
- Editar mensagem.
- Apagar mensagem.
- Conversas arquivadas e nao lidas.
- Feed privado.
- Criar post com midia.
- Fixar post.
- Curtir.
- Comentar.
- Broadcasts.
- Push notifications.

### CRM e growth

- Leads.
- Kanban/lista de leads.
- Cadastro e edicao.
- Proximo contato.
- Interacoes.
- Conversao para aluno.
- Convites.
- Landing page publica.
- Identidade visual.
- Logo e paleta do personal.
- Slogan, bio, especialidades e Instagram.
- Servicos, pacotes, FAQ e CTAs.
- Dominio customizado.
- Hero image/manual/generated.
- Galeria.
- Depoimentos aprovados.
- Tracking de eventos da landing.
- Migracao magica.
- Referral.
- Planos e paywall.
- Trial e Enterprise.

### Analytics e retencao

- Analytics dashboard.
- Funil de ativacao.
- WAU.
- Cohort de retencao.
- Alertas de risco.
- Configuracao de thresholds.
- Detalhe de risco por aluno.
- Resolver alerta.
- Enviar mensagem a partir do alerta.
- Relatorio global.
- Relatorio de aderencia.
- Engajamento.
- Ranking.
- Gamificacao.

### Admin, suporte e QA

- RBAC admin.
- Suporte.
- Tickets e chat de suporte.
- QA smoke screen.
- Catalogo de rotas e endpoints.
- Preview/pump tests de rotas.

## Funcionalidades do aluno

- Cadastro por link/slug do personal.
- Login separado.
- Login Google.
- Definicao de senha definitiva.
- Reset de senha.
- Dashboard aluno.
- Ativacao do aluno.
- Perfil do aluno.
- Edicao de perfil.
- Marca do personal aplicada no app.
- Meus treinos.
- Check-in de treino.
- Registro de series, cargas e conclusao.
- Historico de check-ins.
- Anamnese.
- Plano alimentar.
- Evolucao.
- Medidas.
- Fotos de evolucao.
- Comparativo.
- Health dashboard.
- Apple Health / Google Fit.
- Recovery Score.
- Home widget de recovery.
- Chat com personal.
- Feed do aluno.
- Agenda do aluno.
- Financeiro do aluno.
- IA do aluno.
- Progressao de carga.
- Gamificacao.
- Ranking.
- Trilhas de progresso.
- Notificacoes.
- Suporte.
- Envio de depoimento.

## Integracoes

| Integracao | Uso no app |
|---|---|
| Focux Backend | API REST, WebSocket e auth |
| Firebase Messaging | Push notifications |
| Firebase Crashlytics | Crash reports |
| Google Sign-In | Login social |
| MercadoPago | Fluxos de assinatura/pagamento via backend |
| In-app purchase | Assinatura mobile |
| Cloudinary | Midias via backend |
| Apple Health | Saude e recovery |
| Google Fit | Saude e recovery |
| Terra/Garmin | Recovery via backend quando disponivel |
| Google ML Kit Pose Detection | Base para analise/pose coach |
| Rive | Animacoes premium |

## Ambientes

Configuracao central em `lib/core/config/env.dart` (lidos via `--dart-define` / flavors).

Para desenvolvimento local basta apontar a URL do backend (e, se precisar, a URL web publica). Demais defines (OAuth, pins TLS, etc.) ficam nos scripts de release / `.env.local` — **nao** documentamos aqui a lista completa de secrets nem valores.

```text
.env.local.example   → modelo local
.env.local           → gitignored
tools/release/       → builds de loja (pins obrigatorios)
```

## Rodando localmente

### Pre-requisitos

- Flutter SDK compativel com o projeto.
- Android Studio ou Xcode.
- Emulador Android/iOS ou Chrome.
- Backend disponivel localmente ou em producao.

### Instalar dependencias

```bash
flutter pub get
```

### Rodar Android

```bash
flutter run -d emulator-5554 \
  --dart-define=API_URL=http://10.0.2.2:8080 \
  --dart-define=PUBLIC_WEB_URL=http://10.0.2.2:8080
```

No emulador Android, `10.0.2.2` aponta para `localhost` da maquina host.

### Rodar web

```bash
flutter run -d chrome --web-port 61791 \
  --dart-define=API_URL=http://localhost:8080 \
  --dart-define=PUBLIC_WEB_URL=http://localhost:61791
```

> Scripts PowerShell de conveniencia (`run-android.ps1`, `build-web.ps1`, etc.) existem apenas localmente — nao estao versionados. Veja a secao **Scripts locais** abaixo.

### Rodar apontando para outro backend

```bash
flutter run \
  --dart-define=API_URL=https://SEU_BACKEND \
  --dart-define=PUBLIC_WEB_URL=https://SEU_SITE
```

No Windows PowerShell:

```powershell
flutter run `
  --dart-define=API_URL=https://SEU_BACKEND `
  --dart-define=PUBLIC_WEB_URL=https://SEU_SITE
```

## Scripts locais

A pasta `scripts/` e **gitignored** (ferramentas de deploy, build e assets por maquina). Mantenha uma copia local ou recrie conforme necessidade.

Comandos equivalentes versionados no README:

| Tarefa | Comando |
|---|---|
| SHA-1 debug Android | `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |
| APK release | `flutter build apk --release` com `--dart-define` de ambiente |
| Web release | `flutter build web --release` com `--dart-define` de ambiente |
| Deploy Vercel | `flutter build web --release` + `npx vercel deploy --prebuilt` |

### Android local

Copie `android/gradle.properties.example` para `android/gradle.properties` e ajuste memoria/JVM para sua maquina.

## Build

### Android APK

```bash
# Preferir tools/release/build-android.sh (exige pins TLS da API)
flutter build apk --release \
  --dart-define=API_URL=https://SEU_BACKEND \
  --dart-define=PUBLIC_WEB_URL=https://focuxpersonal.com
```

Saida:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### Web

```bash
flutter build web --release \
  --dart-define=API_URL=https://SEU_BACKEND \
  --dart-define=PUBLIC_WEB_URL=https://focuxpersonal.com
```

Saida:

```text
build/web/
```

### iOS / TestFlight

Guia completo (único passo manual após conta Apple): **`TESTFLIGHT.md`**.

```bash
./tools/release/build-ios.sh
```

Requer Mac, Xcode e Team ID em `ios/ExportOptions.plist`.

## Testes e qualidade

### Analyzer

```bash
dart analyze --fatal-warnings --fatal-infos
```

CI e pre-commit devem manter **zero issues**.

### Unit/widget tests

```bash
flutter test
```

Contratos de seguranca (hubs + Android; monorepo valida website se o checkout incluir `../focux-website/`):

```bash
flutter test test/core/security/ test/core/design_system/security_pillar_contract_test.dart
```

### Integration tests

```bash
flutter test integration_test
```

### E2E web

```bash
cd e2e
npm install
npx playwright install chromium
npx playwright test
```

### CI

O workflow E2E executa:

- `flutter pub get`;
- `flutter analyze`;
- `flutter test`;
- `flutter build web --release`;
- servidor web local em `localhost:61791`;
- Playwright em Chromium;
- backend tests quando o workflow roda em contexto com `focux-backend`.

## Assets

Principais grupos de assets:

```text
assets/images/
assets/animations/
brand/
android/app/src/main/res/
ios/Runner/Assets.xcassets/
```

Inclui logos Focux, splash, app icon, mesh background e animacoes Rive:

- `confetti_success.riv`;
- `confetti_burst.riv`;
- `cdn_heart.riv`;
- `star_sparkle.riv`.

## Internacionalizacao

Fontes (versionadas):

```text
lib/l10n/app_pt.arb
lib/l10n/app_en.arb
lib/l10n/app_es.arb
l10n.yaml
```

Arquivos gerados `lib/l10n/app_localizations*.dart` sao **gitignored**. Regere com:

```bash
flutter gen-l10n
```

## Backend

Repositorio: `focux-backend` (deploy Railway). Aponte o app para o host HTTPS do ambiente desejado.

## Seguranca (app)

Catalogo central: **`lib/core/security/focux_security.dart`** (`FocuxSecurity` v1.1).

| Gate | Arquivo | O que trava |
|---|---|---|
| Hubs | `test/core/design_system/security_pillar_contract_test.dart` | Token em `SecureStorage`, erros sem `$e` na UI, disclaimer IA, padroes proibidos |
| App + TLS | `test/core/security/focux_security_test.dart` | Fontes do catalogo, pinning, device guard, CI Semgrep/gitleaks |
| Android | `test/core/security/platform_hardening_test.dart` | Manifest (HTTPS, sem backup, App Links `focuxpersonal.com`, `taskAffinity=""`), `network_security_config`, backup rules, ProGuard |
| Monorepo | mesmo teste acima | Se existir checkout irmao: `focux-website/vercel.json`, `assetlinks.json` |

Postura atual (alto nivel):

- Autenticacao JWT; refresh com rotacao; logout invalida sessao local e no backend.
- Storage seguro para tokens no mobile; limpeza de cache/offline no logout.
- Builds de release exigem certificate pinning da API (scripts em `tools/release/`).
- App Links / Universal Links com paths allowlisted em `focuxpersonal.com`; fingerprint release sincronizado com website e backend (nao publicar valor no git markdown).
- Hardening Android: cleartext off, backup off, rede TLS-only — nao regredir ao elevar telas.
- Autorizacao e isolamento de tenant sao responsabilidade do backend — o app nao e fonte de verdade.

Nunca commitar:

- `.env.local` e variantes;
- `android/gradle.properties` (use `.example`);
- `android/key.properties`, keystores;
- `google-services.json` / `GoogleService-Info.plist` reais (use `*.example`);
- service accounts Firebase;
- senhas de review, admin ou QA no codigo ou markdown.

Client IDs OAuth publicos e senhas de review ficam so no deploy / docs internos do time — nao neste README.

## Roadmap operacional

1. Release Android/iOS com pins e deep links de producao.
2. IAP completo (verify + notificacoes das lojas).
3. QA smoke + E2E nas rotas criticas.
4. Habitos, recorrencia e monetizacao enterprise.
5. Health/recovery, wearables e pose coach.

## Licenca

Projeto privado/proprietario. Uso, distribuicao e copia dependem de autorizacao do proprietario.
