# FOCUX — PROMPT MESTRE PARA SUPERPOWERS → BRAINSTORMING

Auditoria 360º do Focux que está no código agora: experiência, software, dados, negócio, segurança, operação e prontidão para a Apple App Store.

Os repositórios são a fonte da verdade. Este texto não é o inventário. É a ordem para descobrir o produto, confrontar o que já se sabe, e entregar um plano fechado. Quando as implementações desse plano terminarem, o passo humano seguinte é testar no iPhone as telas que mudaram e enviar o binário para a Apple. Não sobra rodada de descoberta, nem lista de “considerações finais”.

---

## 0. O que você é nesta sessão

Pense ao mesmo tempo como Product Manager, UX Designer, UI Designer, Flutter Engineer, Backend Engineer, Software Architect, QA Engineer, Security Engineer, Performance Engineer, DevOps/SRE e especialista em publicação na Apple App Store.

Cada achado nasce do código, do contrato ou de um fluxo rastreado. Sem evidência, o achado não existe: marque `NECESSITA VALIDAÇÃO` e transforme isso num passo concreto do roteiro de celular ou da submissão. Não deixe pergunta aberta no fim.

O produto no binário iOS se chama Focux Personal. Um app Flutter, dois papéis, um backend Spring Boot multi-tenant:

- **Personal** — quem opera o negócio e acompanha alunos.
- **Aluno** — quem treina.

Não existe um terceiro app. Não existe superfície, módulo ou fluxo chamado Personal 360. Não use esse nome em lugar nenhum do relatório. A visão do personal sobre um aluno é o **Aluno 360** (`AlunoDetailScreen`, rota `/alunos/:id`). O hub do personal é o **Hoje** (`PersonalDashboardScreen`, rota `/dashboard/personal`), com o command center em `/dashboard/command-center/copiloto`.

---

## 1. Restrições absolutas desta sessão

Esta sessão é somente:

DESCOBRIR → ENTENDER → VALIDAR → QUESTIONAR → CONECTAR → PRIORIZAR → PLANEJAR.

É proibido:

- implementar, editar, refatorar, formatar ou gerar código
- alterar banco, migração, API ou UI
- apagar código ou teste
- enfraquecer teste para a mudança caber
- criar funcionalidade nesta sessão
- criar branch, commit ou pull request
- modificar o working tree
- entregar patch, diff ou snippet para colar

Leitura e busca são o trabalho. Se um comando gravaria arquivo, não rode.

O relatório é a resposta. Não grave o relatório no repositório.

A implementação descrita no plano não começa nesta sessão.

---

## 2. Onde está o produto

Audite os dois repositórios juntos. Tela sem endpoint, ou endpoint sem consumidor, é achado incompleto.

| Repositório | Papel | Branch |
|---|---|---|
| `focux-app` | Cliente Flutter (iOS, Android e web) | `main` |
| `focux-backend` | API, jobs, webhooks e páginas públicas servidas pelo backend | `master` |

O código desses trees é o produto atual. Não trate o workspace como checkout atrasado. Não condicione a auditoria a “se o HEAD mudou”.

A versão do app está em `focux-app/pubspec.yaml`: `1.2.1+133`. O README do app está desatualizado: ainda cita `1.2.1+92`. Esse é o documento velho. Não use o README como mapa de rotas, de stack ou de escopo. O router, o `pubspec.yaml` e os módulos é que mandam.

Dentro do backend existe `landing-web/` (Astro). Se o código publica essa superfície, ela entra no inventário. O README cita um repositório `focux-website` que não está neste workspace. O que depender dele fica como passo externo no roteiro de submissão, sem inventar o site.

### Documentos

Código vence documento. Leia os docs só depois do inventário independente, como confronto, nunca como prova de que a feature funciona:

- `focux-app/docs/FOCUX_DESIGN_REFERENCE.md`
- `focux-app/docs/system/*`
- `focux-app/docs/CONTRATO_APP_BACKEND.md`
- `focux-backend/docs/CONTRATO_APP_BACKEND.md`, `docs/SYSTEM.md`, `AUDIT.md`, `docs/adr/*`
- `focux-app/docs/FOCUX_PERFORMANCE_AUDIT.md`
- `focux-app/docs/FOCUX_STUDENT_EXPERIENCE_AUDIT.md`
- `focux-app/docs/FOCUX_REFERRAL_SYSTEM.md` e `FOCUX_REFERRAL_SECURITY.md`
- `focux-app/docs/superpowers/specs/*` e `docs/superpowers/plans/*`
- `focux-app/tools/audit/backend_endpoints.tsv`

Specs de Home do aluno, dados/insights e referral descrevem intenção. O código da Home, da prévia de treino, do “já fiz”, do histórico, da fila de séries, da anamnese no BFF e do cache é o que está shipado. Não redesenhe o que já está no código. Não marque spec como pronta porque o arquivo existe.

---

## 3. Regra de escopo

Nenhuma lista deste prompt é escopo fechado. Isso inclui rotas, telas, módulos, fluxos de exemplo, entidades, integrações e o snapshot da seção 6.

Essas listas não são a lista completa, a prioridade, as únicas telas nem as únicas integrações.

Nomes não bastam. Classe, rota, endpoint, arquivo, comentário, TODO ou model não provam feature. Classifique com evidência:

| Etiqueta | Significado |
|---|---|
| `IMPLEMENTADO` | Chega ao usuário, persiste, e o outro lado do contrato produz ou consome o dado |
| `PARCIAL` | Falta passo, estado, papel ou persistência |
| `INCOMPLETO` | O fluxo não fecha |
| `ÓRFÃO` | Código sem consumidor, sem rota ou sem efeito |
| `NÃO UTILIZADO` | Existe num lado e o outro não chama |
| `QUEBRADO` | O caminho existe e falha, perde dado ou mente para o usuário |
| `NECESSITA VALIDAÇÃO` | Depende de aparelho, loja, segredo ou ambiente. Vira passo do roteiro de celular ou da submissão, com o que observar e o que é aprovação |

Diferencie dado real, cálculo no cliente, cálculo no servidor, fallback estático, cache e texto de marketing.

Não atribua nota, estrela, percentual ou ranking a tela, fluxo ou módulo. O relatório lista gaps. “10/10” não é nota de tela. É o estado-alvo de prontidão da seção 22.

---

## 3.1 Ordem obrigatória de descoberta

Existe uma diferença importante entre:

A) descobrir o produto;

