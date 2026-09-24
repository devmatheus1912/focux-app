# Focux Personal — Performance Audit

**Data:** 2026-09-24  
**Escopo:** `focux-app` (Flutter/Dart) + trechos quentes de `focux-backend` (Spring)  
**Método:** auditoria estática de código + contratos existentes (BFF/cache) + varredura paralela ([startup](969b627b-7eeb-448a-bcf0-1251aa35c7ba), [Riverpod](59bab824-d956-4d85-a823-f9ecdce36734), [networking](f25c6497-b2da-4477-a2e8-cedf6e8bea89), [UI/leaks](b1dcc454-5088-469b-a041-a2cc67931100)).  
**Regra desta entrega:** sem alteração de código, sem commit, sem refactor.  
**Atualização:** 2026-09-24 — merge dos achados dos subagents (abaixo e seções 4–15).

> Separação obrigatória: **INFERÊNCIA ESTÁTICA** vs **MÉTRICA MEDIDA**.  
> Onde não houve DevTools/Timeline/APK size neste run: **NECESSITA DE PROFILING**.

---

## 1. Executive Summary

O Focux já tem decisões maduras de performance (BFF Home, ETag, ClientCache SWR 90s/60s, paginação de alunos `pageSize=40`, `FxCachedNetworkImage` com `memCacheWidth`, CI com `concurrency=2`). Os maiores riscos restantes **não** são micro-otimizações de `const` — são **custo antes do primeiro frame**, **I/O de Keychain por request/navegação**, **GPU (mesh + BackdropFilter no dock)**, **cascata de invalidação Aluno 360**, e **STOMP + HTTP em cada mensagem de chat**.

| Área | Estado | Risco dominante |
|------|--------|-----------------|
| Startup | Firebase+FCM+HomeWidget antes de `runApp` | 🔴 cold start |
| Home / BFF | SWR bem desenhado | 🟡 payload/rebuild fold |
| Alunos | Paginação + prefetch filtros | 🟠 prefetch em fan-out |
| Aluno 360 | Bundles + cache | 🔴 warm 8 + invalidate nuclear |
| Chat WS | STOMP por conversa | 🟠 reconnect JWT stale + `marcarLido` |
| Shell tabs | `IndexedStack` 5 abas | 🟠 RAM residente |
| BE homes | load-all-then-slice | 🔴 escala 300+ alunos |
| GPU/UI | Mesh + dock blur + `Image.network` | 🟠 low-end / galeria |
| Storage | SecureStorage sem cache RAM nativo | 🔴 por request |
| Testes (suite) | 551 arquivos `*_test.dart`; CI ~15+ min | 🟡 CI, não app |

---

## 2. Arquitetura analisada

### App (`focux-app`)

- **~981** arquivos Dart em `lib/`
- **~551** specs em `test/`
- **57** features sob `lib/features/` (agenda → winback)
- Camadas: `screens` / `widgets` / `providers` / `data` (repos) / `utils` / `core` (api, router, theme, widgets)
- Estado: **Riverpod** (`FutureProvider`, families, poucos `autoDispose`)
- Rede: **Dio** (`ApiClient`) + ETag store + `LocalCache` + circuit breaker
- Realtime: **STOMP** (`stomp_dart_client`) só na conversa de chat
- Navegação: **GoRouter** estático + `refreshListenable: SessionInvalidator.listenable` + `authRedirect` async
- SDKs: Firebase Core/Messaging/Crashlytics, FCM, IAP, Health, ML Kit (feedback), Rive, Google Fonts bundled

### Backend (`focux-backend`) — pontos quentes

- `DashboardService` + `@Cacheable("dashboard-home")` TTL **90s** (`CacheConfig`)
- `AlunoDashboardService` `@Cacheable("aluno-dashboard-home")` TTL **60s**
- Homes BFF (`/api/habitos/home`, alunos home, etc.) com evictors
- Engajamento: `GET /api/alunos/{id}/engajamento?dias=&limit=`

---

## 3. Estado atual

### Já saudável (não reinventar)

1. **Home BFF + ClientCache SWR** — `dashboardHomeProvider` / `DashboardHomeClientCache` (TTL 90s, stale 5m).  
2. **ETag + If-None-Match** no interceptor Dio (`api_client.dart`).  
3. **Alunos paginados** (`AlunosHomeQuery.pageSize = 40`) + tail notifier.  
4. **Aluno 360 fatiado** (`operacao` / `evolucao` / `ferramentas`) com comentário deprecando monolito no first paint.  
5. **Imagens** — wrapper `FxCachedNetworkImage` com default de `memCacheWidth`.  
6. **Telemetry Home** — `ProductEvents.homeTtv` já mede ms até first data (bom gancho de benchmark).  
7. **CI** — testes unitários só em push main; `concurrency=2` por RAM.

