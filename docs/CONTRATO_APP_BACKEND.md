# Contrato pareado `focux-backend` ↔ `focux-app`

Documento de acordo entre os dois repositórios, criado a partir do cruzamento
dos 432 endpoints do backend contra as 341 chamadas de produto do app. Cada
seção tem um estado: **acordado**, **aberto** ou **confirmado**.

Regra que vale para tudo: mudança de contrato exige PR pareado. O app em
produção não pode quebrar.

---

## 1. Envelope de paginação — acordado

### 1.1 Os três formatos que ficam como estão

Não serão tocados. Estão em produção e funcionam:

| Formato | Endpoints |
|---|---|
| `Page` do Spring (`content`, `number`, `size`, `totalElements`, `totalPages`, `last`) | `GET /api/exercicios/v2`, `GET /api/exercicios/picker` |
| `mensalidades`, `page`, `size`, `hasMore` | `GET /api/financeiro/mensalidades` |
| objeto (`id`, `alunoId`, `alunoNome`, `valor`, `status`…) | `GET /api/financeiro/mensalidades/{id}` |
| `items`, `page`, `total`, `hasMore` | `GET /api/notificacoes` |

O chat atual (`items`, `nextBeforeId`, `hasMore`) entra na mesma lista: legado,
intocado.

### 1.2 Envelope offset para todos os endpoints novos

```json
{
  "content": [],
  "page": 0,
  "size": 20,
  "totalElements": 137,
  "hasNext": true
}
```

Regras:

- **`content` sempre**, nunca nome de domínio. É o que permite um parser
  genérico único no app (`lib/core/api/pagina.dart`).
- **`page` base 0.**
- **`size` com cap no servidor.** Pedido acima do cap devolve o cap, não erro.
  Default 20, cap 100 — salvo onde o custo por item exigir cap menor, e nesse
  caso o valor fica registrado aqui.
- **`hasNext` explícito**, nunca derivado. Sem ele o app não distingue fim de
  lista de carregamento em andamento.
- **Ordenação fixada no servidor.** `Sort` do cliente não é repassado ao JPA.
  Os dois endpoints que fazem isso hoje (`ExercicioController`,
  `AuditoriaController`) são um P1 aberto e não servem de precedente.

**Consequência de implementação:** este envelope **não** é o `Page` do Spring —
difere em `page` (vs `number`) e `hasNext` (vs `last`). Portanto controller
nenhum pode devolver `Page<T>` direto; é obrigatório um wrapper
(`PaginaResponse<T>`) construído a partir do `Page` interno. Devolver `Page<T>`
cru criaria um quinto formato sem querer: o parser do app ignora `number`/`last`
e trata ausência de `hasNext` como fim de lista.

### 1.3 Cursor para histórico e feed — acordado

Histórico e feed usam cursor, não offset: com offset, item inserido durante a
navegação faz o usuário ver registro duplicado ou pular registro.

**Confirmado pelo app:** o envelope de cursor dos endpoints **novos** é

```json
{
  "content": [],
  "nextCursor": "eyJpZCI6MTIzfQ",
  "hasNext": true
}
```

`content` e `hasNext` são idênticos aos da versão offset. O parser genérico
distingue os dois casos olhando se veio `page`/`totalElements` ou `nextCursor`.

O chat atual (`items`/`nextBeforeId`/`hasMore`) **não** é o modelo a copiar —
fica como está, junto dos outros três legados. Replicá-lo nos novos criaria o
quinto formato e derrubaria o parser único, que era o objetivo da regra 1.2.

`nextCursor` é opaco para o app. O backend escolhe a representação (id,
timestamp, blob); o app só devolve o valor na próxima página. Não há
`beforeId` no contrato novo.

`GET /api/feed` e `GET /api/feed/aluno` paginam no banco (keyset `criadoEm,id`)
e aceitam `q` opcional (título/conteúdo). `GET /api/chat/inbox/search` e
`GET /api/chat/inbox/unread` usam o envelope offset `PaginaResponse` (`content`,
`page`, `size`, `hasNext`), não array raiz. `GET /api/personal/gallery` também
— teto de 9 fotos, uma página. `POST /api/convites/gerar` invalida os unused
do personal; o token anterior deixa de validar.

`GET /api/checkin/historico` pagina no banco (keyset `iniciadoEm,id`) e aceita
`q` (nome do treino) e `status` opcionais. `GET /api/checkin/{id}` devolve a
execução do aluno autenticado. O campo `historico` do hub aluno é a primeira
página (60) do mesmo critério, não o dump. Notificação de evolução do aluno
abre `/checkin/historico/{id}` quando o payload traz `execucaoId`. `GET /api/feedback-videos`,
`/aluno/{id}` e `/me` usam offset `PaginaResponse` no banco, com `q` no
comentário. `GET /api/leads` pagina no banco com `status` e `q` (nome,
objetivo, origem).

