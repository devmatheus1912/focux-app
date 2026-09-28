# FOCUX — PROMPT MESTRE PARA SUPERPOWERS → BRAINSTORMING

Auditoria 360º do produto real: experiência, software, dados, negócio, segurança, operação e prontidão para a Apple App Store.

Você vai auditar o Focux como um sistema integrado. Os dois repositórios abaixo são a fonte da verdade. Este texto não é o inventário do produto. É a ordem de trabalho para você descobrir o produto, validar o que existe, e só então priorizar.

---

## 0. O que você é nesta sessão

Pense ao mesmo tempo como:

- Product Manager
- UX Designer
- UI Designer
- Flutter Engineer
- Backend Engineer
- Software Architect
- QA Engineer
- Security Engineer
- Performance Engineer
- DevOps / SRE
- especialista em publicação na Apple App Store

Isso não autoriza uma lista genérica de boas práticas. Cada achado nasce do código, do contrato ou de um fluxo rastreado. Se a evidência não existe, o achado não existe: marque `NECESSITA VALIDAÇÃO`.

O produto se chama Focux Personal no binário iOS. Há duas experiências no mesmo app Flutter, ligadas a um backend Spring Boot multi-tenant: **Personal** e **Aluno**. Não assuma um terceiro app. Não assuma que “Personal 360” é o nome de uma tela.

---

## 1. Restrições absolutas desta sessão

Esta sessão é somente:

ANALISAR → DESCOBRIR → QUESTIONAR → CONECTAR → PRIORIZAR → PLANEJAR.

É proibido, durante o brainstorming:

- implementar
- editar arquivos
- refatorar
- alterar banco, migração, API ou UI
- apagar código
- remover, enfraquecer ou “simplificar” testes
- criar funcionalidade
- criar branch, commit ou pull request
- modificar o working tree
- formatar, gerar código, ou rodar comando que grave arquivo
- propor patch, diff ou snippet pronto para colar como implementação

Leitura, busca e inspeção são permitidas. Testes e builds só se forem estritamente somente-leitura e não alterarem o tree; se houver dúvida, não rode e marque `NECESSITA VALIDAÇÃO`.

O relatório é a resposta desta sessão. Não grave o relatório no repositório, a menos que o humano peça isso numa sessão posterior.

A fase de implementação controlada descrita no final deste prompt **não começa agora**.

---

## 2. Repositórios e baseline

Audite os dois repositórios em conjunto. Um achado de tela sem o endpoint, ou um endpoint sem o consumidor, está incompleto.

| Repositório | Papel | Branch padrão observada |
|---|---|---|
| `focux-app` | Cliente Flutter (iOS, Android, web) | `main` |
| `focux-backend` | API Spring Boot, jobs, webhooks, páginas públicas servidas pelo backend | `master` |

Há também, dentro do backend, o subprojeto `landing-web/` (Astro). Trate-o como superfície real se o código o publicar. O README do app cita um terceiro repositório, `focux-website`, que **não está neste workspace**. Qualquer comportamento que dependa dele fica `NECESSITA VALIDAÇÃO` fora do código disponível. Não invente o site.

### Baseline em que este prompt foi escrito — não confie nele

Este prompt foi redigido depois de uma leitura dos trees, mas os dois repositórios se movem. Antes de qualquer conclusão:

1. Confirme o HEAD real de `focux-app` `main` e de `focux-backend` `master` (incluindo o remoto, se o working tree estiver atrás).
2. Se o HEAD for diferente dos SHAs abaixo, o snapshot deste prompt está desatualizado na diferença. Releia o que mudou.
3. O código do HEAD vence este prompt, os READMEs, os ADRs, as specs antigas e qualquer auditoria já commitada.

SHAs usados como piso desta redação (podem já não ser o HEAD):

- app: `ad95f815` em `main` — versão em `pubspec.yaml`: `1.2.1+133`
- backend remoto observado: `39b3249f` em `master`

O working tree do backend pode estar atrás do remoto. Não audite um checkout velho se o remoto já tiver o contrato novo da Home do aluno, da prévia de treino e do check-in.

### Docs que existem e não mandam no código

Leia como contexto, nunca como prova de que a feature funciona:

- `focux-app/docs/FOCUX_DESIGN_REFERENCE.md` (taxonomia S1–S9, pele, job, gates)
- `focux-app/docs/system/*` e `focux-app/docs/CONTRATO_APP_BACKEND.md`
- `focux-backend/docs/CONTRATO_APP_BACKEND.md`, `docs/SYSTEM.md`, `AUDIT.md`, `docs/adr/*`
- `focux-app/docs/FOCUX_PERFORMANCE_AUDIT.md`
- `focux-app/docs/FOCUX_STUDENT_EXPERIENCE_AUDIT.md`
- `focux-app/docs/FOCUX_REFERRAL_SYSTEM.md` e `FOCUX_REFERRAL_SECURITY.md`
- `focux-app/docs/superpowers/specs/*` e `docs/superpowers/plans/*`
- `focux-app/tools/audit/backend_endpoints.tsv` se ainda existir

Há specs recentes de Home do aluno, dados/insights e referral. Commits recentes nos dois repositórios mexeram exatamente nesses fluxos (Home do aluno, prévia de treino, “já fiz”, histórico, fila de séries, anamnese no BFF, cache). Sua tarefa é descobrir o que já está no código e o que a spec ainda promete. Não reabra um redesign já shipped como se não existisse. Não dê a spec como pronta só porque o arquivo existe.

Divergência já vista e que você deve reconfirmar: o README do app ainda citava a versão `1.2.1+92` enquanto `pubspec.yaml` estava em `1.2.1+133`. Docs atrasados são um achado de operação, não uma fonte.

---

## 3. Regra de escopo — a mais importante

Nenhuma lista deste prompt é escopo fechado. Isso inclui:

- rotas
- telas
- módulos
- fluxos de exemplo (treino, saúde, chat, pagamento, referral)
- entidades
- integrações
- o snapshot de ancoragem da seção 6

Essas listas são exemplos e âncoras para você não esquecer domínios já vistos. Elas não são:

- a lista completa de funcionalidades
- a ordem de prioridade
- as únicas telas
- as únicas integrações

Protocolo:

1. Descubra o produto a partir dos repositórios.
2. Reconstrua o inventário.
3. Só então audite.
4. Se o código contradisser este prompt, o código vence e você registra a correção.
5. Se existir rota, tela, sheet, dialog, provider, repository, endpoint, entidade, job, webhook ou integração que este prompt não cita, ela entra com a mesma profundidade.
6. Um item do snapshot que você não reabriu no código fica `NÃO REVALIDADO NESTA SESSÃO`. Nunca vira `IMPLEMENTADO` por estar escrito aqui.

Nomes não bastam. Classe, rota, endpoint, arquivo, comentário, TODO ou model não provam feature. Para cada capacidade, classifique com uma destas etiquetas, sempre com evidência:

| Etiqueta | Significado |
|---|---|
| `IMPLEMENTADO` | Chega ao usuário, persiste, e o outro lado do contrato consome ou produz o dado |
| `PARCIAL` | Parte do caminho existe; falta passo, estado, papel ou persistência |
| `INCOMPLETO` | Esboço ou fluxo que não fecha |
| `ÓRFÃO` | Código sem consumidor, sem rota, ou sem efeito de produto |
| `NÃO UTILIZADO` | Existe num lado (app ou backend) e o outro lado não chama |
| `QUEBRADO` | O caminho existe e falha, perde dado, ou mente para o usuário |
| `NÃO VALIDADO` | Não deu para provar pelo código nesta sessão |
| `NECESSITA VALIDAÇÃO` | Depende de ambiente, loja, dispositivo, segredo ou regra externa da Apple |
| `NÃO REVALIDADO NESTA SESSÃO` | Estava no snapshot e você não reabriu o arquivo |

Diferencie também: dado real, dado calculado no cliente, dado calculado no servidor, fallback estático, cache, e valor de marketing hardcoded.

---

## 4. Como descobrir antes de opinar

Faça quatro passagens, nesta ordem. Não comece pela estética.

### Passagem A — Inventário

App:

- todos os `GoRoute` em `lib/core/router/` (`app_router.dart`, `app_router_auth_routes.dart`, `app_router_personal_shell_routes.dart`, `app_router_aluno_routes.dart`, `app_router_chrome_routes.dart`, `app_router_redirect.dart`, `qa_routes.dart`, `qa_routes_stub.dart`, `role_home.dart`)
- shells `lib/core/screens/main_shell.dart` e `aluno_shell.dart`
- dock `lib/core/widgets/fx_dock.dart`
- cada diretório em `lib/features/`
- sheets, dialogs e modais que não são rota (`showModalBottomSheet`, `showDialog`, widgets `*sheet*`, `*dialog*`)
- providers, repositories, services, models
- `lib/core/api/`, `lib/core/storage/`, `lib/core/auth/`, `lib/core/fcm/`, `lib/core/health/`, `lib/core/config/env.dart`

Backend:

- cada diretório em `src/main/java/com/focux/modules/`
- `src/main/java/com/focux/infra/` e `config/` (segurança, rate limit, websocket, cache, webhook, observabilidade)
- `@RequestMapping` / `@GetMapping` / `@PostMapping` e equivalentes
- entidades JPA, DTOs, Flyway em `src/main/resources/db/migration/`
- `@Scheduled`, listeners, publishers STOMP
- `SecurityConfig` e a lista de rotas públicas

Conte de novo. Não reutilize contagens deste prompt como fato.

### Passagem B — Rastro ponta a ponta

Para cada fluxo crítico, reconstrua:

tela → ação → provider → repository → API → controller → service → banco → resposta → estado → próxima tela → quem mais lê esse dado (Home, histórico, evolução, Aluno 360, Personal, jobs, push)

Marque o primeiro elo quebrado, duplicado ou fictício.

### Passagem C — Órfãos, duplicação, mentira de dado

Procure endpoint sem caller no app, tela sem entrada, provider sem listener, model sem uso, feature flag, `kDebugMode`, redirect que esconde rota antiga, HTTP 410, `@Deprecated`, dependência no `pubspec.yaml` sem import em `lib/`, cálculo duplicado, fallback estático servido como se fosse medida.

### Passagem D — Risco de produção

Segurança, pagamento, auth, integridade de treino, saúde, App Store, testes, observabilidade. Só depois disso, julgamento de produto e prioridade.

---

## 5. Mapa de nomes — não traduza errado

| Como alguém pode chamar | O que o código usa (revalidar) |
|---|---|
| Personal 360 | Não há tela com esse nome. A visão do personal sobre **um aluno** é o Aluno 360: `AlunoDetailScreen` em `/alunos/:id`, abas Operação / Evolução / Ferramentas, BFF `GET /api/alunos/{id}/360/operacao`, `/evolucao`, `/ferramentas`, mais timeline. O hub do próprio personal é `PersonalDashboardScreen` em `/dashboard/personal` (dock “Hoje”) e o command center em `/dashboard/command-center/copiloto`. |
| Home | Dock “Hoje”. Personal: `/dashboard/personal`. Aluno: `/dashboard/aluno` (`AlunoDashboardScreen`). Há BFF `GET /api/dashboard/home` e `GET /api/dashboard/aluno/home`. |
| Treinos do aluno | Tab `/checkin/treinos` → `MeusTreinosScreen`. Prévia: `/checkin/treino/:treinoId` → `TreinoPreviaScreen`. Execução: `/checkin/executar` → `CheckinScreen`. |
| Execução / série / RPE / dor | Módulo `checkin`, não um módulo “serie”. Backend: `ExecucaoTreino`, `ExecucaoExercicio`, `ExecucaoSerie`, com `rpe` e `dor`. |
| Saúde / readiness | Tab `/saude`, `health`, recovery score, widget iOS `ios/FocuxRecoveryWidget/`. |
| Assinatura do personal (SaaS) | `in_app_purchase` no app nativo + `POST /api/iap/verify`. Mercado Pago aparece no checkout **web** e em cobranças de aluno (PIX, recorrência, loja). Não há RevenueCat nem Stripe no que foi visto — confirme ausência, não assuma que “deveria” existir. |
| Papéis | `PERSONAL` e `ALUNO` no app. RBAC de equipe e `Personal.isAdmin` são outra coisa. Não invente um app admin separado. |

Se a UI chamar algo de “360” em copy de marketing, isso não cria uma tela.

---

## 6. Snapshot de ancoragem — revalidar, não copiar

Tudo nesta seção é hipótese de partida. Reabra o arquivo. Classifique. Acrescente o que faltar.

### 6.1 Forma do app

- Pacote `focux_app`. Estado principal: Riverpod. `provider`/`ChangeNotifier` ainda aparece em plano de sucesso — confirme se continua.
- HTTP: Dio em `lib/core/api/api_client.dart` (Bearer, ETag, retry, fila offline genérica). Dinheiro/IAP: `payment_api_client.dart`. Upload: `media_upload_service.dart`.
- Base URL: `lib/core/config/env.dart` (`API_URL`, `WS_URL`, URL pública). Não copie segredos nem hosts com credencial para o relatório.
- Navegação: GoRouter com redirect de auth/papel.
- Design system já existe. Não invente outro. Tokens e pele: `lib/core/theme/` (`design_tokens.dart`, `tokens_strip.dart`, `app_theme.dart`, tipografia, `fx_settings_layout.dart`). Motion: `lib/core/motion/focux_motion.dart`. Data viz: `lib/core/data_viz/focux_data_viz.dart`. Catálogo de superfícies: `lib/core/design_system/`. Referência normativa: `docs/FOCUX_DESIGN_REFERENCE.md`. Onde o código divergir do doc, descreva os dois e diga qual o usuário vê.
- Locale: `MaterialApp.router` força `Locale('pt')` e mesmo assim registra `S.localizationsDelegates`. ARB `pt`/`en`/`es` existem. ADR do backend (`docs/adr/002-brasil-first-sem-i18n.md`) pode estar atrasado. Descubra se a UI está de fato só em português e se strings ainda estão hardcoded fora do ARB.
- `main.dart` limita `textScaler` (teto mais baixo em telefone estreito). Cruze isso com os commits recentes que tentam não cortar texto da Home com fonte grande. Acessibilidade e Dynamic Type: `VALIDAR ANTES DA SUBMISSÃO`, com o clamp citado em arquivo e linha.
- iOS observado: bundle `com.focux.focuxApp`, display name Focux Personal, entitlements com Sign in with Apple, associated domains `focuxpersonal.com` / `www.focuxpersonal.com`, HealthKit, app group. `PrivacyInfo.xcprivacy` existe. `ios/Products.storekit` existe. Firebase real é template (`*.example`) e não deve ser versionado — confirme `git ls-files`. Permissões de câmera, fotos, microfone, fala, Face ID e Health estão no `Info.plist`; releia os textos, não copie da memória.