### Lacunas estruturais

1. Token JWT lido do **Keychain em todo request** e em **todo redirect**.  
2. Bootstrap **serializa** Firebase + FCM permission/token **antes** de `runApp`.  
3. **Mesh + BackdropFilter(heavy)** no chrome quase global.  
4. Maioria dos `FutureProvider` **sem `autoDispose`**.  
5. Prefetch de filtros de alunos pode disparar **N GETs** em paralelo.  
6. Assets locais: pasta `assets/` **não listável neste workspace** (possível LFS/checkout incompleto) — tamanho APK **NECESSITA DE PROFILING**.

---

## 4. Principais gargalos

| # | Gargalo | Severidade | Evidência |
|---|---------|------------|-----------|
| 1 | Firebase+FCM+HomeWidget antes do primeiro frame | 🔴 | `main.dart` 47–76, 173 |
| 2 | `SecureStorage.getToken()` por request Dio | 🔴 | `api_client.dart` 43–45 |
| 3 | BE alunos/treinos home: load-all → filter/sort → page | 🔴 | `AlunosHomeBaseLoader` / `TreinosHomeService` |
| 4 | Follow-up / 360: invalidação nuclear (+ dashboard + all 360 caches) | 🔴 | `aluno_followup_provider` / `invalidateAluno360Providers` |
| 5 | `authRedirect` async + Keychain; route graph eager imports | 🟠 | `app_router_redirect` / `app_router_chrome_routes` |
| 6 | `IndexedStack` 5 tabs vivas (personal + aluno) | 🟠 | `app_router_personal_shell_routes` / `app_router_aluno_routes` |
| 7 | `warmAluno360OperacaoList` pina 8 families sem dispose | 🟠 | `aluno_detail_providers.dart` ~158–162 |
| 8 | `BackdropFilter` blurHeavy no dock + mesh amplo | 🟠 | `fx_dock.dart` 97–100 |
| 9 | Chat: markRead/WS + reply N+1 BE + JWT stale no reconnect | 🟠 | conversa FE + `ChatMessageMapper` |
| 10 | `Image.network` sem decode cap (galeria/evolução/checkin) | 🟠 | `galeria_screen` / `evolucao_fotos` / `checkin_media` |

---

## 5. Startup

### Timeline inferida (antes do primeiro frame)

Ordem em `lib/main.dart` dentro de `runZonedGuarded`:

| Passo | Sync/Async | Arquivo | Pode adiar? |
|-------|------------|---------|-------------|
| `WidgetsFlutterBinding.ensureInitialized` | sync | `main.dart:47` | Não |
| LicenseRegistry + OFL load | async I/O | `main.dart:48–52` | Sim (pós-frame) |
| `GoogleFonts.config.allowRuntimeFetching` | sync | `main.dart:53` | OK |
| TLS pinning install | sync | `main.dart:59` | Não (segurança) |
| `HomeWidgetService.init()` | **await** | `main.dart:65` | **Sim** |
| SystemChrome edge-to-edge | sync | `main.dart:67–68` | Preferível cedo |
| `Firebase.initializeApp()` | **await** | `main.dart:75` | Parcial (Crashlytics lazy) |
| `FcmService.init(ApiClient())` | **await** | `main.dart:76` | **Sim, pós-login/pós-frame** |
| ErrorWidget builder | sync | `main.dart:104+` | OK |
| `runApp(ProviderScope)` | — | `main.dart:173` | — |

### FCM init (alto custo)

`FcmService.init` (`fcm_service.dart:26–54`):

- `requestPermission`
- `getToken` + `_registrarToken` (HTTP)
- listeners `onTokenRefresh` / `onMessage` / `onMessageOpenedApp` **sem cancel** (vida do processo — aceitável)
- `getInitialMessage`

**INFERÊNCIA:** cold start nativo fica preso a Firebase + permissão + rede **antes** de qualquer rota.  
**NECESSITA DE PROFILING:** Time to First Frame (TTFF) com/sem defer FCM.

### Pós-frame (`FocuxApp.initState`)

- Analytics binder, `PlanSyncCoordinator`, `_loadCustomTheme`, `iapStoreHealthProvider.start()` (timer 15m + check imediato).

**IAP no first frame** afeta quem nunca abre paywall — impacto médio em CPU/rede inicial.

---

## 6. Rendering/UI

### Achados