B) validar hipóteses sobre o produto.

Você deve fazer A antes de B.

Primeiro:

- percorra os repositórios
- descubra as features
- descubra as rotas
- descubra as telas
- descubra os módulos
- descubra os endpoints
- descubra as entidades
- descubra os fluxos
- descubra as integrações
- descubra os jobs
- descubra os webhooks
- descubra os mecanismos de persistência
- descubra os contratos App ↔ Backend
- descubra as superfícies públicas
- descubra os estados e comportamentos reais

Somente depois:

- use o snapshot da seção 6
- use os exemplos das seções seguintes
- use os documentos existentes
- use as hipóteses levantadas anteriormente

O resultado do inventário independente é a fonte de verdade da auditoria.

O snapshot não pode determinar o que será auditado.

Se o inventário independente descobrir algo que não aparece no snapshot, esse item tem prioridade de descoberta sobre o snapshot e deve ser auditado normalmente.

Se o inventário independente contradizer o snapshot, registre:

`SNAPSHOT INCORRETO → REAL NO HEAD → EVIDÊNCIA`

Não tente fazer o código se encaixar no snapshot.

Não deixe de analisar uma funcionalidade porque ela não aparece no snapshot.

Não deixe de analisar uma funcionalidade porque ela não aparece nas listas deste prompt.

O objetivo é descobrir o Focux que existe, não confirmar o Focux que alguém imaginou anteriormente.

Até o inventário independente estar escrito, é proibido abrir a seção 6, citar hipótese da seção 6.7, ou deixar uma lista deste prompt decidir se uma pasta entra ou fica de fora.

---

## 4. Passagens, depois da descoberta

A passagem A é a descoberta. As outras só começam com o inventário independente já escrito.

### Passagem A — inventário independente

App, lendo o tree, sem usar a seção 6:

- todo `GoRoute` em `lib/core/router/`
- `lib/core/screens/main_shell.dart`, `lib/core/screens/aluno_shell.dart`, `lib/core/widgets/fx_dock.dart`
- cada diretório de `lib/features/`
- sheets, dialogs e modais que não são rota
- providers, repositories, services, models
- `lib/core/api/`, `lib/core/storage/`, `lib/core/auth/`, `lib/core/fcm/`, `lib/core/health/`, `lib/core/config/env.dart`

Backend, lendo o tree:

- cada diretório de `src/main/java/com/focux/modules/`
- `src/main/java/com/focux/infra/` e `config/`
- mappings HTTP
- entidades, DTOs, Flyway em `src/main/resources/db/migration/`
- `@Scheduled`, listeners, publishers STOMP
- `SecurityConfig` e rotas públicas

Conte no tree. Não reutilize número deste prompt.

### Passagem B — confronto

Só agora abra a seção 6 e os docs. Para cada divergência, a linha `SNAPSHOT INCORRETO → REAL NO HEAD → EVIDÊNCIA`. O que o inventário achou e o snapshot não cita entra na auditoria com a mesma profundidade.

### Passagem C — rastro

Para cada fluxo que o inventário mostrou ser real:

tela → ação → provider → repository → API → controller → service → banco → resposta → estado → próxima tela → quem mais lê o mesmo fato (Hoje do aluno, Hoje do personal, histórico, evolução, Aluno 360, job, push)

Marque o primeiro elo quebrado, duplicado ou fictício.

### Passagem D — órfãos, duplicação, dado que mente

Endpoint sem caller, tela sem entrada, provider sem uso, model sem uso, flag, `kDebugMode`, redirect que esconde rota, HTTP 410, `@Deprecated`, dependência no `pubspec.yaml` sem uso em `lib/`, cálculo duplicado, fallback estático no lugar de medida.

### Passagem E — risco e plano fechado

Segurança, pagamento, auth, integridade do treino, saúde, App Store, testes, observabilidade. Depois o julgamento e a prioridade. Cada P0 e P1 sai como item de implementação com aceite. Cada verificação que só o aparelho faz sai no roteiro de celular. Nada fica para uma “fase seguinte de análise”.

---

## 5. Vocabulário do produto

Use os nomes do código. Não traduza para um nome que o produto não tem.

| No produto | Onde está |
|---|---|
| Hoje do personal | Dock “Hoje”. `PersonalDashboardScreen`, `/dashboard/personal`. BFF `GET /api/dashboard/home`. |
| Hoje do aluno | Dock “Hoje”. `AlunoDashboardScreen`, `/dashboard/aluno`. BFF `GET /api/dashboard/aluno/home`. |
| Aluno 360 | Visão do personal sobre um aluno. `AlunoDetailScreen`, `/alunos/:id`. Abas Operação, Evolução e Ferramentas. BFF `GET /api/alunos/{id}/360/operacao`, `/evolucao`, `/ferramentas`, mais timeline. |
| Command center | `/dashboard/command-center/copiloto`. |
| Treinos do aluno | Tab `/checkin/treinos`, `MeusTreinosScreen`. Prévia `/checkin/treino/:treinoId`, `TreinoPreviaScreen`. Execução `/checkin/executar`, `CheckinScreen`. |
| Série, RPE, dor | Módulo `checkin`. Backend: `ExecucaoTreino`, `ExecucaoExercicio`, `ExecucaoSerie`. |
| Saúde | Tab `/saude`. Módulo `health`. Widget iOS `ios/FocuxRecoveryWidget/`. |
| Assinatura do personal | Compra nativa com `in_app_purchase` e `POST /api/iap/verify`. Mercado Pago no checkout web do plano e na cobrança do aluno (PIX, recorrência, loja). Não há RevenueCat nem Stripe no código. Não proponha um deles. |
| Papéis | `PERSONAL` e `ALUNO`. Equipe e RBAC são permissão dentro do tenant. `Personal.isAdmin` não é um terceiro app. |

Copy de marketing que diga “360°” não cria outra tela. A tela é o Aluno 360.

---

## 6. Snapshot para confronto — só depois do inventário

Proibido usar esta seção para decidir o que auditar. Ela descreve o código atual para você confrontar com o inventário independente. Se bater, siga o inventário. Se não bater, registre `SNAPSHOT INCORRETO → REAL NO HEAD → EVIDÊNCIA` e audite o real.

### 6.1 Forma do app