### 6.2 Shells

Personal (`MainShell`), dock: Hoje, Alunos, Treinos, Agenda, IA.

| Path | Tela a confirmar |
|---|---|
| `/dashboard/personal` | `PersonalDashboardScreen` |
| `/alunos` | `AlunosListScreen` |
| `/treinos` | `TreinosListScreen` |
| `/agenda` | `AgendaScreen` |
| `/ia/copiloto` | `IaCopilotoScreen` |

Aluno (`AlunoShell`), dock: Hoje, Treinos, Saúde, Chat, Perfil. O dock de chat some em algumas condições — confirme.

| Path | Tela a confirmar |
|---|---|
| `/dashboard/aluno` | `AlunoDashboardScreen` |
| `/checkin/treinos` | `MeusTreinosScreen` |
| `/saude` | `HealthDashboardScreen` |
| `/chat/aluno` | `ChatAlunoScreen` |
| `/aluno/perfil` | `PerfilAlunoScreen` |

Atalhos: `/` splash; `/home`, `/dashboard`, `/dashboard/home` redirecionam para a home do papel; `/aluno` → dashboard aluno; `/personal` → dashboard personal; `/ia` → copiloto.

### 6.3 Rotas públicas e de conta

Recontar em `app_router_auth_routes.dart`: `/login`, `/login/mfa`, `/register`, `/register/aluno`, `/onboarding`, `/esqueci-senha`, `/resetar-senha`, `/resetar-senha/verificar-codigo`, `/p/:slug` (redirect para login de aluno com slug), `/convite/:token`, `/aluno/definir-senha`.

Debug: `/qa/smoke`, `/qa/tokens-strip` só em debug; release usa stub. Confirme que não vazam no binário de loja.

### 6.4 Rotas autenticadas fora do dock

Reabra `app_router_chrome_routes.dart` e `app_router_aluno_routes.dart` e produza a tabela completa path → widget → papel. O piso abaixo estava no router no SHA do app citado. Acrescente o que nascer depois. Vários paths são redirect, não tela.

Aluno além do dock: `/aluno/ativacao`, `/aluno/habitos`, `/aluno/habitos/:id`, `/aluno/desafios`, `/aluno/desafios/:id`, `/aluno/recorrencia`, `/aluno/grupo-aulas`, `/aluno/perfil/editar`, `/aluno/anamnese`, `/aluno/trilhas`, `/aluno/form-check` (redirect), `/evolucao` (redirect), `/feed/aluno`, `/financeiro/aluno`, `/agenda/aluno`, `/depoimentos-aluno`.

Personal e compartilhadas (confirmar guarda de papel em cada uma):

- operação: `/dashboard/qualidade`, `/dashboard/command-center/copiloto`
- aluno: `/alunos/novo`, `/alunos/acoes-massa` (redirect), `/alunos/:id`, `/alunos/:id/editar`, `/alunos/:id/equipamentos`, `/alunos/:id/relatorio`, `/alunos/:id/evolucao`, `/alunos/:id/plano-sucesso`, `/alunos/:id/fotos`, `/alunos/:id/anamnese`, `/personal/alunos/:id/anamnese` (redirect), `/alunos/:id/treinos-list`, `/alunos/:id/ia/progressao`, `/alunos/:id/chat`, `/alunos/:id/feedback-video`, `/alunos/:id/engajamento`, `/alunos/:id/evolucao-comparativo`, `/alunos/:id/trilhas`, `/alunos/:id/feedback-videos`
- treino e biblioteca: `/treinos/novo`, `/treinos/:id`, `/treinos/:id/exercicios/add`, `/exercicios`, `/exercicios/novo`, `/exercicios/biblioteca-wizard`, `/exercicios/:id`, `/exercicios/:id/editar`
- check-in: `/checkin`, `/checkin/executar`, `/checkin/treino/:treinoId`, `/checkin/historico`, `/checkin/historico/:id`
- agenda e dinheiro: `/agenda/novo`, `/financeiro`, `/financeiro/mensalidades/:id`
- conta e marca: `/perfil`, `/configuracoes`, `/perfil/editar`, `/perfil/link-publico`, `/perfil/wallet`, `/perfil/ferramentas`, `/perfil/mfa`, `/identidade-visual`, `/white-label`, `/perfil/white-label`, `/setup/identidade`, `/perfil/equipe`, `/perfil/landing-editor`
- IA e chat: `/ia/chat`, `/ia/checkin` (redirect), `/ia/progressao/aceitar`, `/chat/inbox`
- feed, CRM: `/feed`, `/leads`, `/leads/kanban`, `/kanban`, `/leads/novo`, `/leads/:id`, `/leads-publicos`
- alertas e relatórios: `/alertas`, `/alertas/aluno/:id`, `/alertas/config`, `/relatorios/global`, `/relatorio/business`
- monetização e growth: `/convites`, `/planos` e `/paywall` (redirect para `/assinatura`), `/assinatura`, `/assinatura/review`, `/assinatura/success`, `/referral`, `/retencao`, `/ofertas-upsell`, `/cancel-save`, `/dunning`, `/winback`, `/promo-enterprise`, `/migracao-magica`, `/migracao-focux`, `/growth/migracao`
- programas: `/habitos`, `/habitos/:id`, `/automacoes`, `/desafios`, `/desafios/:id`, `/loja`, `/pacotes`, `/recorrencia`, `/nps`, `/grupo-aulas`, `/onboarding/wizard`
- outros: `/ranking`, `/coach`, `/notificacoes`, `/suporte`, `/broadcasts`, `/depoimentos`, `/galeria`, `/feedback-videos`, `/busca`, `/analytics`, `/gamificacao`, `/ferramentas/hub/:itemId`, `/admin/rbac`

Para cada rota responda: quem chega nela sem saber a URL? O dock, um push, um deep link, um push FCM, ou só quem digita o path?

### 6.5 Módulos do app (`lib/features/`)

Piso, não teto. Um diretório sem tela ainda pode ser infraestrutura (`subscription`, `pricing`).

`admin`, `agenda`, `alertas`, `alunos`, `analytics`, `anamnese`, `assinatura`, `auth`, `automacoes`, `avaliacao`, `broadcasts`, `busca`, `captura`, `chat`, `checkin`, `coach`, `convites`, `dashboard`, `depoimentos`, `desafios`, `dunning`, `evolucao`, `exercicios`, `feed`, `feedback`, `ferramentas`, `financeiro`, `galeria`, `gamificacao`, `growth`, `grupos`, `habitos`, `health`, `ia`, `leads`, `loja`, `monetizacao`, `notificacoes`, `nps`, `onboarding`, `pacotes`, `perfil`, `planos`, `plano_sucesso`, `pricing`, `qa`, `ranking`, `recorrencia`, `referral`, `relatorio`, `retencao`, `subscription`, `suporte`, `treinos`, `trilhas`, `winback`.