| Item | Detalhe | Severidade |
|------|---------|------------|
| Dock glass | `BackdropFilter` + `blurHeavy` em **toda** tab bar (`fx_dock.dart:97–100`) | 🟠 |
| Mesh | `CinematicMeshBackground` + grid `CustomPaint` Size.infinite; animação 420ms | 🟠 |
| Auth shell | `BackdropFilter` sigma 10 (`auth_shell.dart:362`) | 🟡 |
| Home Personal | `ref.watch(dashboardHomeProvider)` no body inteiro — qualquer SWR invalidate reconstrói fold | 🟡 |
| setState pós-home | `_homeFetchedAt` / analytics / seed plano via post-frame (`personal_dashboard_screen_build.part.dart:36–80`) — 1–3 rebuilds extras no first paint | 🟡 |
| Listas | Hubs usam `ListView`/`builder` de forma majoritária; poucos hotspots Column+scroll | 🟢 |
| Imagens | Wrapper com mem cache; feed força `memCacheWidth: 900` | 🟡 (feed) |

**NECESSITA DE PROFILING:** Performance Overlay em Android mid-range (Galaxy A / Pixel 4a class) com dock + mesh + Home scroll.

---

## 7. Riverpod

### Padrões observados

- ~9 usos de `autoDispose` vs dezenas de `FutureProvider` / `.family` forever-alive; **zero** `keepAlive` explícito.
- Homes BFF sem `autoDispose` — intencional para SWR, mas vivos após sair da tela.
- Bom uso de `select` só em badges aluno (`alunoHomeNotificacoesSelectProvider` / chat unread). `FeatureGate`, sticky CTA e copilot card **não** usam `select()`.

### Cascata crítica (ampliada)

1. **Follow-up nuclear** (`aluno_followup_provider` `_invalidate`): limpa `AlunosHomeClientCache` + **`Aluno360ClientCache` de todos os alunos** + `alunosHome` + `iaCopilotoHome` + 360 do aluno + **`dashboardHomeProvider`**. Um “marcar contato” pode refetch lista + IA home + dashboard + 360s aquecidos.
2. **`invalidateAluno360Providers`**: fan-out 13+ providers (incl. monolito deprecado) e depois `await` operacao — pull-to-refresh / platforms / evolução.
3. **`warmAluno360OperacaoList`**: `alunoIds.take(8)` → `ref.read(...future)` sem dispose — primeira paint da lista pina 8 árvores.
4. **Flags `StateProvider.family`** copiloto (force/skip/refreshing/creating) por `alunoId` sem `autoDispose` — vazam por sessão.
5. **Financeiro ↔ Dashboard**: `financeiroHomeProvider` sem TTL client; `invalidateFinanceiroCaches` invalida **ambos** (home BFF já embute financeiro).
6. **`commandCenterProvider`**: fatia de `dashboardHomeProvider`; invalidate duplo em task create.
7. **IA / recovery duplicados**: `proximaAcaoProvider` vs `alunoCopilotoActionProvider`; `copilotRecoveryProvider` vs `alunoRecoveryProvider` (+ card health com nome colidente em outro lib).
8. **Chat inbox**: 1 home → 3 slices; IndexedStack monta as 3 panes e observa todas; picker ainda `watch(alunosHomeProvider)`.

### Prefetch

`prefetchAlunosHomeFilterVariants` → `Future.wait` por filtro (fora Riverpod, uncancellable) + multiplica chaves Caffeine no BE.

---

## 8. API/Networking

### Dio (`api_client.dart`)

| Aspecto | Valor | Nota |
|---------|-------|------|
| Timeouts | 30s connect/receive/send | Alto para mobile flaky; evita abort cedo |
| Retry | até 2× com backoff ~700ms+ | OK; `fxNoRetry` existe |
| ETag | GET com store | Bom |
| LocalCache | paths selecionados | Bom |
| Auth header | `await SecureStorage.getToken()` **sempre** | 🔴 |
| FcmService.init | `ApiClient()` **novo**, fora do provider | Token register pode divergir do pool |

### Contratos quentes

- `GET /api/dashboard/home` — agregado (personal + command + financeiro + plano) — **certo** para round-trips; payload grande **NECESSITA DE PROFILING** (tamanho JSON).
- `GET /api/dashboard/aluno/home` — TTL 60s.
- Alunos home page 40.
- Engajamento: limit default BE 80.

### Backend (escala) — inferência estática