- Pacote `focux_app`, versão `1.2.1+133` no `pubspec.yaml`.
- Estado: Riverpod. `ChangeNotifier` de plano de sucesso ainda existe no código; o inventário diz se a rota usa.
- HTTP: Dio em `lib/core/api/api_client.dart` (Bearer, ETag, retry, fila offline genérica). Dinheiro e IAP: `payment_api_client.dart`. Upload: `media_upload_service.dart`.
- URLs: `lib/core/config/env.dart`. Não copie segredo para o relatório.
- Navegação: GoRouter com redirect de auth e papel.
- Design system já existe. Não invente outro. Tema em `lib/core/theme/` (`design_tokens.dart`, `tokens_strip.dart`, `app_theme.dart`, tipografia, `fx_settings_layout.dart`). Motion em `lib/core/motion/focux_motion.dart`. Data viz em `lib/core/data_viz/focux_data_viz.dart`. Catálogo em `lib/core/design_system/`. Norma em `docs/FOCUX_DESIGN_REFERENCE.md`. Se o doc e o widget divergirem, o usuário vê o widget.
- Locale: `MaterialApp.router` usa `Locale('pt')` e `S.localizationsDelegates`. Existem ARB `pt`, `en` e `es`. O app não oferece troca de idioma. O ADR `focux-backend/docs/adr/002-brasil-first-sem-i18n.md` está alinhado com o locale fixo; o wiring do delegate é detalhe de implementação, não um produto trilíngue.
- `main.dart` limita `textScaler` (teto menor em telefone estreito). A Home do aluno também trata quebra de texto. O efeito no iPhone entra no roteiro de celular como `VALIDAR ANTES DA SUBMISSÃO`, com arquivo e linha do clamp.
- iOS: bundle `com.focux.focuxApp`, nome Focux Personal, Sign in with Apple, associated domains `focuxpersonal.com` e `www.focuxpersonal.com`, HealthKit, app group, `PrivacyInfo.xcprivacy`, `ios/Products.storekit`. Firebase real não entra no git; o que existe versionado é template `*.example`. Purpose strings de câmera, fotos, microfone, fala, Face ID e Health estão no `Info.plist`.

### 6.2 Shells

Personal, `MainShell`, dock: Hoje, Alunos, Treinos, Agenda, IA.

| Path | Tela |
|---|---|
| `/dashboard/personal` | `PersonalDashboardScreen` |
| `/alunos` | `AlunosListScreen` |
| `/treinos` | `TreinosListScreen` |
| `/agenda` | `AgendaScreen` |
| `/ia/copiloto` | `IaCopilotoScreen` |

Aluno, `AlunoShell`, dock: Hoje, Treinos, Saúde, Chat, Perfil. Na tab de chat o dock se esconde.

| Path | Tela |
|---|---|
| `/dashboard/aluno` | `AlunoDashboardScreen` |
| `/checkin/treinos` | `MeusTreinosScreen` |
| `/saude` | `HealthDashboardScreen` |
| `/chat/aluno` | `ChatAlunoScreen` |
| `/aluno/perfil` | `PerfilAlunoScreen` |

Atalhos: `/` é a splash. `/home`, `/dashboard` e `/dashboard/home` vão para o Hoje do papel. `/aluno` vai para o Hoje do aluno. `/personal` vai para o Hoje do personal. `/ia` vai para o copiloto.

### 6.3 Rotas públicas e de conta

`app_router_auth_routes.dart`: `/login`, `/login/mfa`, `/register`, `/register/aluno`, `/onboarding`, `/esqueci-senha`, `/resetar-senha`, `/resetar-senha/verificar-codigo`, `/p/:slug` (redirect para login de aluno com o slug), `/convite/:token`, `/aluno/definir-senha`.

`/qa/smoke` e `/qa/tokens-strip` só em debug. Release usa stub.

### 6.4 Rotas fora do dock

O inventário independente produz a tabela path → widget → papel → como se chega (dock, push, deep link, FCM ou só URL). A lista abaixo é o router atual, para confronto. Vários paths são redirect.

Aluno, além do dock: `/aluno/ativacao`, `/aluno/habitos`, `/aluno/habitos/:id`, `/aluno/desafios`, `/aluno/desafios/:id`, `/aluno/recorrencia`, `/aluno/grupo-aulas`, `/aluno/perfil/editar`, `/aluno/anamnese`, `/aluno/trilhas`, `/aluno/form-check` (redirect), `/evolucao` (redirect), `/feed/aluno`, `/financeiro/aluno`, `/agenda/aluno`, `/depoimentos-aluno`.

Demais rotas autenticadas:

- `/dashboard/qualidade`, `/dashboard/command-center/copiloto`
- `/alunos/novo`, `/alunos/acoes-massa` (redirect), `/alunos/:id`, `/alunos/:id/editar`, `/alunos/:id/equipamentos`, `/alunos/:id/relatorio`, `/alunos/:id/evolucao`, `/alunos/:id/plano-sucesso`, `/alunos/:id/fotos`, `/alunos/:id/anamnese`, `/personal/alunos/:id/anamnese` (redirect), `/alunos/:id/treinos-list`, `/alunos/:id/ia/progressao`, `/alunos/:id/chat`, `/alunos/:id/feedback-video`, `/alunos/:id/engajamento`, `/alunos/:id/evolucao-comparativo`, `/alunos/:id/trilhas`, `/alunos/:id/feedback-videos`
- `/treinos/novo`, `/treinos/:id`, `/treinos/:id/exercicios/add`, `/exercicios`, `/exercicios/novo`, `/exercicios/biblioteca-wizard`, `/exercicios/:id`, `/exercicios/:id/editar`
- `/checkin`, `/checkin/executar`, `/checkin/treino/:treinoId`, `/checkin/historico`, `/checkin/historico/:id`
- `/agenda/novo`, `/financeiro`, `/financeiro/mensalidades/:id`
- `/perfil`, `/configuracoes`, `/perfil/editar`, `/perfil/link-publico`, `/perfil/wallet`, `/perfil/ferramentas`, `/perfil/mfa`, `/identidade-visual`, `/white-label`, `/perfil/white-label`, `/setup/identidade`, `/perfil/equipe`, `/perfil/landing-editor`
- `/ia/chat`, `/ia/checkin` (redirect), `/ia/progressao/aceitar`, `/chat/inbox`
- `/feed`, `/leads`, `/leads/kanban`, `/kanban`, `/leads/novo`, `/leads/:id`, `/leads-publicos`
- `/alertas`, `/alertas/aluno/:id`, `/alertas/config`, `/relatorios/global`, `/relatorio/business`
- `/convites`, `/planos` e `/paywall` (redirect para `/assinatura`), `/assinatura`, `/assinatura/review`, `/assinatura/success`, `/referral`, `/retencao`, `/ofertas-upsell`, `/cancel-save`, `/dunning`, `/winback`, `/promo-enterprise`, `/migracao-magica`, `/migracao-focux`, `/growth/migracao`
- `/habitos`, `/habitos/:id`, `/automacoes`, `/desafios`, `/desafios/:id`, `/loja`, `/pacotes`, `/recorrencia`, `/nps`, `/grupo-aulas`, `/onboarding/wizard`
- `/ranking`, `/coach`, `/notificacoes`, `/suporte`, `/broadcasts`, `/depoimentos`, `/galeria`, `/feedback-videos`, `/busca`, `/analytics`, `/gamificacao`, `/ferramentas/hub/:itemId`, `/admin/rbac`