### 6.6 Módulos do backend (`com.focux.modules`)

Piso. No intervalo até `39b3249f` nasceram ou mudaram peças de check-in (`CheckinPreviaService`), Home do aluno (campos de anamnese, insight, volume, agenda condicionada ao plano), NPS e agenda. Releia esses pacotes no HEAD.

`agenda`, `alertas`, `alimentar`, `alunos`, `analytics`, `anamnese`, `auditoria`, `auth`, `automacoes`, `avaliacao`, `backup`, `brand`, `broadcast`, `busca`, `campanhas`, `captura`, `chat`, `checkin`, `coach`, `comunidade`, `convites`, `dashboard`, `depoimentos`, `desafios`, `dunning`, `engajamento`, `evolucao`, `exercicios`, `exportacao`, `fcm`, `feed`, `feedback`, `ferramentas`, `financeiro`, `galeria`, `gamificacao`, `growth`, `grupos`, `habitos`, `health`, `ia`, `iap`, `leads`, `lgpd`, `loja`, `monetizacao`, `nfse`, `notificacoes`, `nps`, `onboarding`, `pacotes`, `pagamentos`, `personal`, `planos`, `planosucesso`, `posecoach`, `pql`, `pricing`, `ranking`, `rbac`, `recorrencia`, `referral`, `relatorio`, `retencao`, `suporte`, `sync`, `templates`, `treinos`, `trilhas`, `upload`, `webhooks`, `winback`.

Flyway: conte os `V*.sql`. A leitura antiga viu na ordem de 170 migrações. Não use o número como fato.

Padrão frequente: CRUD mais um BFF `*/home`. Muitos hubs do app foram desenhados para first paint em um request. Verifique se a tela ainda dispara sidecars que anulam isso.

### 6.7 Hipóteses para confirmar ou refutar

Não transforme nenhuma linha em P0 sem reler o código e mostrar o efeito no usuário ou no dado.

1. **Duas filas offline de treino.** `OfflineSyncService.isSensitivePath` exclui `/checkin` (e também chat, anamnese, health, lgpd, wallet, mensalidade, pagamento, financeiro, auth, alunos, leads, perfil, ia, comunidade, fcm, upload — releia a função). Em paralelo, o check-in tem fila própria de séries: `CheckinSeriesPendentesStore`, `checkin_series_fila.dart`, `CheckinFilaSync`, escopo global `checkin_fila_sync_scope.dart`. A série guarda carga, repetições, RPE, dor e feedback e reenvia por `registrarSerie`. 4xx sai da fila; 5xx/401/408/429/rede ficam. Audite: concluir treino com pendência, reabrir sessão, duplicar série, “já fiz” repetido no dia, o que a Home e o Aluno 360 mostram antes do flush, e se o personal vê carga inventada. O backend recente tem regra explícita de “confirmar restante sem inventar carga” — rastreie até a UI.
2. **Prévia e hub de treinos.** `TreinoPreviaScreen` e `MeusTreinosScreen` mudaram de papel (hub com prévia, rodízio, “já fiz” sem séries). Não descreva a tab Treinos como uma lista antiga.
3. **Home do aluno e BFF.** O contrato `GET /api/dashboard/aluno/home` perdeu campos legados. Cruze `AlunoDashboardHomeResponse` com o parser Dart. Insight, coach, meta, recorde, anamnese, agenda com horário, NPS adiado e cache da Home são um fluxo só. Procure card duplicado de evolução e atalho que repete o topo.
4. **Recovery em dois lugares.** Cliente: `lib/core/health/recovery_score.dart` (`RecoveryScoreView.compute`). Servidor: calculadora de recovery no módulo `health`, alimentada por `POST /api/aluno/saude/sync`, lida em `/api/aluno/saude/recovery` e no BFF / Aluno 360. Diga qual número aparece antes do sync, depois, offline, e na tela do personal. Widget iOS entra nesse rastro.
5. **Terra versus Health.** Webhook Terra no backend. O app sincroniza Apple Health / Health Connect. Confirme se Terra tem efeito de produto ou é caminho morto.
6. **Biblioteca de exercício.** `kBibliotecaLibraryVideosStandby` em `lib/features/exercicios/services/biblioteca_media_config.dart` estava `true`, com comentário de que a mídia MoveKit/Cloudinary live usa URL publicada e que não se abre sheet “em breve”. Confirme o comportamento real da prévia sem mídia.
7. **Pose coach.** Testes do app afirmavam que `gated_pose_coach_panel.dart` e `pose_coach_panel.dart` não existem. `google_mlkit_pose_detection` estava no `pubspec.yaml` sem uso em `lib/`. O backend tem módulo `posecoach`. Classifique os três fatos no HEAD. Não proponha reativar pose coach sem evidência de job de usuário.
8. **Comunidade e `/api/hoje`.** `api_client.dart` listava `/api/comunidade` e `/api/hoje` em cache. Hipótese: sem repository no app; `ComunidadeController` existe; `/api/hoje` sem mapping. Grupo de aulas (`/api/grupo-aulas`) é outro domínio. Não misture.
9. **Alimentar.** Módulo `alimentar` respondia 410. Confirme se sobrou UI de dieta.
10. **Listas cruas 410.** Analytics e agenda teriam endpoints crus aposentados em favor de `*/home`. Confirme se o app ainda chama os crus.
11. **Outbox.** `OutboxProcessorJob` marca evento como `PROCESSADO` depois de log, sem consumer externo. Descubra se algum fluxo de produto depende disso ou se é infra morta. Não proponha Kafka por padrão.
12. **Pagamentos.** IAP nativo verifica no backend. Preferência Mercado Pago de plano SaaS no app estava condicionada a `kIsWeb`. `POST /api/pagamentos/preapproval/{planoId}` parecia sem caller no app. Webhook Mercado Pago é servidor (`/api/webhooks`). Recorrência e PIX de mensalidade do aluno são outro dinheiro (aluno → personal), não a assinatura da loja. Separe os três ledgers: SaaS do personal, mensalidade do aluno, loja/pedido. Referral converte em pagamento real — rastreie IAP e MP até o ledger.
13. **IAP fail-closed.** Há código de verificação Apple/Google que muda de comportamento sem segredo. Não afirme que recibo falso passa. Diga o que o código faz quando o verifier não está configurado, e marque produção como `NECESSITA VALIDAÇÃO`.
14. **Restore e exclusão de conta.** `restorePurchases` existe na assinatura. Exclusão: `DELETE /api/lgpd/me/delete` no aluno e no perfil do personal. Confirme se os dois papéis concluem o fluxo exigido pela App Store (exclusão iniciada no app, não só um link solto) e o que é apagado de verdade (treino, saúde, mídia, tokens, tenant).
15. **Suporte.** A rota `/suporte` redireciona para a web. `ApiClient` pode postar `POST /api/suporte/analisar-erro` para personal. Separe o que o usuário vê do que o cliente dispara sozinho.
16. **Referral.** UI chama `GET /api/referral`. Validação pública de código e atribuição no cadastro precisam ser rastreadas até conversão, limite e estorno. `GET /api/referral/validar/{codigo}` pode estar sem caller.
17. **Export/backup.** Endpoints de exportação e backup podem estar só no catálogo de QA. Confirme se LGPD export (`/api/lgpd/me`) é o caminho real do titular.
18. **Entitlements.** Queda de rede usa mapa estático de capabilities e cache local em planos. Diga se o app libera ou bloqueia feature quando o BFF não responde. A regra do design system é capability, nunca `plano == 'FREE'`. Procure o atalho proibido.
19. **NFS-e, campanhas, PQL, smart pricing.** Podem ser backend-only ou sem superfície útil. Classifique. Não vire feature de lançamento por existir classe.
20. **White-label e landing.** Identidade, editor de landing, páginas `/p/`, `/c/`, `/landing/`, convite HTML. Fazem parte do produto público. Audite o que um aluno vê antes de ter conta.
21. **STOMP.** Chat usa SockJS/STOMP em `{ws}/ws/websocket` com tópicos por personal/aluno. Handshake `/ws/**` é público e o JWT entra no CONNECT — confirme o interceptor. Não há, na leitura antiga, WS para dashboard ou push. Notificação de produto é FCM + centro in-app.
22. **Analytics de produto.** `POST /api/analytics/evento` pode estar ligado só a um funil estreito. Crashlytics existe no app. Sentry existe no backend (DSN opcional). Não chame isso de observabilidade completa até ver o que um incidente de pagamento ou de fila de séries emite.
23. **RBAC.** `/admin/rbac` e membros de tenant. Descubra quem abre a tela e se o backend recusa o recurso, não só esconde o botão.
24. **Textos e escala.** Home do aluno teve correções de quebra de linha com fonte grande ao mesmo tempo em que o scaler é clampado. Diga qual dos dois o usuário de iPhone pequeno experimenta.
25. **README versus binário.** Versão, stack e escopo do README não batem necessariamente com `pubspec.yaml` nem com o router. Trate README como superfície pública desatualizada até prova em contrário.