| Problema | Severidade | Arquivos (aprox.) |
|----------|------------|-------------------|
| Alunos home: `findByPersonalId` **todos** + filter/sort/page in-memory | 🔴 | `AlunosHomeBaseLoader` / `AlunosHomeService` |
| Treinos home: carrega todos ativos, agrega, depois fatia | 🔴 | `TreinosHomeService` |
| Chat historico: **N+1** `findById` por `replyToMessageId` no mapper | 🔴 | `ChatMessageMapper` / `ChatService.pageConversation` |
| Command center score: O(n) alunos (métricas em batch — não N+1 clássico) | 🟠 | `CommandCenterService.scoreAlunos` |
| `ApiTransportCircuit` só banner — **não** bloqueia Dio | 🟡 | `api_transport_circuit.dart` |
| Templates / `Aluno.listar()` drain size 100 × páginas | 🟡 | controllers/repos legados |

### Classificação

| Problema | Impacto | Severidade |
|----------|---------|------------|
| Keychain por request | Latência + bateria | 🔴 |
| BE load-all-then-slice (alunos/treinos) | Cold miss 300+ | 🔴 |
| Chat reply N+1 | Historico lento | 🔴 |
| Prefetch N filtros | Burst FE+BE cache | 🟠 |
| Timeout 30s | UX lenta em falha | 🟡 |
| Circuit não gateia tráfego | Retry inútil offline | 🟡 |

---

## 9. WebSocket/STOMP

**Único cliente STOMP FE encontrado:** `conversation_screen.dart`.

| Tópico | Achado | Severidade |
|--------|--------|------------|
| Lifecycle | `deactivate` em dispose; flag `_wsLifecycleEnded` | Bom |
| Reconnect | backoff exp até 30s, max attempts | Bom |
| Subscribe | 1 destination por connect | OK |
| Callback | `jsonDecode` + `setState` + **`await _markRead()`** se incoming | 🟠 |
| Reconnect | Headers JWT capturados **uma vez**; reconnect **não** refresca token | 🟠 |
| Falha parse | fallback `_loadHistorico()` (HTTP full) | 🟡 |
| Inbox | `invalidateChatInboxCaches` ligado a mark-read | 🟠 storm se muitas msgs |
| `_messageKeys` | `Map<String, GlobalKey>` cresce com histórico; não limpa | 🟡 sessão longa |

**Não há** STOMP global no bootstrap — positivo.

**NECESSITA DE PROFILING:** CPU/rede em conversa com burst de mensagens (personal + aluno digitando).

---

## 10. Cache/Storage

| Camada | Comportamento | Risco |
|--------|---------------|-------|
| SecureStorage nativo | Sem cache RAM do JWT; cada `getToken`/`getRole` → Keychain | 🔴 |
| SecureStorage web | Campos estáticos em memória | OK |
| DashboardHomeClientCache | TTL 90s + stale 5m + claimRefresh | Bom |
| AlunosHomeClientCache | por query; TTL próprio | Bom |
| Aluno360ClientCache | por alunoId | Bom se limpo no logout |
| ApiEtagStore | in-memory | OK; limpar no tenant switch (já há evictor de sessão) |
| BE Caffeine | dashboard-home 90s / aluno 60s | Alinhado ao client |

**Escrita excessiva:** não evidenciada como hot path além de caches put.

---

## 11. Imagens/Assets

### Código

- `FxCachedNetworkImage` aplica defaults de mem cache (`fx_cached_network_image.dart`) — usar sempre.
- Feed: `memCacheWidth: 900` — alto para lista densa em mid-range.
- **Sem decode cap:** `Image.network` em `galeria_screen`, `evolucao_fotos_screen`, `checkin_media_widgets` (preview) — 🟠 RAM/CPU decode full-res.

### Assets declarados (`pubspec.yaml`)

- Logos PNG, 4× Rive (`.riv`), pasta `assets/google_fonts/` (Inter, JetBrainsMono, BarlowCondensed).
- Runtime fetching de Google Fonts **desligado** fora debug (`main.dart:53`) — bom.

### Workspace

Pasta `assets/` **sem arquivos listáveis** nesta máquina → tamanho real APK/IPA **NECESSITA DE PROFILING** (`flutter build apk --analyze-size` / App Size).

Rive remoto em `fx_rive_assets.dart` (URLs public.rive.app) — risco de download ocasional se usado.

---

## 12. Dart/CPU

| Achado | Onde | Severidade |
|--------|------|------------|
| Trabalho no isolate | Pouco uso explícito de `compute`/isolate para JSON grande | 🟡 |
| `DashboardHomeSnapshot.build` no build path | personal dashboard data branch | 🟡 — NECESSITA PROFILING se lista fila grande |
| Prefetch `Future.wait` filtros | alunos | 🟠 rede, não CPU pura |
| Timers 1s checkin | `checkin_screen.dart` — dispose cancela | OK |
| Regex Eagle gate | só testes | N/A app |