### 1.4 `totalElements` tem custo

`totalElements` exige um `COUNT` por página. Nos 19 da lista A isso é
aceitável. Se algum se mostrar caro sob carga real, o backend avisa **antes**
de mudar, e a alternativa é omitir o campo naquele endpoint específico —
`hasNext` sozinho já sustenta a paginação. Não será omitido em silêncio. O
parser do app trata ausência como `null`, não como zero.

---

## 2. Campo `codigo` nos erros — acordado, e o app já migrou

### 2.1 A infraestrutura já existe

Nada precisa ser construído. `ApiErrorResponse` já tem os campos e o
`GlobalExceptionHandler` já os propaga:

```text
erro, status, requestId, timestamp, codigo, detalhes, upgradePlano
```

Com `@JsonInclude(NON_NULL)`, `codigo`, `detalhes` e `upgradePlano` só
aparecem quando preenchidos. **Adicionar código não muda em nada o corpo dos
erros que ainda não têm código.** O trabalho no backend é apenas passar o
código nos pontos de lançamento.

### 2.2 Shape

O campo da mensagem chama **`erro`**, não `mensagem`. O corpo real é:

```json
{
  "erro": "O recurso POSE_COACH requer plano ENTERPRISE ou superior. Faca upgrade na App Store ou Google Play.",
  "status": 403,
  "requestId": "a1b2c3",
  "timestamp": "2026-09-02T20:00:00Z",
  "codigo": "PLANO_FEATURE_REQUER_UPGRADE",
  "upgradePlano": "ENTERPRISE",
  "detalhes": { "feature": "POSE_COACH" }
}
```

`upgradePlano` diz *qual tier* oferecer. A sheet de upgrade **não** infere o
plano a partir do texto: `UpgradePromptSheet.showFromError` lê o campo e
`PlanEntitlements.lockedOffer(upgradePlano:)` o trata como fonte da verdade,
mesmo quando o mapa local de capability diria outro tier. Sem o campo, o
mapa local continua valendo — é o caminho das telas que gateiam antes de
chamar a API.

### 2.3 Catálogo inicial

Os dois primeiros já existem em produção hoje e não mudam.

#### Gate de plano — 403

| `codigo` | Origem | `upgradePlano` | `detalhes` |
|---|---|---|---|
| `IA_PLANO_INSUFICIENTE` | já existe | `PRO` | — |
| `PLANO_FEATURE_REQUER_UPGRADE` | `PlanoVerificationService` | `PRO` ou `ENTERPRISE` | `feature` |
| `PLANO_IMPORTACAO_FOTO_REQUER_UPGRADE` | `MigracaoFotoQuotaService` | `PRO` | — |

`PLANO_FEATURE_REQUER_UPGRADE` cobre as 16 features de
`PlanoVerificationService` (`IA_COPILOTO`, `WHITE_LABEL`, `LANDING_COMPLETA`,
`HABIT_COACHING`, `COMUNIDADE_PRIVADA`, `AUTOMACOES`, `AUTOMACOES_AVANCADAS`,
`COMUNIDADE_GRUPOS`, `EQUIPE_RBAC`, `LOJA_DIGITAL`, `POSE_COACH`, `FINANCEIRO`,
`RELATORIOS`, `AGENDA`, `LEADS`, `NFSE`). O nome da feature vai em
`detalhes.feature`.

#### Cota e limite — 403

| `codigo` | Origem | `detalhes` |
|---|---|---|
| `IA_QUOTA_ESGOTADA` | já existe | `limite` |
| `PLANO_LIMITE_ALUNOS_ATINGIDO` | `PlanoVerificationService` | `limite`, `plano` |
| `PLANO_LIMITE_ASSISTENTES_ATINGIDO` | `PlanoVerificationService` | `limite` |
| `MIGRACAO_FOTO_QUOTA_ESGOTADA` | `MigracaoFotoQuotaService` | `limite` |

#### Recurso já existente — 409

| `codigo` | Origem |
|---|---|
| `ALUNO_EMAIL_JA_EXISTE` | `AlunoService` |
| `EMAIL_JA_CADASTRADO` | `AuthService` |
| `EMAIL_JA_CADASTRADO_NO_ESPACO` | `AuthService` |

#### Excesso de tentativas — 429

| `codigo` | Origem |
|---|---|
| `CODIGO_EMAIL_LIMITE_HORA` | `EmailVerificationService` |
| `CODIGO_SENHA_LIMITE_HORA` | `PasswordResetService` |