---

## 7. Inventário obrigatório (saída, seção 1–4)

Antes de sugerir melhoria, publique:

1. Inventário de módulos dos dois repos, com etiqueta de status.
2. Mapa de telas: path, widget, papel, tipo S1–S9 se conseguir classificar pela referência já existente, entrada (dock, push, deep link, FCM), e se é redirect morto.
3. Mapa de sheets e dialogs que não são rota, amarrados à tela dona.
4. Mapa de fluxos ponta a ponta (seção 9).
5. Arquitetura App ↔ Backend: BFFs usados no first paint, sidecars, cache/ETag, fila offline genérica versus fila de séries, STOMP, FCM, webhooks que o app nunca vê.
6. Entidades que importam para o usuário, não o catálogo bruto das ~100 classes. Inclua relações: Personal 1—N Aluno; treino prescrito; execução e séries; medida, foto, recorde; mensalidade e recorrência; plano SaaS e `planoValidoAte`; referral; chat; agenda; health snapshot; anamnese.

Não desenhe arquitetura-alvo. Descreva a que o código executa.

---

## 8. Auditoria de cada tela

Toda tela alcançável ganha um scorecard curto. Fluxos P0/P1 ganham narrativa. Não escreva um ensaio de UX idêntico para cem telas.

Scorecard mínimo:

- por que a tela existe e qual job fecha
- ação primária
- de onde vem o dado (endpoint, repository, cache, constante)
- o que o backend tem e a tela não mostra
- o que a tela mostra sem origem
- loading, vazio, erro, offline, sucesso, primeira vez, retorno
- uma frase de UI só se houver inconsistência real com o design system existente (densidade, card sem job, métrica sem decisão, motion sem função, safe area, contraste, tipo)
- risco de segurança só se a tela lê ou grava dado de outro tenant, saúde, pagamento ou sessão

### UX, quando houver achado

Clareza, hierarquia, decisão, carga cognitiva, consistência com o resto do Focux, feedback, prevenção e recuperação de erro, acessibilidade, estados. Cite o widget. “Deixar mais bonito” não é achado.

### UI

Use a pele que já existe (Tokens Strip, tipografia, inset-grouped só onde o tipo S2 manda, CTA conforme S5/S6/S9). Aponte tela que virou outro produto: genérica, entupida de cards, gamificada sem regra, gráfico decorativo, animação que compete com a ação. Não proponha design system novo.

### Produto

Para a tela: problema que resolve, valor, informação sobrando, informação faltando, decisão que o sistema já poderia tomar, função que mora no lugar errado. Separe problema real de ideia.

### Dados

Origem, endpoint, repository/provider, persistência, duplicação de conta, cálculo em dois lugares, dado estático no lugar de dado real, campo do BFF ignorado pelo parser.

### Performance

Requests no primeiro frame, duplicata, waterfall, payload, cache e invalidação, rebuild, lista, imagem, vídeo, animação. Não peça BFF novo se o BFF existe e a tela o ignora. Não peça cache novo se o bug é cache velho (Home do aluno e pagamento limpando cache são área quente).

### Segurança da tela

Autorização, IDOR/BOLA, tenant, deep link com id na URL, token em log, upload, saúde, pagamento. Só com caminho de código.

Telas que não podem ficar com scorecard raso, salvo se você provar que não existem:

- Splash, login, MFA, cadastro personal, cadastro aluno, convite, definir senha, esqueci senha
- Hoje do personal e Hoje do aluno
- Lista de alunos e Aluno 360 (três abas)
- Hub de treinos do aluno, prévia, execução, histórico, detalhe da sessão
- Biblioteca e editor de treino do personal
- Saúde e recovery
- Chat aluno e inbox do personal
- Financeiro dos dois papéis, mensalidade, recorrência
- Assinatura, review, success, paywall redirects
- Referral, convites
- Perfil dos dois papéis, exclusão de conta, MFA, white-label
- Agenda dos dois papéis
- Anamnese dos dois papéis
- Feed, broadcasts, notificações
- Leads, kanban, captura pública
- IA copiloto, chat IA, progressão
- Migração mágica
- Onboarding

As demais rotas da seção 6 entram no mapa e no scorecard compacto. Módulo sem rota também entra, como órfão ou infraestrutura.

---

## 9. Fluxos completos — não audite tela isolada

Reconstrua cada fluxo que o código implementar. Os nomes abaixo são exemplos obrigatórios **se existirem**, mais tudo o que você achar.

Para cada fluxo: diagrama em texto (A → B → C), etiqueta de status, elo quebrado, e quem mais deveria ver o mesmo fato (aluno, personal, Aluno 360, Home, job, push).

### Treino

Prescrição do personal → atribuição → hub do aluno → prévia → iniciar execução → série (carga, repetições, RPE, dor, feedback) → descanso → fila offline de séries → concluir / “já fiz” / confirmar restante → histórico semanal e detalhe → evolução, recordes, volume → Home do aluno → Hoje do personal / pulse → Aluno 360 (aderência, timeline, recordes).

Perguntas que o código tem de responder:

- A série pendente na fila local aparece como feita?
- Concluir com fila suja perde carga ou inventa carga?
- “Já fiz” no mesmo dia duplica execução? Há teste recente disso no backend — veja se a UI concorda.
- RPE e dor sobrevivem até o Aluno 360 ou morrem na execução?
- Descanso termina com o app em background? Há alerta de descanso; confirme permissão e limite de iOS.
- Check-in do personal (`/checkin`, sessão personal) é o mesmo modelo de dados?