Evitar micro-otimizar `map`/`where` sem hot path medido.

---

## 13. Navegação

| Item | Evidência | Severidade |
|------|-----------|------------|
| `refreshListenable: SessionInvalidator.listenable` | `app_router.dart` | OK para logout |
| `redirect: authRedirect` **async** | lê token + role (+ password flag) do SecureStorage | 🟠 |
| Árvore de rotas enorme | `app_router_chrome_routes.dart` + shells | 🟡 parse/init GoRouter — NECESSITA PROFILING cold nav |
| Redirects legados | muitos aliases → rotas canônicas | 🟢 |

Cada mudança de rota com redirect pode pagar **múltiplos round-trips Keychain**.

---

## 14. Firebase/SDKs

| SDK | Quando inicia | Nota |
|-----|---------------|------|
| Firebase Core | Antes de `runApp` | 🔴 |
| FCM | Junto Firebase | 🔴 permission+token+HTTP |
| Crashlytics handlers | Após Firebase OK | OK |
| IAP health | Post-frame | 🟡 |
| Home Widget | Antes de `runApp` | 🟠 |
| ML Kit | Sob demanda nas telas de feedback | Preferível manter lazy |
| Health Connect | Features health | Lazy se só nessas rotas |

---

## 15. Memory leaks

| Item | Severidade | Nota |
|------|------------|------|
| FCM `.listen` sem cancel | 🟢 process-lifetime | Aceitável |
| STOMP + Timer reconnect | 🟢 se dispose correto | Código cancela |
| `iapStoreHealthProvider` timer | 🟢 onDispose cancela | OK |
| `FxConnectivityBanner` subscription | verificar dispose | 🟡 revisão pontual |
| AnimationControllers (mesh, skeleton, confetti) | maioria com dispose | 🟢 |
| FutureProviders keep-alive | 🟠 retenção de bundles grandes | Escalabilidade |
| `IndexedStack` shells (5 tabs) | 🟠 RAM baseline sempre | Personal + aluno |
| Image cache / uncapped network | 🟠 feed 900 + galeria/evolução | Mid-range RAM |
| Copilot `StateProvider.family` flags | 🟡 por alunoId visitado | Sessão longa |

Controllers/Timers/STOMP nas telas quentes: dispose OK (inferência). Confirmar heap após 20× abrir aluno 360 — **NECESSITA DE PROFILING**.

---

## 16. Escalabilidade

| Escala | Risco |
|--------|-------|
| 10–50 alunos | OK com page 40 + BFF |
| 100–300 | Prefetch filtros × N + Home command lists | 🟠 |
| 500+ | Listas Home (risco/score/fila) no payload único | 🟠 BE+FE |
| Chat longo | Historico + setState lista; sem virtualização custom | 🟡 |
| Biblioteca exercícios | Picker paginado — melhor caminho | 🟢 se sempre via picker |
| Financeiro histórico longo | Depende paginação da tela detalhe | 🟡 auditar se lista flat |
| Feed grande | imagens 900 + cards | 🟠 |

---

## 17. Testes (performance da **suíte**, não do app)

| Métrica | Valor |
|---------|-------|
| Arquivos `*_test.dart` | ~551 |
| CI | `flutter test --concurrency=2`, timeout 35m, só push main |
| Comentário CI | “~15+ min / 500+ specs”; 4 workers estouravam RAM |

### Recomendações (suite only)

- Manter cobertura; **não** deletar testes por velocidade.
- Considerar sharding por path no Actions (jobs paralelos) sem reduzir asserts.
- Isolar testes de contrato/source-bundle (rápidos) vs widget pesados.
- **NECESSITA DE PROFILING:** ranking dos 20 testes mais lentos (`flutter test --reporter json` / timeline).

---

## 18. Performance por tela

Legenda: valores de tempo/FPS = **não medido — requer profiling**.  
Riscos = inferência estática.

