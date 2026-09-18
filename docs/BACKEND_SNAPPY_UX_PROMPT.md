# Prompt backend — alinhar BFF 100% (snappy UX / produção)

> **Como usar:** abra este arquivo no agente do `focux-backend` (ou cole o conteúdo integral).  
> **App já pronto:** `focux-app` PR [#109](https://github.com/devmatheus1912/focux-app/pull/109) — `1.2.1+84` — branch `cursor/perf-snappy-ux-cd16`.  
> **Objetivo:** implementar o lado servidor completo, sem defer, alinhado ao contrato que o app já consome.

---

## Contexto (não invente)

O Flutter já está production-ready e tolera API antiga **e** nova:

| Lado | Estado |
|------|--------|
| App | ClientCache SWR, ETag/`If-None-Match`, `historicoResumo`, caps, `pulse.coachPendentes`, imagens cacheadas |
| Backend | Falta slim no BFF, ETag/304, N+1 zero, caps server, Redis/evict, `pulse.coachPendentes` |

### Fontes canônicas

- `docs/CONTRATO_APP_BACKEND.md`
- `docs/FOCUX_DESIGN_REFERENCE.md` (cache Home 90s, evict no writer, sem N+1)
- `docs/system/05-cache.md`
- App: `lib/features/dashboard/data/dashboard_repository.dart`
- App: `lib/features/checkin/data/checkin_repository.dart` (`fromHistoricoResumoJson`)
- App: `lib/core/api/api_client.dart` + `api_etag_store.dart`

### Regras

- Pode mudar BFF/contrato pareado.
- **Não** mexa auth / tenant / pagamento / Flyway / RLS sem necessidade.
- Sem migration se não precisar de schema.
- Não invente endpoint novo se o BFF já existe — edite os builders.
- Ship tudo neste PR (ou série curta sem “fase 2”).

---

## Objetivo

Deixar estes dois endpoints **rápidos, slim e cacheáveis**, alinhados 100% ao app `1.2.1+84`:

- `GET /api/dashboard/home` (personal)
- `GET /api/dashboard/aluno/home` (aluno)

### Critérios de aceite (todos obrigatórios)

1. Payload slim no home do aluno (sem dump de séries/mídia no histórico).
2. ETag + 304 nos dois homes.
3. Cache server com TTL explícito + evict no write path.
4. Zero N+1 nos builders dos dois homes (batch / EntityGraph / join fetch).
5. `pulse.coachPendentes` no home personal (app já lê; sem sidecar coach no first paint).
6. Caps no servidor (não só no client).
7. Testes + medição p95 antes/depois.
8. Backward compatible: app antigo ainda funciona.

---

## A) `GET /api/dashboard/aluno/home` — slim + caps

### A1. Campo novo `historicoResumo` (obrigatório)

Array slim, máx **12** itens, ordenado do mais recente.  
**Sem** `exercicios`, **sem** mídia, **sem** evoluções.

Contrato de cada item (exato — o app parseia assim):

```json
{
  "id": 123,
  "treinoId": 45,
  "treinoNome": "A — Superior",
  "status": "CONCLUIDO",
  "iniciadoEm": "2026-09-18T10:00:00Z",
  "concluidoEm": "2026-09-18T11:00:00Z",
  "exerciciosCount": 8
}
```

| Campo | Obrigatório no app |
|-------|--------------------|
| `id` | sim |
| `treinoId` | sim (default 0) |
| `treinoNome` | sim |
| `status` | sim |
| `iniciadoEm` | opcional |
| `concluidoEm` | opcional |
| `exerciciosCount` | opcional (informativo) |

### A2. Campo legado `historico`

Enquanto houver clientes &lt; `1.2.1+83`:

- Pode continuar, **mas**:
  - **não** embutir séries/detalhes/mídia se `historicoResumo` já veio;
  - preferência: emitir `historico: []` ou omitir quando `historicoResumo` estiver presente  
    (o app **prefere** `historicoResumo` se a lista não for vazia).
- Documentar no CONTRATO: Home usa `historicoResumo`; dump completo só em `GET /api/checkin/historico` (paginado).

### A3. Caps server-side (obrigatório)

| Campo | Cap |
|-------|-----|
| `historicoResumo` | 12 |
| `medidas` | 5 (mais recentes) |
| `coachMensagens` | 5 (não lidas / mais recentes) |
| `treinos` (agenda do dia / ativos) | só o que a Home precisa; sem dump de biblioteca |
| `upsellPendentes` | ≤ 5 |
| `recordes` | ≤ 10 (se vier no bundle) |

O app já aplica caps client como rede de segurança; o servidor **deve** cortar na origem.

### A4. `chat` = resumo (não histórico completo)

App espera:

```json
"chat": {
  "possuiMensagemDoAluno": true,
  "ultimaMensagemAlunoEm": "2026-09-18T09:00:00Z",
  "naoLidasDoPersonal": 2
}
```

**Proibido** mandar lista de mensagens no home.

### A5. Performance / N+1

No builder do aluno home:

- Identificar e eliminar N+1 (checkins, medidas, coach, chat unread, notificações, brand).
- Usar batch / `@EntityGraph` / queries agregadas.
- **Proibido** esconder N+1 com cache.
- Se hoje monta histórico completo com séries: substituir por query slim (só colunas do resumo + count).

**TTL cache aluno home:** `60s` (app alinhado).  
Nome sugerido: `dashboard-aluno-home`.

---

## B) `GET /api/dashboard/home` (personal) — pulse completo

### B1. `pulse.coachPendentes` (obrigatório)

App já lê:

```json
"pulse": {
  "checkinsHoje": 3,
  "mensagensNaoLidas": 5,
  "coachPendentes": 2,
  "checkinsTrend": [0, 1, 2, 1, 0, 3, 2],
  "emptyHint": "..."
}
```

- `coachPendentes` = contagem de mensagens/itens coach não lidos do personal (mesmo critério do coach home).
- Aceita alias legado `coachPending`, mas **canônico** é `coachPendentes`.
- Home **não** deve forçar o app a chamar `GET coachHome` no first paint só por badge.

### B2. Resto do pulse (manter / garantir)

| Campo | Significado |
|-------|-------------|
| `mensagensNaoLidas` | unread de **chat** (SSOT da Home) |
| `checkinsHoje` | check-ins do dia |
| `checkinsTrend` | 7 ints, hoje-6 … hoje |
| `emptyHint` | opcional |

### B3. Cache personal

- TTL **90s**, cache name `dashboard-home` (já documentado na referência).
- Evict no write path via `DashboardHomeCacheEvictor` (e equivalentes) em: perfil, wallet, aluno create/update, chat send/read, mensalidade, white-label, coach marcar lido, checkin, etc.
- **Listar no PR** cada writer → evict.

---

## C) ETag / HTTP 304 (obrigatório nos dois homes)

O app já envia `If-None-Match` em GETs e trata `304` como sucesso (reusa ClientCache).

### Implementar

1. Gerar `ETag` estável por resposta (hash do payload canônico **ou** versão monotônica por tenant/aluno + revision).
2. Responder `ETag: "..."` em `200`.
3. Se `If-None-Match` casar → **`304 Not Modified`** sem body.
4. `Cache-Control` alinhado ao TTL (`max-age=60` aluno / `max-age=90` personal) **ou** só ETag; não mentir freshness.
5. Invalidar ETag/revision no mesmo write path do cache (evict).

### Endpoints mínimos

- `GET /api/dashboard/home`
- `GET /api/dashboard/aluno/home`

(Opcional ROI alto, se barato: outros hubs BFF já cacheados.)

### Testes

- `200` com ETag → segundo GET com `If-None-Match` → `304`.
- Após mutação que evicta → `200` de novo com ETag novo.

---

## D) Redis / multi-instância

Conforme `docs/system/05-cache.md`:

1. Se Redis estiver (ou puder ser) ligado: invalidação distribuída no writer (não só Caffeine local).
2. Se single-node: documentar explicitamente no PR.
3. Value cache opcional do JSON do home (além do Caffeine) **só** se evict estiver correto.
4. **Proibido** cachear entitlement pago sem evict no webhook/IAP.

---

## E) Não fazer / não quebrar

- **NÃO** quebrar clientes antigos: home personal/aluno continua parseável.
- **NÃO** mudar envelope de paginação de outros endpoints neste PR.
- **NÃO** reescrever campo `erro` / códigos auth.
- **NÃO** criar segundo BFF paralelo; editar os builders existentes.
- **NÃO** “otimizar” escondendo N+1 com `@Cacheable` sem corrigir query.
- Detalhe completo de treino/execução continua em `GET /api/checkin/{id}` e histórico paginado.

---

## F) Atualizar contrato

Atualizar `focux-app/docs/CONTRATO_APP_BACKEND.md` (PR pareado ou nota no PR do backend) com:

- [ ] `historicoResumo` no aluno home
- [ ] caps
- [ ] ETag/304 nos dois homes
- [ ] `pulse.coachPendentes`
- [ ] TTL 60s aluno / 90s personal + lista de evictors

---

## G) Testes e evidência (gate do PR)

1. Testes unit/integration do builder:
   - `historicoResumo` size ≤ 12 e sem `exercicios`
   - caps medidas/coach
   - `pulse.coachPendentes` presente
2. Teste ETag `200` → `304` → evict → `200`
3. Log/assert de SQL sob carga realista do home aluno: **0 N+1**
4. Antes/depois: tamanho médio do JSON aluno home + p95 do endpoint (timer `focux.dashboard.home` / equivalente aluno)
5. `./gradlew test` nos módulos tocados

---

## H) Ordem de implementação sugerida

1. Slim `historicoResumo` + caps + cortar dump (maior ROI payload)
2. Matar N+1 do builder aluno home
3. `pulse.coachPendentes` no personal home
4. ETag/304 nos dois
5. Evict completo + Redis/doc multi-instância
6. CONTRATO + métricas no PR

---

## Definition of Done

- [ ] aluno home devolve `historicoResumo` slim ≤ 12
- [ ] sem séries/mídia no histórico do home
- [ ] caps medidas ≤ 5, coach ≤ 5 no server
- [ ] personal `pulse.coachPendentes` preenchido
- [ ] ETag + 304 nos dois homes
- [ ] TTL 60s / 90s + evict listado
- [ ] 0 N+1 comprovado
- [ ] testes verdes + p95/tamanho no corpo do PR
- [ ] CONTRATO atualizado

---

## Referência rápida — o que o app já faz (não reimplementar no BE)

| Capacidade | Onde no app |
|------------|-------------|
| ClientCache aluno 60s + SWR 5min | `aluno_dashboard_home_client_cache.dart` |
| ClientCache personal 90s + SWR 5min | `dashboard_home_client_cache.dart` |
| Prefetch pós-login | `login_screen_actions.part.dart` |
| `If-None-Match` / store ETag / 304 | `api_client.dart`, `api_etag_store.dart` |
| Prefere `historicoResumo`; fallback dump slim+cap 12 | `dashboard_repository.dart` |
| Caps medidas/coach 5 | `dashboard_repository.dart` |
| Lê `pulse.coachPendentes` | `DashboardPulseSnapshot` |
| Evict cache no logout | `session_invalidator` / `session_cache_evictor` |

App **já sobe** sem este PR de backend. Este doc fecha o ganho de servidor (payload, p95, multi-instância).