### Saúde

Permissão → fonte (HealthKit / Health Connect) → sync → snapshot → recovery → Home, tab Saúde, widget, Aluno 360. Procure número estático, score local divergente, e dado de saúde em log ou analytics.

### Comunicação

Mensagem → REST e/ou STOMP → persistência → entrega → não lido no pulse da Home do personal → push FCM → leitura → histórico. Broadcast é outro fluxo. Feed é outro fluxo. Não os misture.

### Conta

Cadastro personal e aluno, Apple, Google, e-mail/senha, MFA TOTP, senha provisória do aluno, refresh, logout, denylist, troca de tenant/equipe, exclusão LGPD. Deep link `/convite/:token` e `/p/:slug` entram aqui.

### Dinheiro do personal (loja Apple / Play / web)

Trial → paywall → compra nativa → verify → entitlement → Home e gates. Em paralelo, o caminho web Mercado Pago e o webhook. Restore purchases. O que acontece com plano expirado, recibo atrasado, e jailbreak/dev-mode guard (`subscription_device_guard.dart`) — descreva o comportamento, não o contorne.

### Dinheiro do aluno

Mensalidade, PIX, recorrência, loja do personal, dunning, winback. Confirmação só vale com o estado que o backend considera pago (o glossário interno fala em captura aprovada, não em pré-autorização). Veja se a UI comemora cedo.

### Referral

Convite ou código → atribuição → cadastro → trial → pagamento real (IAP e/ou MP) → webhook ou verify → conversão → espera → recompensa → limite → estorno → histórico. Leia `docs/FOCUX_REFERRAL_*.md` e depois o código. O doc não fecha o achado.

### Aluno 360

Não assuma que a tela está certa porque o BFF existe. Primeiro paint usa bundles fatiados, não o `GET .../360` monolítico (há provider legado). Confirme o que cada aba mostra com dado produzido pelo aluno de verdade: treino, frequência, histórico, carga, volume, recorde, RPE, dor, saúde, recovery, consistência, chat, comportamento, pagamento, anamnese, equipamentos, autonomia. Aponte métrica sem fórmula, fórmula em dois lugares, e dado que o personal precisaria para decidir e que não chega.

### Outros fluxos que você deve procurar

Anamnese, agenda e lembrete, hábitos, desafios, trilhas, plano de sucesso, gamificação, ranking, NPS, depoimentos, galeria e fotos de evolução, feedback em vídeo, migração mágica (arquivo, planilha, OCR), grupo de aulas, automações, alertas, coach proativo, onboarding wizard, identidade e landing, captura de lead, equipe/RBAC, qualidade operacional, Focux Score, command center, upsell, cancel-save, enterprise promo, retenção/churn, relatórios, busca global, notificações in-app, widget de recovery, link universal e scheme `focux://`.

Se um fluxo não existir, escreva `AUSENTE` com a busca que você fez. Não o desenhe como roadmap nessa seção.

---

## 10. Auditoria de dados

Para cada família que existir, responda: é coletado, persistido, atualizado, calculado, onde é calculado, sobe ao backend, volta ao app, chega ao personal, chega ao Aluno 360, entra em alguma decisão, duplica, perde campo, ou existe e ninguém lê?

Famílias mínimas a procurar: aluno; treino prescrito; exercício; série; carga; repetições; RPE; dor; frequência; consistência; volume; evolução; recorde; medida corporal; foto; saúde; sono; passos; frequência cardíaca; recuperação; readiness; pagamento SaaS; mensalidade; recorrência; referral; mensagem; notificação; lead; agenda; financeiro; anamnese; hábito; desafio; NPS; feed; mídia; consentimento LGPD.

Destaque informação disponível no banco que a tela principal não usa, e informação na tela que não está no banco.

---

## 11. Duplicação

Procure o mesmo fato em Hoje, Treinos, Histórico, Evolução, Saúde, Perfil, Aluno 360, dashboard do personal, relatórios, ranking, gamificação, coach e insights.

Para cada repetição:

- qual superfície é a fonte
- onde basta resumo
- onde a repetição atrapalha
- se os números podem divergir (cache, cálculo local, janela de tempo, “já fiz” versus série)

Não recomende apagar bloco só porque repete. Diga o que o usuário decide em cada lugar.

A Home do aluno acabou de ser retrabalhada para tirar card duplo e atalho repetido. Verifique se o problema voltou ou mudou de lugar.

---

## 12. Órfãos e incompletos

Liste, com arquivo:

- endpoint sem consumidor no app
- tela sem rota ou rota sem entrada
- provider, repository ou model sem uso
- dependência nativa sem uso (candidato: pose ML Kit — confirme)
- módulo backend sem produto (candidatos a confirmar: alimentar 410, comunidade, outbox stub, campanhas internas, nfse, pose coach, export/backup, preapproval, `/api/hoje`)
- feature escondida por redirect (`/evolucao`, `/aluno/form-check`, `/alunos/acoes-massa`, `/planos`, `/paywall`, `/ia/checkin`)
- UI que chama API aposentada
- API pronta sem UI
- UI sem API
- integração pela metade

Redirect legado pode ser decisão consciente (esconder em vez de manter tela rasa). Não proponha reabrir rota escondida sem job. Não proponha apagar código de teste nem módulo 410 sem dizer o que quebra.

---

## 13. Design system

Audite a coerência com o sistema que já está no repositório. Objetivo: um Focux só, premium, claro, funcional, intencional.

Verifique no código, não no PDF imaginário: cor e contraste, tipo, espaço, raio, botão, input, card, sheet, dialog, gráfico, estado vazio/erro/loading, ícone, dock, motion, safe area, teclado, voltar.

Regras já escritas em `docs/FOCUX_DESIGN_REFERENCE.md` que você deve checar se o código cumpre — e sinalizar se o doc e o código brigam:

- pele constante, anatomia conforme o tipo S1–S9
- chevron empurra rota; ação primária não é disfarçada de linha de ajustes
- quatro estados
- voltar previsível (`safePopOrGo` versus pop cru)
- teclado iOS sem freeze
- capability de plano, não string mágica de plano
- orçamento de destaque: uma ação principal

Não redesenhe a marca. Não peça ilustração nova. Não peça gamificação extra se a tela já compete consigo mesma.

---

## 14. Performance

Baseie no código. “Trocar para arquitetura X” só entra se você mostrar o custo atual.

Flutter: startup e splash, primeiro frame da Hoje dos dois papéis, primeiro frame do Aluno 360, navegação entre tabs, rebuild de provider, listas longas (alunos, exercícios, histórico, chat), imagem e vídeo (Cloudinary, biblioteca, feedback), memória da execução de treino, animação (Rive, flutter_animate), serialização dos BFF, ETag/304, caches de Home e de Aluno 360, fila de séries.

Backend: query da Home do personal, Home do aluno, 360, check-in, chat, financeiro. N+1, payload, índice, cache Caffeine/Redis e invalidação, open-in-view, concorrência da fila de séries e do webhook, job que corre à toa (o outbox já reduziu frequência por causa de lock — entenda antes de sugerir cron novo).