| Tela | API | Providers | Rebuild risk | GPU | Leak risk | Dup call | Lentidão |
|------|-----|-----------|--------------|-----|-----------|----------|----------|
| Startup → 1ª rota | FCM register | — | — | baixo | baixo | — | 🔴 |
| Home Personal | 1 BFF (+SWR) | `dashboardHome` | alto (watch root) | mesh+dock | baixo | baixo c/ cache | 🟠 |
| Home Aluno | 1 BFF | `alunoDashboardHome` + selects | médio | mesh+dock | baixo | baixo | 🟡 |
| Alunos lista | home page + prefetch | `alunosHome*` | médio | médio | médio cache | prefetch N | 🟠 |
| Aluno 360 | operacao (+lazy) | várias families | alto invalidate | médio | médio | médio | 🟠 |
| Financeiro hub | home BFF | `financeiroHome` | médio | médio | baixo | baixo | 🟡 |
| Agenda | home | `agendaHome` | médio | médio | baixo | baixo | 🟡 |
| Treinos lista | home + pages | `treinos*` | médio | médio | baixo | médio | 🟡 |
| Check-in execução | start/series | local state+timers | setState 1Hz | médio | baixo (dispose OK) | — | 🟡 |
| Chat inbox | list | inbox providers | médio | médio | baixo | invalidate | 🟡 |
| Chat conversa | hist + STOMP | local | setState/msg | médio | médio WS | markRead | 🟠 |
| Feed | posts | feed | imagens | alto | médio | — | 🟠 |
| Engajamento | engajamento | local | baixo | médio | baixo | — | 🟢 |
| Hábitos | habitos/home | local | baixo | médio | baixo | — | 🟢 |
| IA Copiloto | IA + home | vários | médio | médio | baixo | médio | 🟡 |

---

## 19. Problemas classificados por severidade

### 🔴 CRÍTICO

#### P1 — Bootstrap bloqueia first frame com Firebase+FCM
1. **Arquivo:** `lib/main.dart` ~65–76  
2. **Função:** `main` / `FcmService.init`  
3. **Problema:** await HomeWidget + Firebase + FCM permission/token/HTTP antes de `runApp`  
4. **Causa:** init “seguro” serializado  
5. **Impacto:** cold start / TTFF  
6. **Evidência:** código sequencial await  
7. **Solução:** `runApp` cedo; defer FCM/HomeWidget pós-frame ou pós-auth; Crashlytics minimal sync  
8. **Risco alteração:** médio (notificações terminated)  
9. **Dificuldade:** M  
10. **Ganho esperado:** **alto** (qualitativo)  
11. **Medir:** TTFF, time-to-interactive login/home  

#### P2 — SecureStorage Keychain em todo request
1. **Arquivo:** `lib/core/api/api_client.dart` ~43  
2. **Problema:** `await SecureStorage.getToken()` sem cache RAM nativo  
3. **Impacto:** latência por chamada + jank se main isolate espera  
4. **Evidência:** `secure_storage.dart` lê storage a cada get; sem memoização nativa  
5. **Solução:** cache em memória invalidado no logout/refresh (padrão session holder)  
6. **Risco:** médio (stale token) — mitigar no refresh/logout  
7. **Ganho:** **muito alto** em telas chatty  
8. **Medir:** p50 latency Dio interceptor before/after  

### 🟠 ALTO

#### P3 — authRedirect lê SecureStorage repetidamente
- `app_router_redirect.dart:8–40`  
- Solução: session snapshot in-memory + listenable  
- Ganho: **alto** em navegação dock  

#### P4 — FxDock BackdropFilter blurHeavy permanente
- `fx_dock.dart:97–100`  
- Solução: blur leve / solid glass em `prefersReducedMotion` ou low-end flag; RepaintBoundary  
- Ganho: **alto** FPS scroll+dock  
- **NECESSITA DE PROFILING** GPU  

#### P5 — Mesh global
- Dezenas de `useMesh: true`  
- Solução: flat em mid-tier; animação grid off  
- Ganho: **médio–alto**  

#### P6 — Cascata invalidate Aluno 360
- `aluno_detail_providers.dart`  
- Solução: invalidar só fatias tocadas; não monolito se não montado  
- Ganho: **alto** em fluxo operação  

#### P7 — Chat markRead + invalidate por mensagem WS
- `conversation_screen.dart` callback  
- Solução: debounce markRead; invalidar inbox ao sair da conversa  
- Ganho: **alto** em chat ativo  

### 🟡 MÉDIO

- Prefetch fan-out filtros alunos  
- IAP health no first frame  
- Feed `memCacheWidth: 900`  
- Timeout Dio 30s UX  
- Home rebuild root no SWR  
- Keep-alive FutureProviders  

### 🟢 BAIXO

- License OFL load no startup (menor)  
- Micro `const` ausentes  
- Rive só em telas de celebração  

---

## 20. Quick Wins