### 6.5 Módulos do app

`admin`, `agenda`, `alertas`, `alunos`, `analytics`, `anamnese`, `assinatura`, `auth`, `automacoes`, `avaliacao`, `broadcasts`, `busca`, `captura`, `chat`, `checkin`, `coach`, `convites`, `dashboard`, `depoimentos`, `desafios`, `dunning`, `evolucao`, `exercicios`, `feed`, `feedback`, `ferramentas`, `financeiro`, `galeria`, `gamificacao`, `growth`, `grupos`, `habitos`, `health`, `ia`, `leads`, `loja`, `monetizacao`, `notificacoes`, `nps`, `onboarding`, `pacotes`, `perfil`, `planos`, `plano_sucesso`, `pricing`, `qa`, `ranking`, `recorrencia`, `referral`, `relatorio`, `retencao`, `subscription`, `suporte`, `treinos`, `trilhas`, `winback`.

`subscription` e `pricing` não têm tela própria. O inventário diz quem os chama.

### 6.6 Módulos do backend

`agenda`, `alertas`, `alimentar`, `alunos`, `analytics`, `anamnese`, `auditoria`, `auth`, `automacoes`, `avaliacao`, `backup`, `brand`, `broadcast`, `busca`, `campanhas`, `captura`, `chat`, `checkin`, `coach`, `comunidade`, `convites`, `dashboard`, `depoimentos`, `desafios`, `dunning`, `engajamento`, `evolucao`, `exercicios`, `exportacao`, `fcm`, `feed`, `feedback`, `ferramentas`, `financeiro`, `galeria`, `gamificacao`, `growth`, `grupos`, `habitos`, `health`, `ia`, `iap`, `leads`, `lgpd`, `loja`, `monetizacao`, `nfse`, `notificacoes`, `nps`, `onboarding`, `pacotes`, `pagamentos`, `personal`, `planos`, `planosucesso`, `posecoach`, `pql`, `pricing`, `ranking`, `rbac`, `recorrencia`, `referral`, `relatorio`, `retencao`, `suporte`, `sync`, `templates`, `treinos`, `trilhas`, `upload`, `webhooks`, `winback`.

Flyway está em `src/main/resources/db/migration/`. Conte no tree.

O padrão do produto é CRUD mais BFF `*/home` para o first paint. A auditoria diz se a tela ainda dispara sidecar que anula o BFF.

Peças atuais do contrato de treino e da Home do aluno, para confronto com o inventário: `CheckinPreviaService`, bundles da Home do aluno (anamnese, insight, volume, agenda condicionada ao plano), NPS.

### 6.7 Comportamentos atuais para confrontar

Não promova nenhuma linha a P0 sem o rastro da passagem C. Se o inventário mostrar outra coisa, o inventário vence.