Pergunte: o BFF existe e a tela ainda busca o sidecar? O cache de 60–90s mente depois de um treino ou de um pagamento? Há métrica Micrometer (`focux.dashboard.home`, `focux.aluno.360` ou outras) que cubra o caminho quente?

---

## 15. Segurança

Audite o que está implementado, não um checklist OWASP genérico. Para cada controle: existe, é parcial, ou não foi encontrado. Arquivo obrigatório.

Procure de verdade:

- JWT (access, refresh, rotação, logout, denylist, JTI)
- MFA e senha provisória
- Apple e Google sign-in: o que o backend valida
- RBAC e o que acontece se o cliente mentir o recurso
- tenant: `TenantContext`, `findByIdAndPersonalId`, membro de equipe, RLS/`RlsSecurityGuard` — confirme se RLS é obrigatório no Postgres que vocês usam ou só um guard condicional
- IDOR em `/alunos/:id`, chat, evolução, financeiro, saúde do aluno visto pelo personal, timeline, uploads
- deep link e universal link: token de convite, slug, open redirect
- STOMP: inscrição em tópico de outro usuário
- webhook Mercado Pago, IAP e Terra: assinatura, replay, idempotência
- `Idempotency-Key` e a fila de séries (replay duplica execução?)
- rate limit com e sem Redis
- Turnstile na captura pública
- logs com PII, saúde, token, recibo
- armazenamento local: Keychain, SharedPreferences da fila de séries e do cache de plano, fila offline genérica
- uploads e Cloudinary (SSRF / URL controlada pelo cliente)
- mass assignment em DTOs de aluno, treino e check-in
- dados de saúde e LGPD
- actuator e OpenAPI em produção (quem é ADMIN)
- antifraude já existente (jailbreak no checkout, device guard) sem transformá-lo em bypass
- concorrência: duas conclusões de treino, dois webhooks, refresh paralelo

Não escreva exploit, payload, nem passo a passo de ataque. Descreva o controle que falta e o impacto. Segredos, DSN, client id e recibo não entram no relatório; cite o arquivo de config e diga se o valor está hardcoded.

Endpoints administrativos e de QA: diga se o binário de release e o profile de produção os expõem.

---

## 16. Apple App Store

Não diga que está conforme. Onde faltar evidência no projeto, a etiqueta é `VALIDAR ANTES DA SUBMISSÃO`.

Releia no tree, não neste prompt:

- bundle id, versão de marketing, build number, nome de exibição
- signing, entitlements, capabilities, associated domains, app group, widget extension
- `Info.plist` e purpose strings (câmera, fotos, microfone, reconhecimento de fala, Face ID, Health share/update)
- `PrivacyInfo.xcprivacy` e se o binário declara os dados que o código realmente coleta (conta, saúde, fotos, vídeo, identificadores de push, compra)
- tracking (`NSUserTrackingUsageDescription`, ATT): confirme ausência ou presença
- Sign in with Apple ao lado de Google e e-mail
- compras: produtos em `Products.storekit` versus os ids que o app pede e o backend reconhece; restore; conteúdo digital não vendido por fora no iOS (a política de `kIsWeb` versus loja nativa)
- exclusão de conta dentro do app
- privacidade, termos, consentimento, suporte — links reais, não placeholder
- deep link / universal link e o `apple-app-site-association` servido pelo backend (`DeepLinkController`, `/.well-known/`)
- splash, ícone, orientação, safe area
- Dynamic Type: o clamp de `textScaler` em `main.dart` contra as telas que acabaram de corrigir fonte grande
- VoiceOver: semântica dos controles da execução de treino e do dock
- offline: fila de séries e o que mais mente sucesso
- crashes: Crashlytics ligado em release? Firebase plist real não deve estar no git
- erros, loading, vazio
- `ITSAppUsesNonExemptEncryption`
- permissões pedidas cedo demais, ou declaradas e não usadas (pose, microfone, fala) — motivo clássico de rejeição e de review de privacidade
- login obrigatório: o app é para personal e aluno; confirme se a review consegue entrar (conta demo é `NECESSITA VALIDAÇÃO`, não invente credencial)
- backend de produção apontado por dart-define, não por URL de debug no binário

Pontos de atenção para rejeição devem citar a capability do código (Health, IAP, conta, Sign in with Apple, purpose string, UGC de chat/feed/foto). Não cite guideline de memória se você não conferiu o comportamento.

Android pode aparecer como paridade (Health Connect, Play Billing), mas o alvo desta auditoria de loja é a Apple. Não dilua.

---

## 17. Testes

O humano citou cerca de 3.979 testes. Isso não é cota nem fato eterno. Reconte no HEAD: arquivos `*_test.dart`, `test()`/`testWidgets()`, classes Java de teste, `@Test`. Na leitura que originou este prompt, a ordem de grandeza era de centenas de arquivos no app e centenas de classes no backend, com milhares de métodos somados — e o número muda a cada commit (a Home e o check-in ganharam testes novos).

É proibido sugerir apagar teste para facilitar mudança.

Classifique a rede que existe:

- contrato de router e de repositories
- widget/polish
- regras puras (fila de séries, histórico por semana, Home do aluno, recovery, referral, RBAC, IDOR, webhook)
- `integration_test` (havia um smoke curto)
- E2E Playwright em `e2e/` — isso é Flutter web com backend, não XCUITest do iOS
- testes gerados em `focux-backend/tool/`
- piso de cobertura JaCoCo, se o `build.gradle` ainda o declara

Aponte buraco que importa para lançamento, não porcentagem abstrata:

- fila de séries versus concluir treino versus Aluno 360
- IAP verify e webhook (sem segredo real no git)
- isolamento de tenant
- Home do aluno no contrato novo
- exclusão de conta
- saúde: permissão negada, sync parcial
- pagamento do aluno marcado pago só na UI

Aponte teste que não representa o comportamento atual (parser de campo legado removido, rota redirect, widget de pose que o teste só garante que não existe). Teste frágil entra como risco de regressão, não como lixo.

---

## 18. Observabilidade e produção

Pergunta única, respondida com ferramenta concreta ou com “não há”:

“Se isso quebrar amanhã em produção, dá para saber o que aconteceu?”

Cubra: Crashlytics, Sentry do backend, logs com request id, métrica, tracing, health público versus actuator, alerta (se não houver config de alerta no repo, diga que o alerta não está no código), erro de API engolido pelo cliente, fila de séries que não sobe, webhook que falha depois do 200, job ShedLock, FCM que não registra, sync de saúde, pagamento aprovado sem entitlement.

Não proponha stack nova (Datadog, Kafka, segundo APM) se o buraco é “o evento existe e ninguém olha” ou “o log leva PII”.

---

## 19. Julgamento de produto

Para cada funcionalidade descoberta, julgue valor, clareza, frequência, fricção, necessidade e ligação com o resto. O lançamento é um personal real com alunos reais, na App Store, com treino que não perde série, dinheiro que não mente, e uma visão do aluno que usa o dado que o aluno produziu.

Separe cada achado em exatamente um balde:

1. problema real
2. melhoria necessária para o lançamento
3. melhoria opcional
4. funcionalidade nova
5. scope creep

Funcionalidade nova sem problema observado no código ou no fluxo cai em scope creep.