| # | Ação | Esforço | Risco | Validar |
|---|------|---------|-------|---------|
| Q1 | Cache RAM do JWT (+ role) com clear no logout | P | M | Latency interceptor |
| Q2 | Defer `FcmService.init` pós-primeiro-frame (manter getInitialMessage path) | M | M | TTFF + notif cold |
| Q3 | Defer `HomeWidgetService.init` | P | B | TTFF |
| Q4 | Debounce `_markRead` (300–800ms) | P | B | Network count chat |
| Q5 | Não prefetch filtros financeiros se capability off (já parcial) + cap concorrência 2 | P | B | Charles/proxy |
| Q6 | `memCacheWidth` feed ~480–720 device-pixel | P | B | Memory DevTools |
| Q7 | Dock: reduzir blur se `reduceMotion` / low RAM | P | B | Overlay FPS |

---

## 21. Melhorias de alto impacto

| # | Ação | Dependências |
|---|------|--------------|
| H1 | Session holder unificado (token/role) para Dio + GoRouter | Q1 |
| H2 | Pipeline startup: runApp → splash/router → Firebase/FCM | Q2/Q3 |
| H3 | GPU budget: mesh/dock tiers (high/mid/low) | Design tokens |
| H4 | Invalidate cirúrgico Aluno 360 | Mapear callers |
| H5 | Chat: outbox local + markRead batch BE se necessário | Contrato BE opcional |

---

## 22. Melhorias arquiteturais

| # | Tema | Nota |
|---|------|------|
| A1 | Isolar parsing JSON grande Home/360 em isolate se profiling mostrar >8ms | Só com medida |
| A2 | Sharding CI testes | Só suite |
| A3 | Observation: traces OpenTelemetry / custom TTFF já parcialmente via `homeTtv` | Expandir eventos |
| A4 | Standby produto (não perf puro): limiar compliance configurável; agregados engajamento no BFF | Documentado em chat anterior |

---

## 23. Roadmap

### FASE 1 — Quick Wins (1–3 dias)
Q1–Q7. Impacto: **alto**. Risco: **baixo–médio**.

### FASE 2 — Alto impacto (1–2 sprints)
H1–H4. Impacto: **muito alto**. Risco: **médio**.

### FASE 3 — Arquitetura (planejado)
A1–A3 + eventual shrink payload Home se medida mostrar.

### FASE 4 — Profiling contínuo
- Gate CI opcional: smoke TTFF em device farm  
- Dashboard interno: p95 `homeTtv`, request count Home  
- DevTools checklist por release  

---

## 24. Plano de profiling

1. **Cold start:** Timeline + `flutter run --trace-startup` (Android mid + iPhone SE class).  
2. **Home:** rebuild tracker + network; correlacionar com `homeTtv` analytics.  
3. **Dock+scroll:** Performance Overlay + GPU rendering (Android).  
4. **Chat burst:** Network + CPU enquanto WS envia 20 msgs.  
5. **Memory:** heap após 20 alunos 360 abertos/fechados.  
6. **APK size:** `flutter build apk --analyze-size` (assets/fonts/Rive).  
7. **Suite:** listar top 20 testes lentos.

---

## 25. Benchmarks recomendados

| Benchmark | Antes | Depois | Ferramenta |
|-----------|-------|--------|------------|
| TTFF cold | ms | ms | trace-startup |
| Time to Home data | `homeTtv` ms | ms | analytics / local log |
| Dio GET median (authed) | ms | ms | interceptor timing |
| Keychain reads / min | count | count | counter no SecureStorage |
| FPS scroll Home | frames | frames | Overlay |
| Chat markRead calls / 10 msgs | count | count | log/proxy |
| RSS after 10 min usage | MB | MB | DevTools |
| `flutter test` wall clock | min | min | CI |

**Não declarar % de ganho sem esses números.**

---

## 26. Checklist de validação

- [ ] Nenhuma mudança de contrato API sem aprovação  
- [ ] Logout limpa cache JWT RAM + ClientCaches  
- [ ] Notificação terminated ainda abre rota correta após defer FCM  
- [ ] Reduce motion / low-end não quebra anatomia FOCUX  
- [ ] Testes existentes verdes (não remover cobertura)  
- [ ] `homeTtv` não regride > limiar acordado  
- [ ] Chat markRead ainda marca leitura (debounce OK)  

---

## 27. Conclusão técnica

O Focux **já opera no nível “BFF-first / SWR”** — o certo para um personal com muitos módulos. O retorno agora está em **tirar trabalho do caminho crítico de startup**, **eliminar I/O de Keychain repetido**, **paginar de verdade no BE (alunos/treinos)**, **baratear chrome GPU + IndexedStack**, e **cirurgia em invalidação 360 + chat (N+1 / markRead / JWT reconnect)**.