1. **Duas filas no treino.** `OfflineSyncService.isSensitivePath` exclui `/checkin`, e também chat, anamnese, health, lgpd, wallet, mensalidade, pagamento, financeiro, auth, alunos, leads, perfil, ia, comunidade, fcm e upload. A execução tem outra fila: `CheckinSeriesPendentesStore`, `checkin_series_fila.dart`, `CheckinFilaSync`, `checkin_fila_sync_scope.dart`. A série pendente guarda carga, repetições, RPE, dor e feedback e reenvia com `registrarSerie`. 4xx sai da fila. 5xx, 401, 408, 429 e falha de rede ficam. O backend, em `CheckinService`, não inventa carga ao confirmar o restante. Rastreie concluir com pendência, reabrir sessão, “já fiz” no mesmo dia, o que o Hoje e o Aluno 360 mostram antes do envio, e o que o personal vê.
2. **Hub e prévia.** `MeusTreinosScreen` é hub. `TreinoPreviaScreen` é a prévia, com rodízio e “já fiz” sem exigir séries. Não descreva a tab Treinos como lista antiga.
3. **Home do aluno.** `GET /api/dashboard/aluno/home` é o contrato vigente, sem os campos legados removidos. Cruze `AlunoDashboardHomeResponse` com o parser Dart. Insight, coach, meta, recorde, anamnese, agenda com horário, NPS adiado e cache são o mesmo fluxo.
4. **Recovery.** Cliente: `lib/core/health/recovery_score.dart`. Servidor: módulo `health`, `POST /api/aluno/saude/sync`, `GET /api/aluno/saude/recovery`, BFF e Aluno 360. Diga qual número a UI mostra antes do sync, depois, offline, e na tela do personal. O widget iOS entra no rastro.
5. **Terra e Health.** O backend tem webhook Terra. O app sincroniza Apple Health e Health Connect. Classifique se Terra altera o que o usuário vê.
6. **Biblioteca.** `kBibliotecaLibraryVideosStandby` em `lib/features/exercicios/services/biblioteca_media_config.dart` é `true`. Mídia MoveKit já publicada no Cloudinary continua na prévia. Sem mídia publicada, não abre sheet “em breve”.
7. **Pose.** Não há painel de pose no app. `google_mlkit_pose_detection` está no `pubspec.yaml`. O backend tem o módulo `posecoach`. Classifique os três. Não proponha reativar pose.
8. **Comunidade e `/api/hoje`.** `api_client.dart` cita os dois paths em cache. Não há repository de comunidade no app. `ComunidadeController` existe. `/api/hoje` não tem mapping. Grupo de aulas é `/api/grupo-aulas`.
9. **Alimentar.** O módulo responde 410. Não há dieta no produto.
10. **Listas cruas.** Analytics e agenda aposentaram lista crua em favor de `*/home`, com 410 no caminho velho. Veja se o app ainda chama o velho.
11. **Outbox.** `OutboxProcessorJob` marca o evento como `PROCESSADO` depois de log. Não há consumer externo. Não proponha Kafka.
12. **Três dinheiros.** SaaS do personal (IAP no nativo; preferência Mercado Pago quando `kIsWeb`). Mensalidade do aluno (PIX, recorrência, webhook). Loja/pedido. `POST /api/pagamentos/preapproval/{planoId}` não é chamado pelo app. Referral converte em pagamento real: rastreie IAP e Mercado Pago até o ledger.
13. **IAP sem segredo.** O verifier muda de comportamento quando o segredo de produção não está configurado. Descreva o que o código faz. O efeito em produção entra no roteiro de submissão, sem afirmar que recibo falso passa.
14. **Restore e exclusão.** `restorePurchases` está na assinatura. Exclusão dos dois papéis: `DELETE /api/lgpd/me/delete` (`aluno_delete_account.dart` e o perfil do personal). Diga o que o servidor apaga. O gesto no iPhone entra no roteiro.
15. **Suporte.** `/suporte` abre a web. `ApiClient` envia `POST /api/suporte/analisar-erro` para o personal em erro de transporte. Separe o que a pessoa vê do que o app dispara.
16. **Referral.** A UI chama `GET /api/referral`. Atribuição, conversão, limite e estorno estão no backend. `GET /api/referral/validar/{codigo}` não é chamado pelo app.
17. **Export e backup.** Exportação e backup de tenant aparecem no catálogo de QA. O caminho do titular é `/api/lgpd/me`.
18. **Entitlement.** Sem rede, o app usa mapa estático de capabilities e cache local. Diga se a feature abre ou fecha. A regra do produto é capability, não `plano == 'FREE'`.
19. **NFS-e, campanhas, PQL, pricing.** Existem no backend. A auditoria diz se algum tem tela. Não viram escopo de loja por existir classe.
20. **Marca e páginas públicas.** Identidade, editor de landing, `/p/`, `/c/`, `/landing/`, HTML de convite. Fazem parte do que um aluno vê antes da conta.
21. **Tempo real.** Chat usa STOMP em `{ws}/ws/websocket`, tópico por personal e por aluno. O handshake de `/ws/**` é público; o JWT entra no CONNECT. Push de produto é FCM mais o centro `/notificacoes`. Não há WebSocket de dashboard.
22. **Sinal de produção.** Funil `POST /api/analytics/evento`. Crashlytics no app. Sentry no backend, com DSN opcional. Diga se uma série presa na fila ou um pagamento sem entitlement deixa rastro.
23. **RBAC.** Tela `/admin/rbac` e membros em `/api/tenant/membros`. A autorização que importa é a do backend quando o cliente mente o recurso.
24. **Escala de texto.** Clamp em `main.dart` e o layout da Home do aluno. O iPhone pequeno confirma no roteiro, com o arquivo citado.

---

## 7. O que publicar antes de qualquer gap

Com o inventário independente, e só então o confronto:

1. Módulos dos dois repositórios, com etiqueta.
2. Telas: path, widget, papel, como se chega, redirect ou tela, tipo S1–S9 quando o design system já classifica.
3. Sheets e dialogs que não são rota, com a tela dona.
4. Fluxos ponta a ponta.
5. App ↔ Backend: BFF do first paint, sidecar, ETag, fila genérica versus fila de séries, STOMP, FCM, webhook que o app não chama.
6. Entidades que o usuário produz: Personal e Aluno, treino prescrito, execução e série, medida, foto, recorde, mensalidade, recorrência, plano SaaS e validade, referral, chat, agenda, snapshot de saúde, anamnese.

Descreva a arquitetura que o código executa. Não desenhe outra.

---

## 8. Auditoria de cada tela do inventário

Toda tela que o inventário encontrou entra. Tela que só está na seção 6 e o inventário não encontrou não é inventada de volta. Tela que o inventário encontrou e a seção 6 omitiu entra do mesmo jeito.

### Não transformar o scorecard em nota

Não atribua notas numéricas, estrelas, percentuais ou rankings às telas.

“10/10” representa apenas o estado-alvo de prontidão definido na seção 22.

Uma tela pode estar visualmente excelente e ainda possuir um gap P0 de dados, segurança ou integração.

Da mesma forma, uma tela simples pode estar pronta sem precisar receber novas funcionalidades.

O objetivo é identificar gaps concretos, não produzir uma pontuação subjetiva.

Para cada tela, só gaps. Se não houver gap, escreva `SEM GAP RELEVANTE` e a evidência do job, do dado e dos estados. Não escreva elogio.

Campos do gap, quando existir:

- job da tela e ação primária
- origem do dado (endpoint, repository, cache ou constante)
- campo que o backend tem e a tela não mostra
- valor que a tela mostra sem origem
- estado que falta: loading, vazio, erro, offline, sucesso, primeira vez, retorno
- inconsistência com o design system existente, se mudar o que a pessoa consegue fazer
- autorização, tenant, saúde, pagamento ou sessão, se a tela lê ou grava isso

UX, UI, produto, dado, performance e segurança entram como gap com arquivo, não como capítulo genérico por tela. “Deixar mais bonito” não é gap.

UI usa a pele que já existe. Aponte tela que virou outro produto: card sem job, métrica sem decisão, motion que compete com a ação, safe area, contraste, tipo. Não proponha design system novo.

Fluxos que o inventário marcar como caminho principal (entrar, Hoje dos dois papéis, Aluno 360, treino da prescrição até o personal ver a série, saúde, chat, os três dinheiros, referral, exclusão de conta) ganham o rastro completo da seção 9, não um parágrafo solto.

---

## 9. Fluxos do inventário

Reconstrua os fluxos que o código implementa. Os títulos abaixo são exemplos do que procurar no inventário, não a lista fechada. Fluxo ausente no código: `AUSENTE` e a busca. Não vira roadmap.

Para cada fluxo real: cadeia em texto, etiqueta, elo quebrado, e quem mais lê o mesmo fato.

### Treino

Prescrição → atribuição → hub do aluno → prévia → execução → série (carga, repetições, RPE, dor, feedback) → descanso → fila de séries → concluir, “já fiz” ou confirmar restante → histórico → evolução, recorde, volume → Hoje do aluno → Hoje do personal → Aluno 360.