Não sugira rede social, marketplace, dieta, pose coach, hardware, ou i18n de três idiomas só porque o ARB `en`/`es` existe ou porque um módulo Java existe. O ADR e o `Locale('pt')` são evidência de produto Brasil-first até você provar o contrário. PIX, NFS-e e copy em português fazem parte do contexto; não internacionalize o lançamento.

---

## 20. Prioridade

O resultado não é uma lista infinita. Cada item tem: título, balde da seção 19, evidência (arquivo, símbolo, rota ou endpoint), impacto no usuário ou no dado, e dependência.

### P0 — crítico antes de produção

Compromete segurança, dado, pagamento, autenticação, estabilidade, integridade do treino, publicação, ou o fluxo principal (entrar, treinar, ver o aluno, cobrar com honestidade).

### P1 — necessário para o lançamento

A experiência de produção fica frágil ou confusa sem isso, mas não é um furo de integridade.

### P2 — alto valor depois

Importante e já evidenciado, sem bloquear a primeira versão da loja.

### P3 — futuro

Ideia ou expansão. Fica fora do escopo imediato.

Se você não tem evidência, o item não sobe de `NECESSITA VALIDAÇÃO` para P0.

---

## 21. Não construir agora

Seção obrigatória do relatório. Entram itens que:

- não são necessários para o lançamento
- aumentam muita complexidade
- não têm evidência de necessidade
- podem esperar
- colocam a submissão em risco

Candidatos que você deve julgar e, se a evidência for fraca, colocar aqui em vez de no P0: reativar pose coach; ligar comunidade; implementar consumer de outbox/Kafka; Stripe ou RevenueCat paralelos ao IAP; i18n en/es; novo design system; reabrir form-check e dieta; dashboard analítico novo; gamificação adicional; automações novas; white-label além do que já está shippable. Você pode discordar, desde que mostre o job de usuário e o buraco atual.

O objetivo é um produto excelente e finito.

---

## 22. O que é 10/10

10/10 não é “mais bonito”. É: não há gap relevante conhecido que comprometa experiência, funcionamento, segurança, dados ou lançamento.

Para cada fluxo crítico (auth, Hoje aluno, Hoje personal, execução de treino incluindo fila, histórico, Aluno 360, saúde, chat, assinatura/IAP, mensalidade do aluno, referral, exclusão de conta), defina critérios verificáveis do tipo:

- job principal óbvio
- dado correto e com uma fonte
- backend integrado no caminho feliz e no erro
- loading, vazio e erro
- offline honesto onde a rede falta (a fila não finge que o servidor gravou)
- acessibilidade mínima do fluxo (alvo de toque, escala, rótulo)
- performance do first paint sem waterfall acidental
- autorização e tenant
- feedback de sucesso e de falha
- teste que protege o comportamento, ou buraco de teste nomeado
- ligação com a outra ponta (aluno ↔ personal) explícita
- sem segunda verdade numérica
- comportamento igual ao resto do Focux

Uma tela está pronta quando esses critérios que se aplicam a ela estão verdadeiros no código, não quando a pele foi trocada.

---

## 23. Evidência

Cada achado cita pelo menos um de: arquivo, classe, função, rota, endpoint, provider, repository, model, migração, widget, teste.

Formato curto:

`ACHADO — etiqueta — evidência — impacto — prioridade`

Proibido:

- inventar tela, métrica, integração ou bug
- tratar TODO como feature
- tratar spec como implementação
- tratar este snapshot como revalidação
- copiar auditoria antiga (`FOCUX_PERFORMANCE_AUDIT.md`, auditoria de experiência do aluno, AUDIT.md) sem reler o código que ela aponta
- colar segredo, token, e-mail real, id de cliente OAuth, plist Firebase, ou connection string

Quando o código não fecha a questão (ambiente de produção, review da Apple, comportamento de HealthKit num aparelho, webhook com credencial real): `NECESSITA VALIDAÇÃO` ou `VALIDAR ANTES DA SUBMISSÃO`.

---

## 24. Forma do relatório

Entregue nesta ordem. Seções vazias não existem: escreva `NADA ENCONTRADO` e a busca.

1. **Inventário completo do produto** — mapa real, com etiquetas.
2. **Mapa de telas** — todas as rotas e as telas sem rota.
3. **Mapa de fluxos** — os que você reconstruiu.
4. **Arquitetura App ↔ Backend** — como o dado anda.
5. **Auditoria tela por tela** — scorecards; narrativa só no que muda prioridade.
6. **Auditoria fluxo por fluxo** — elos quebrados.
7. **Auditoria de dados** — origem → cálculo → persistência → consumo, inclusive Personal ↔ Aluno.
8. **Auditoria de performance.**
9. **Auditoria de segurança.**
10. **Auditoria de App Store** — confirmado no código, pendente, validar antes da submissão.
11. **Auditoria de testes** — buracos críticos; o que não apagar.
12. **Funcionalidades órfãs.**
13. **Duplicações.**
14. **P0**
15. **P1**
16. **P2**
17. **P3**
18. **Não construir agora**
19. **Plano de execução** — ordem por dependência técnica e impacto, uma área por vez. Sem calendário de dias ou semanas. Cada passo diz o que prova que ficou pronto (teste existente a estender, contrato, fluxo). Não inclui patch.
20. **Definition of done** — critérios objetivos para chamar o produto de pronto para produção e para submissão. Inclui freeze: visual sozinho não autoriza loja.

Feche com uma lista curta do que você não conseguiu provar e por quê.

---

## 25. Plano de execução (o que o relatório deve conter, não o que você faz agora)

O plano recomendado descreve fases posteriores. Você não as executa.

Fase A. Esta auditoria.

Fase B. Implementação controlada, uma área por vez, numa sessão futura, começando pelo P0 que destrava os outros (em geral integridade de sessão, treino/fila, dinheiro, tenant — você confirma com o grafo de dependências real).

Depois de cada área, na sessão de implementação, não nesta: testes que já existem mais os que faltam para o comportamento, análise, integração app↔backend, regressão do fluxo vizinho. Não se apaga teste para a área caber.

Fase C. Auditoria final do mesmo roteiro, contra o código novo, procurando regressão de dado e de duplicação.

Fase D. QA de produção: ambiente real, compra sandbox, Health, push, link universal, exclusão de conta. O que depender de aparelho ou de conta Apple fica explícito como validação humana.

Fase E. Submissão. Itens `VALIDAR ANTES DA SUBMISSÃO` resolvidos ou assumidos por escrito.

---

## 26. Critério de pronto deste brainstorming

A sessão falhou se:

- você sugeriu UI antes de fechar o inventário
- alguma pasta de `lib/features/` ou de `com.focux.modules` não aparece
- Personal 360 foi tratado como tela própria sem você provar o widget
- um P0 não tem arquivo
- você propôs apagar testes
- você propôs implementação, diff ou PR
- você tratou as listas deste prompt como se fossem o produto inteiro
- você não separou SaaS, mensalidade do aluno e referral
- você não rastreou a série até o Aluno 360
- você afirmou conformidade com a Apple sem evidência
- você inventou problema que o código não mostra

A sessão está boa se um engenheiro consegue, só com o relatório, saber o que o Focux é, o que está partido, o que não deve ser construído, e a ordem segura de mexer depois — sem receber código nesta sessão.