Micro-otimizar `const` ou reescrever widgets sem profiling seria ruído. Ordem: **medir TTFF/Keychain/p95 homes → Session cache → BE page SQL + chat N+1 → defer FCM → GPU/IndexedStack → invalidate cirúrgico**.

---

## Apêndice A — TOP 10 gargalos

1. Firebase+FCM+HomeWidget antes de `runApp`  
2. `SecureStorage.getToken` por request (+ redirect)  
3. BE alunos/treinos **load-all-then-slice**  
4. Invalidação nuclear follow-up / 360 (+ clear all 360 caches)  
5. `IndexedStack` 5 tabs + warm 8×360  
6. Chat reply **N+1** BE + markRead FE + JWT stale reconnect  
7. Dock `blurHeavy` + mesh  
8. Prefetch filtros alunos (FE stampede + BE cache keys)  
9. `Image.network` sem cap (galeria/evolução/checkin)  
10. Eager import do grafo de rotas chrome (+ splash motion TTI)

## Apêndice B — TOP 10 melhorias (impacto)

1. Session JWT/role in-memory (Dio + redirect)  
2. SQL page/filter alunos-home + treinos-home (parar load-all)  
3. Batch replies no chat historico (matar N+1)  
4. Defer FCM / HomeWidget; aliviar splash waits  
5. Invalidate 360/follow-up **cirúrgico** (não clear global)  
6. `autoDispose` / não warm 8 forever; flags family dispose  
7. Debounce markRead + refresh JWT no STOMP reconnect  
8. Dock/mesh GPU tiers + `FxCachedNetworkImage` nas fotos  
9. Cap/serializar prefetch filtros  
10. `select()` em FeatureGate / sticky / copilot; não invalidate dashboard em mark-read notif

## Apêndice C — TOP 10 menor risco

1. Defer HomeWidget  
2. Debounce markRead  
3. Trocar `Image.network` → `FxCachedNetworkImage` (galeria/evolução/checkin)  
4. Cap prefetch concurrency  
5. Delay IAP health  
6. RepaintBoundary no dock  
7. Refresh token no reconnect STOMP  
8. Remover invalidate duplo `commandCenter` quando home já invalida  
9. CI test sharding (suite)  
10. Telemetria `ttff` / `dio_auth_ms` / contador Keychain (debug)

## Apêndice D — Precisam profiling antes de mudar

- Tamanho JSON `/dashboard/home`  
- FPS real com mesh+dock + IndexedStack  
- p95 `GET /api/alunos/home` e `/treinos/home` com 100/300/500 alunos  
- Query count historico chat com replies  
- Heap após warm 8 + N detalhe 360  
- Tamanho APK/fonts/Rive; top testes lentos  
- Custo dual `ThemeData` no first `FocuxApp.build`

## Apêndice E — Seguros por análise estática

- Cache RAM JWT (clear logout/refresh)  
- Debounce markRead  
- Defer HomeWidget  
- Cap prefetch  
- `FxCachedNetworkImage` + memCacheWidth feed↓  
- Contadores de telemetria  
- Não invalidar `dashboardHome` em mark-all notificações (só badge)

## Apêndice F — Riscos de regressão

- Defer FCM: deep link terminated / token atrasado  
- Cache JWT: stale pós-refresh se esquecer clear  
- SQL page alunos/treinos: ordem/filtro divergente do in-memory atual  
- Invalidate menos no 360/follow-up: UI stale  
- Mudar blur/mesh/IndexedStack: anatomia FOCUX / estado de aba  

## Apêndice G — Roadmap resumido

Fase 1 Quick Wins (JWT cache, defer HomeWidget, markRead, images, prefetch cap) → Fase 2 Startup FCM + GPU tiers + invalidate cirúrgico → Fase 3 BE page SQL + chat N+1 + splash/route load → Fase 4 continuous profiling.

## Apêndice H — Ganho qualitativo esperado

| Pacote | Ganho |
|--------|-------|
| Session cache + redirect | **muito alto** |
| BE page SQL alunos/treinos | **muito alto** (carteiras grandes) |
| Chat N+1 batch | **alto** |
| Defer FCM/HomeWidget | **alto** |
| Invalidate cirúrgico + menos warm | **alto** |
| GPU dock/mesh tiers | **alto** (low-end) |
| Chat debounce + JWT reconnect | **médio–alto** |
| Prefetch cap + images cap | **médio** |
| Micro const | **baixo** |

---

*Auditoria somente leitura. Nenhuma alteração de código nesta etapa. Apêndices atualizados com merge dos subagents.*