O código tem de responder: a série ainda na fila aparece como feita; concluir com fila suja perde ou inventa carga; “já fiz” no mesmo dia duplica execução; RPE e dor chegam ao Aluno 360; o descanso acaba com o app em background; o check-in do personal em `/checkin` usa o mesmo modelo.

### Saúde

Permissão → HealthKit ou Health Connect → sync → snapshot → recovery → Hoje, tab Saúde, widget, Aluno 360. Número estático, score local diferente do servidor, e saúde em log são gaps.

### Comunicação

Mensagem → REST e STOMP → persistência → entrega → não lido no Hoje do personal → FCM → leitura. Broadcast é outro fluxo. Feed é outro fluxo.

### Conta

Cadastro dos dois papéis, Apple, Google, e-mail, MFA, senha provisória do aluno, refresh, logout, denylist, equipe, exclusão. Deep link `/convite/:token` e `/p/:slug`.

### SaaS do personal

Trial → `/assinatura` → compra nativa → verify → entitlement → gates do Hoje. Caminho web Mercado Pago e webhook, em separado. Restore. Plano expirado. O guard de dispositivo em `subscription_device_guard.dart` é comportamento a descrever, não a contornar.

### Dinheiro do aluno

Mensalidade, PIX, recorrência, loja, dunning, winback. A UI só trata como pago o estado que o backend trata como pago.

### Referral

Código ou convite → atribuição → cadastro → pagamento real → conversão → limite → estorno → histórico na tela `/referral`.

### Aluno 360

O first paint usa os três bundles, não o `GET .../360` monolítico. Diga o que cada aba mostra a partir do que o aluno produziu: treino, frequência, histórico, carga, volume, recorde, RPE, dor, saúde, recovery, consistência, chat, pagamento, anamnese, equipamentos. Métrica sem fórmula, duas fórmulas, e dado necessário para decidir que não chega são gaps.

### O restante que o inventário achar

Anamnese, agenda, hábitos, desafios, trilhas, plano de sucesso, gamificação, ranking, NPS, depoimentos, fotos, feedback em vídeo, migração mágica, grupo de aulas, automações, alertas, coach, onboarding, landing, captura, RBAC, qualidade operacional, Focux Score, command center, upsell, cancel-save, retenção, relatórios, busca, notificações, widget, universal link e scheme `focux://`.

---

## 10. Dados

Para cada família que o inventário encontrar: é coletado, persistido, atualizado, calculado, onde, sobe, volta, o personal vê, o Aluno 360 vê, alguma decisão usa, duplica, perde campo, ou ninguém lê?

Famílias que o código tem e que a passagem A deve localizar: aluno, treino, exercício, série, carga, repetições, RPE, dor, frequência, consistência, volume, evolução, recorde, medida, foto, saúde, sono, passos, frequência cardíaca, recovery, pagamento SaaS, mensalidade, recorrência, referral, mensagem, notificação, lead, agenda, anamnese, hábito, desafio, NPS, feed, mídia, consentimento.

Dado no banco que a tela principal ignora, e dado na tela que não está no banco, são gaps.

---

## 11. Duplicação

O mesmo fato em Hoje, Treinos, Histórico, Evolução, Saúde, Perfil, Aluno 360, relatórios, ranking, gamificação, coach e insights.

Para cada repetição: qual tela é a fonte, onde basta resumo, onde a repetição atrapalha, e se os números podem divergir (cache, cálculo local, “já fiz” versus série).

Não peça para apagar bloco só porque repete. Diga a decisão que a pessoa toma em cada lugar.

---

## 12. Órfãos e incompletos

Com arquivo:

- endpoint sem consumidor
- tela sem rota, ou rota sem entrada
- provider, repository ou model sem uso
- dependência sem uso em `lib/`
- módulo backend sem efeito no app
- redirect que esconde rota (`/evolucao`, `/aluno/form-check`, `/alunos/acoes-massa`, `/planos`, `/paywall`, `/ia/checkin`, e os que o inventário achar)
- UI em API 410
- API sem UI
- UI sem API

Redirect pode ser decisão de esconder tela rasa. Não reabra rota escondida sem job no código atual. Não apague teste nem módulo 410 no plano, a menos que o item diga o que quebra e por que o lançamento exige isso.

---

## 13. Design system

Audite contra o sistema do repositório. Um Focux só: claro, funcional, intencional.

No código: cor, contraste, tipo, espaço, raio, botão, input, card, sheet, dialog, gráfico, estados, ícone, dock, motion, safe area, teclado, voltar.

O `docs/FOCUX_DESIGN_REFERENCE.md` já exige pele constante, anatomia S1–S9, chevron para push, ação primária que não se disfarça de linha de ajuste, quatro estados, `safePopOrGo`, teclado sem freeze, capability em vez de `plano == 'FREE'`, uma ação principal. Onde o widget descumpre, é gap. Onde o doc e o widget discordam, vale o widget, e o gap é a divergência se ela muda o comportamento.

Não redesenhe a marca. Não peça ilustração. Não peça gamificação nova.

---

## 14. Performance

Só com custo visível no código.

Flutter: splash, primeiro frame dos dois Hoje, primeiro frame do Aluno 360, troca de tab, rebuild, lista de alunos, exercícios, histórico e chat, imagem e vídeo, memória da execução, animação, parse do BFF, ETag, cache da Home e do Aluno 360, fila de séries.

Backend: Home do personal, Home do aluno, Aluno 360, check-in, chat, financeiro. N+1, payload, índice, cache e invalidação, open-in-view, corrida da fila com o webhook, job que não faz trabalho de produto.

Gap típico a confirmar no código: BFF existe e a tela ainda busca sidecar; cache da Home mente depois de treino ou pagamento.

---

## 15. Segurança

Para cada controle: presente, parcial ou ausente, com arquivo.

- JWT, refresh, rotação, logout, denylist
- MFA e senha provisória
- validação de Apple e Google no backend
- RBAC quando o cliente mente
- tenant: `TenantContext`, `findByIdAndPersonalId`, membro de equipe, `RlsSecurityGuard`
- IDOR em aluno, chat, evolução, financeiro, saúde, timeline, upload
- convite, slug e open redirect
- STOMP em tópico de outra pessoa
- webhook Mercado Pago, IAP e Terra: assinatura, replay, idempotência
- fila de séries e replay
- rate limit com e sem Redis
- Turnstile na captura
- log com PII, saúde, token ou recibo
- Keychain, fila de séries, cache de plano
- upload e URL de mídia
- DTO de aluno, treino e check-in
- saúde e LGPD
- actuator e OpenAPI em produção
- guard de dispositivo no checkout, descrito sem virar bypass
- duas conclusões de treino, dois webhooks, refresh paralelo