#### Credenciais — 401

| `codigo` | Origem |
|---|---|
| `CREDENCIAIS_INVALIDAS` | `AuthService.loginPersonal` / `loginAluno` |
| `SENHA_ATUAL_INVALIDA` | `AuthService.definirSenhaDefinitivaAluno` |

O campo `erro` permanece `"Credenciais inválidas"` no login e
`"Senha atual inválida"` na troca da provisória. Só o `codigo` é aditivo.

Fonte no app: `lib/core/api/api_error.dart` (`ApiErrorCodes`). Código novo
entra nos dois lados no mesmo PR pareado. Código que o app ainda não conhece
**não** é tratado como "não é gate" — cai no heurístico de texto, senão um
código novo derrubaria a sheet de upgrade em silêncio.

### 2.4 Ordem obrigatória

Isto não é preferência: `isPlanGateError` decidia entre sheet de upgrade e
erro genérico procurando `requer plano`, `faça upgrade`, `faca upgrade` e
`premium` no corpo do 403. Reescrever a mensagem antes do app migrar quebrava
o gate de upgrade em silêncio.

1. Backend adiciona `codigo` **de forma aditiva**, mantendo `erro` byte a byte
   igual. *(feito no backend — lançamentos do catálogo §2.3)*
2. Backend avisa o app; este catálogo é a fonte. *(feito)*
3. App passa a usar `codigo` como fonte primária, com o match de string como
   fallback para versões antigas. *(feito —
   `lib/core/utils/friendly_error.dart`)*
4. **Só então** qualquer mensagem pode ser reescrita.

O passo 4 continua bloqueado enquanto houver versão antiga relevante em
produção. O fallback de string some quando o catálogo cobrir todos os pontos
de lançamento **e** a versão antiga sair de circulação.

**Cota não é entitlement.** `IA_QUOTA_ESGOTADA` e irmãos não abrem a sheet de
"desbloqueie o recurso" (`isPlanGateError` / `showFromError`). Distinção no
app: `isPlanGateError` vs `isPlanQuotaError`. Tela que já mostra estado
bloqueado usa `isPlanRestrictionError` (os dois) para não empilhar snackbar
de falha.

Fallback local quando `upgradePlano` não veio: `LEADS` → PRO, `NFSE` →
ENTERPRISE. Com o campo presente, ele vence o mapa.

---

Push leva `route` no `data` (tap no app empilha a rota). Sem tipo novo.

Aluno (`FcmTapPayload.ensureAluno`): mensalidade / dunning → `/financeiro/aluno`;
treino / engajamento / upsell / automação / winback / coach → `/dashboard/aluno`;
chat → `/chat/aluno`; anamnese → `/aluno/anamnese`; `plan_sync` / `trial` /
`trial_expired` → `/assinatura`; retenção → `/retencao`. Sem type+route cai
em `/dashboard/aluno`.

Personal (`FcmTapPayload.ensurePersonal`): mensalidade / dunning → `/financeiro`;
chat → `/chat/inbox`; trial / `plan_sync` / `trial_expired` → `/assinatura`;
retenção → `/retencao`. Sem type+route cai em `/dashboard/personal`.
Agenda → `/agenda`; lead / captura → `/leads`; suporte → `/suporte`;
grupo-aula → `/grupo-aulas`; anamnese preenchida → `/alunos/{id}/anamnese`.
Broadcast para aluno usa só `route=/dashboard/aluno`.

## 3. `DELETE /api/fcm/token` — confirmado, P0 fechado no servidor

### 3.1 O contrato está correto

```
DELETE /api/fcm/token
{ "token": "..." }
```

Resposta `204 No Content`. `token` é `@NotBlank`, então corpo vazio devolve
400, não no-op. Não é query param. O app já manda o token no corpo.

Ordem: a rota exige autenticação. O `DELETE` acontece **antes** do
`POST /api/auth/logout` invalidar o access token
(`AuthRepository.logout` → `FcmService.desregistrarToken`). Confirmado no
app.

### 3.2 P0 — vazamento de PII entre tenants — fechado no servidor

O `DELETE` do app cobre o caminho feliz. Os outros três casos (versão antiga,
logout offline, troca de conta sem logout) o servidor resolve no registro:
apaga qualquer linha com aquele token e insere a identidade atual. `V157`
cria unique em `token`. Um token de dispositivo pertence a exatamente uma
identidade logada por vez.

Nada disso muda o contrato. O app não faz mais nada neste item.

---

## 4. Endpoints liberados para remoção — confirmado