Não escreva exploit nem payload. Segredo não entra no relatório. Diga se QA ou actuator ficam no binário de release.

---

## 16. Apple App Store

Não afirme conformidade. O que o código não prova vira item do roteiro de celular ou da ficha de submissão, com a etiqueta `VALIDAR ANTES DA SUBMISSÃO` e o passo exato.

Leia no tree:

- bundle, versão `1.2.1+133`, build, nome
- entitlements, associated domains, app group, widget
- purpose strings e `PrivacyInfo.xcprivacy` contra o que o código coleta
- tracking e ATT, presentes ou ausentes
- Sign in with Apple junto de Google e e-mail
- ids em `Products.storekit`, no app e no backend; restore; plano digital no iOS só pela loja
- exclusão de conta dentro do app, nos dois papéis
- links de privacidade, termos e suporte
- `apple-app-site-association` no backend
- ícone, splash, orientação, safe area
- clamp de `textScaler` e VoiceOver da execução e do dock
- fila de séries e qualquer sucesso mentiroso
- Crashlytics em release, sem plist Firebase no git
- `ITSAppUsesNonExemptEncryption`
- permissão declarada e não usada
- URL de API de release via dart-define, não host de debug no binário

Rejeição possível só com a capability que o código liga: Health, IAP, conta, Sign in with Apple, purpose string, conteúdo de chat, feed e foto.

Android fica como paridade de Health Connect e Play Billing quando o mesmo código ramifica. O alvo da loja desta auditoria é a Apple.

---

## 17. Testes

Reconte no tree: arquivos `*_test.dart`, `test` e `testWidgets`, classes Java, `@Test`. O número de testes existentes é grande e não é cota. Não sugira apagar teste.

Diga o que a rede cobre de verdade: contrato de router e repository, widget, fila de séries, histórico, Home do aluno, recovery, referral, RBAC, tenant, webhook, `integration_test`, Playwright em `e2e/` (web, não o iPhone), geradores em `focux-backend/tool/`, piso JaCoCo se o `build.gradle` ainda declara.

Buraco que entra no plano é o que deixa passar série perdida, pagamento mentiroso, tenant cruzado, Home no contrato errado, exclusão que não apaga, saúde com permissão negada. Teste que trava comportamento que o código já removeu entra como ajuste do teste, não como lixo.

---

## 18. Observabilidade

Responda com a ferramenta que existe no repositório, ou com “não há”:

se a fila de séries não subir, se o webhook de pagamento falhar depois do 200, se o entitlement não aplicar, se o sync de saúde falhar, se o FCM não registrar — dá para saber no dia seguinte?

Cubra Crashlytics, Sentry, request id, métrica, tracing, health público, actuator, job com ShedLock. Não proponha outro APM nem fila nova. O gap é evento invisível ou log com PII.

---

## 19. Julgamento

Para cada funcionalidade do inventário: valor, clareza, frequência, fricção e ligação com o resto. O lançamento é personal e aluno reais, treino que não perde série, dinheiro que não mente, e Aluno 360 que mostra o que o aluno produziu.

Cada gap cai num balde só:

1. problema real
2. melhoria necessária para a loja
3. melhoria opcional
4. funcionalidade nova
5. scope creep

Funcionalidade nova sem buraco no fluxo atual é scope creep e vai para “Não construir agora”.

Não sugira rede social, marketplace, dieta, pose, hardware, Stripe, RevenueCat nem i18n. O produto é Brasil-first, locale `pt`, PIX e copy em português.

---

## 20. Prioridade

Cada item de P0 e P1 é um pacote de implementação, não uma ideia:

- título
- balde da seção 19
- comportamento atual, com arquivo, símbolo, rota ou endpoint
- comportamento desejado, verificável
- app, backend ou os dois
- testes que já existem e devem continuar passando, e o teste novo que trava o comportamento
- telas que o roteiro de celular precisa abrir por causa deste item
- dependência de outro item
- o que este item não mexe

### P0

Segurança, dado, pagamento, autenticação, estabilidade, integridade do treino, publicação, ou o fluxo de entrar, treinar, ver o aluno e cobrar com honestidade.

### P1

Sem isso a versão de loja fica frágil ou confusa, e não é furo de integridade.

### P2

Evidenciado, e fica fora da primeira submissão.

### P3

Expansão. Fora do plano de implementação.

`NECESSITA VALIDAÇÃO` não vira P0. Vira passo do roteiro de celular ou da ficha de submissão.

P2 e P3 não entram no plano que antecede a loja.

---

## 21. Não construir agora

Seção obrigatória. Entram itens sem necessidade para a loja, de complexidade alta, sem evidência, ou que atrasam a submissão.

Julgue e, se a evidência for fraca, coloque aqui: pose, comunidade, consumer de outbox, Stripe, RevenueCat, i18n, design system novo, dieta, form-check, dashboard analítico novo, gamificação nova, automação nova, white-label além do que já funciona.

O plano de implementação não contém esta seção.

---

## 22. Estado-alvo de prontidão

“10/10” não é nota e não é “mais bonito”. É este estado, para o produto inteiro: não há gap relevante conhecido que comprometa experiência, funcionamento, segurança, dados ou lançamento.

Não dê nota por tela. Para cada fluxo que for parar na loja, o plano só está pronto quando os critérios que se aplicam estão escritos como aceite de item P0 ou P1, ou como passo do roteiro de celular:

- job principal óbvio
- um dado, uma fonte
- backend no caminho feliz e no erro
- loading, vazio e erro
- offline que não finge gravação
- alvo de toque, rótulo, e o comportamento de escala que o roteiro confirma no iPhone
- first paint sem waterfall que o código mostra
- tenant e autorização
- sucesso e falha visíveis
- teste que trava o comportamento, ou passo de aparelho que o teste não alcança
- o outro papel vê o mesmo fato quando o fluxo cruza
- o widget se comporta como o resto do Focux

Tela pronta é tela em que esses critérios são verdade no código. Pele nova, sozinha, não autoriza loja.

---

## 23. Evidência

Formato:

`ACHADO — etiqueta — evidência — impacto — P0|P1|P2|P3|NÃO CONSTRUIR|ROTEIRO`

Proibido inventar tela, métrica, integração ou bug; tratar TODO ou spec como feature; forçar o código a caber no snapshot; copiar auditoria antiga sem reler o arquivo; colar segredo, token, e-mail, id OAuth ou plist.

---

## 24. Forma do relatório

Esta é a resposta inteira. Não há seção de considerações finais, próximos passos soltos, observações ou perguntas para o humano decidir depois.

1. **Inventário independente** — o mapa do tree, com etiquetas. Fonte da auditoria.
2. **Confronto com o snapshot** — só divergências, no formato `SNAPSHOT INCORRETO → REAL NO HEAD → EVIDÊNCIA`. Se não houver divergência, `SNAPSHOT CONFERE COM O INVENTÁRIO`.
3. **Mapa de telas** — as do inventário, mais sheets.
4. **Mapa de fluxos**
5. **Arquitetura App ↔ Backend**
6. **Gaps por tela** — sem nota. `SEM GAP RELEVANTE` quando for o caso.
7. **Gaps por fluxo**
8. **Dados** — origem, cálculo, persistência, consumo, inclusive aluno → Aluno 360.
9. **Performance**
10. **Segurança**
11. **App Store** — o que o código já mostra, e o que vai para o roteiro.
12. **Testes** — buraco que vira item de plano; teste que permanece.
13. **Órfãos**
14. **Duplicações**
15. **P0** — pacotes de implementação.
16. **P1** — pacotes de implementação.
17. **P2** — fora da primeira submissão.
18. **P3** — fora.
19. **Não construir agora**
20. **Plano de implementação** — só P0 e P1, em ordem de dependência. Uma área por vez. Sem calendário. Cada passo aponta o pacote, os testes e as telas do roteiro. Sem patch.
21. **Roteiro de teste no iPhone** — o único teste humano depois que o plano estiver implementado. Ver a seção 25.
22. **Submissão** — a ficha da seção 26. Quando o roteiro passar, a ação seguinte é enviar o binário.

Se uma seção não tiver item, escreva `NADA ENCONTRADO` e a busca. Não acrescente apêndice.

---

## 25. Roteiro de teste no iPhone

O relatório inclui o roteiro completo. Ele é o que a pessoa executa depois das implementações, no celular, nas telas que o plano alterou e nos passos que só o aparelho prova. Não é uma nova auditoria. Não descobre escopo. Falha no roteiro é bug contra o aceite já escrito.

Para cada tela que algum P0 ou P1 alterar, um caso:

- papel
- caminho desde o dock, o push ou o link
- preparo (vazio, com dado, sem rede, erro)
- ação
- resultado visível
- quando o fluxo cruza de papel, o que o outro papel vê em seguida

Bloco fixo, sempre no roteiro, porque o teste automatizado não substitui o aparelho:

- entrar com Apple, com Google e com e-mail, nos dois papéis
- compra sandbox do plano, restore, e o gate da feature depois da compra
- exclusão de conta do aluno e do personal, e a sessão que termina
- Health: permitir e recusar; o número na tab Saúde e no Aluno 360
- push: tocar e cair na tela certa
- universal link de convite e de `/p/{slug}`
- execução de uma série sem rede, reabrir o app, ver a série subir, ver carga, RPE e dor no Aluno 360
- fonte grande no iPhone pequeno na Home do aluno e na execução
- câmera ou foto só se o plano tiver mexido em evolução ou exercício
- propósito de permissão coerente com o que a tela faz

Cada caso termina em passa ou falha. Não há campo de comentário livre.

---

## 26. Submissão

O relatório inclui a ficha, nesta ordem. Item que o código já satisfaz fica marcado `NO CÓDIGO`, com arquivo. Item que o roteiro cobre fica `NO ROTEIRO`, com o número do caso. Item que é preenchimento na App Store Connect fica `NA FICHA`, com o texto ou o asset que o repositório já tem (nome, bundle, versão, purpose string, URL de privacidade). O que não estiver no repositório não é inventado: entra como `NA FICHA` com o campo vazio nomeado, para preencher na hora do envio, sem reabrir produto.

Ordem:

1. versão e build iguais ao `pubspec.yaml`
2. ícone, nome Focux Personal, bundle `com.focux.focuxApp`
3. capabilities do entitlements conferidas com o que o binário usa
4. privacy nutrition label alinhada ao `PrivacyInfo.xcprivacy` e ao que o app coleta
5. Sign in with Apple, compra, restore e exclusão de conta demonstráveis pelo roteiro
6. purpose strings iguais às do `Info.plist`
7. URL de suporte, privacidade e termos
8. conta de review: o que o revisor precisa conseguir fazer (entrar como personal, entrar como aluno, abrir um treino). Sem senha no relatório
9. notas de review só para o que o binário faz e a Apple não vê sozinha (Health, compra sandbox)
10. upload

Quando os pacotes P0 e P1 estiverem implementados, os testes do plano estiverem passando e o roteiro da seção 25 estiver em passa, o próximo ato é este upload. Não há auditoria extra.

---

## 27. O que acontece depois deste relatório

Você não executa estas fases. O relatório deixa elas fechadas.

1. Implementar os pacotes P0 e P1, um por vez, na ordem do plano. Testes existentes permanecem. O teste novo do pacote passa. P2, P3 e “Não construir agora” não entram.
2. Rodar o roteiro da seção 25 no iPhone, só nas telas alteradas e no bloco fixo.
3. Se um caso falhar, corrigir contra o aceite daquele pacote. Sem novo brainstorm.
4. Enviar para a Apple com a ficha da seção 26.

---

## 28. A sessão falhou se

- uma sugestão de tela apareceu antes do inventário independente
- a seção 6 definiu o que foi auditado
- alguma pasta de `lib/features/` ou de `com.focux.modules` ficou de fora do inventário
- o relatório usa o nome Personal 360
- algum P0 ou P1 não tem comportamento desejado, teste e tela de roteiro
- o roteiro de celular ou a ficha de submissão ficaram de fora
- sobrou pergunta, consideração final ou “depois a gente vê”
- você propôs apagar teste, patch, diff ou PR
- você tratou uma lista deste prompt como o produto inteiro
- SaaS, mensalidade do aluno e referral ficaram no mesmo fluxo
- a série não foi rastreada até o Aluno 360
- você deu nota a uma tela
- você afirmou que a Apple aprova, sem o item correspondente na ficha

A sessão está boa quando uma implementação seguida do roteiro no iPhone esgota o trabalho até o upload.