| Endpoint | Notas |
|---|---|
| `GET /api/chat/aluno/historico` | cru, sem `/page` |
| `GET /api/chat/historico/{alunoId}` | cru, sem `/page` |

Os gêmeos `/page` permanecem. Os `/buscar` **não** foram liberados e seguem
em uso.

---

## 5. Ordem da paginação — acordada

De 86 listas sem paginação, 59 têm consumidor no app.

- **A — 19 endpoints**, primeiro. Crescem sem teto e estão em tela de uso
  diário.
- **B — 14 endpoints**, depois.
- **C — 26 endpoints**, apenas cap de `size` no servidor. Coleção
  naturalmente limitada; não recebem envelope paginado.

Os 27 sem consumidor no app entram na meta 15 (endpoint sem consumidor), não
na fila de paginação.

Paginação continua **atrás dos P0** na fila geral. Ela é o único item grande
que exige PR pareado, e não bloqueia nenhum dos P0.

Quando o primeiro endpoint do bucket A sair, o app consome via
`Pagina.fromJson`. Não há parser paralelo a criar na hora.

---

## 6. Segurança — sem espera pelo app

Os P0 de autorização estão em endpoints que o app não chama
(`TenantMembroController`, `RbacController`, post de comunidade). Isso **não**
reduz a severidade: a vulnerabilidade continua exposta via `curl`, e atacante
não usa o app.

O que muda é só o custo: não há tela para quebrar, então a correção pode ser
agressiva e não precisa de PR pareado nem de aviso prévio.

---

## 7. Fila do lote de design — fechada

Os seis itens que travavam o lote estão fechados no backend
([PR #4](https://github.com/devmatheus1912/focux-backend/pull/4)). `erro`
não foi reescrito.

| Item | Libera | Estado |
|---|---|---|
| RBAC P0 | — (sem tela) | Fechado |
| Webhook MercadoPago | financeiro | Fechado. Resumo/somas em `BigDecimal`. JSON de dinheiro (dashboard, resumo, mensalidade, pacote, oferta, loja, plano, business, recorrência, dunning, command center) sai como **string**. Cliente lê com `FxMoney.parse` (aceita string ou número). `vencimento` da mensalidade é coluna `DATE` própria (`V161`). Create/edit aceitam `vencimento` opcional (`yyyy-MM-dd`); omitido copia `mesReferencia`. Atraso e dashboard de vencimentos usam essa coluna. Receita do mês continua em `mesReferencia`. |
| `FocuxClock` America/Sao_Paulo | S1 hubs + números de S3 | Fechado |
| Gates de plano + `codigo` | S6 paywall | Fechado |
| Timeouts IA (connect 5s / read 30s) | IA | Fechado |
| Paginação A / `PaginaResponse<T>` | S4 | Fechado. Primeiro no ar: `GET /api/alunos` |

App: `AlunoRepository.listarPagina` consome via `Pagina.fromJson`. `listar()`
drena as páginas (picker de recorrência). A lista de produto continua no BFF
`/api/alunos/home`.

`GET /api/planos/paywall/home` inclui `me` no mesmo shape de
`GET /api/planos/me`. O campo é por personal e **não** entra no cache
`planos-paywall-home` (só `planos` + `vitrine`). Null só se o tenant não
resolver. First paint de `/assinatura` lê `home.me`; fallback
`GET /api/planos/me` se `me` ausente.

`planoFeaturesProvider` não chama `/api/planos/me` quando existe snapshot
fresco de qualquer BFF (`PlanoFeaturesBffCache` ou Home) ou cache local.
`GET /api/planos/me` fica só para cold start sem cache e para `refresh`
(compra, FCM `plan_sync`).

`GET /api/planos/me` inclui `limiteLeads` (`Integer`, `null` = ilimitado).
Free / plano ausente = `5`, o mesmo teto de `LeadService`. O app não
deriva o banner de leads pelo nome `FREE`.

## 8. Desafios e alertas — acordado

`GET /api/desafios/{id}` — PERSONAL e ALUNO. Devolve o desafio mesmo com
`ativo=false` (lista `GET /api/desafios` e `GET /api/desafios/me` continua
só ativos). Deep link de encerrado deixa de ficar cego.

`GET /api/alertas/aluno/{alunoId}` (`AlertaDetalheResponse`) inclui
`motivos`, `diasSemTreino` e `aderenciaPercent` — os mesmos campos do card
da home. Sem e-mail.

`GET /api/habitos/{id}` — PERSONAL e ALUNO. Devolve o hábito mesmo com
`ativo=false` (listas `GET /api/habitos/home` e `GET /api/habitos/me`
continuam só ativos). A resposta inclui `ativo`. Deep link / FCM de
desativado deixa de ficar cego.

