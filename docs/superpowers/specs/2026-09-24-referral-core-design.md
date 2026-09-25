# Indique e Ganhe — ciclo 1: núcleo (design)

Data: 2026-09-24 · Status: aprovado no brainstorming · Repos: `focux-backend` (principal), `focux-app` (ajuste mínimo)

## 1. Objetivo

Substituir o bônus atual de indicação (flag booleana + `+30 dias` fixo no código, sem limite) por um núcleo
auditável: campanha versionada no servidor, ledger append-only, limite de recompensas por indicador,
idempotência por evento de gateway, proteção contra concorrência, antifraude com retenção e reversão por
reembolso/chargeback do Mercado Pago.

## 2. Decomposição (ciclos)

| Ciclo | Escopo |
|-------|--------|
| **1 (este)** | Núcleo backend + ajuste mínimo na tela atual |
| 2 | Desconto do indicado no checkout Mercado Pago (valor calculado no servidor a partir do snapshot) |
| 3 | Reembolso/revogação via lojas (App Store Server Notifications, Google RTDN) + ofertas nativas das lojas para o desconto |
| 4 | Tela premium completa (todos os estados, i18n, analytics `referral_*`) |

Fora do ciclo 1: desconto do indicado, notificações das lojas, painel admin (não haverá painel), revogação do
acesso do próprio indicado após reembolso (regra de billing).

## 3. Regras comerciais (valores iniciais da campanha, nunca no código)

- Indicador ganha `dias_indicador` (30) por conversão elegível.
- Indicado terá `desconto_indicado_pct` (20) — aplicado a partir do ciclo 2.
- Máximo `max_recompensas` (3) por indicador e `teto_dias` (90) no total.
- Trial nunca conta. Só pagamento real confirmado pelo backend (webhook MP ou recibo de loja verificado).
- Conversão acima do limite é registrada com 0 dias.

## 4. Abordagem

Síncrona, dentro da transação do pagamento. Um único ponto de trava por indicador (`SELECT … FOR UPDATE` na
linha de `referral_codigos` do indicador) e constraints `UNIQUE` como segunda barreira. Se o pagamento sofrer
rollback, a indicação também sofre. Alternativas descartadas: outbox assíncrono (mais peças, consistência
eventual) e lock otimista com retry (frágil sob concorrência).

## 5. Modelo de dados (migration V179, todas as tabelas com `ENABLE ROW LEVEL SECURITY`)

### `campanhas`
`id`, `chave` (ex.: `REFERRAL_PERSONAL`), `versao`, `ativa`, `inicio_em`, `fim_em` (nullable),
`dias_indicador`, `desconto_indicado_pct`, `max_recompensas`, `teto_dias`, `carencia_risco_dias`, `criado_em`.
`UNIQUE(chave, versao)`; `CHECK` de valores positivos e `desconto_indicado_pct` entre 0 e 100.
Uma única versão ativa por chave, garantida no serviço e coberta por teste. Seed da versão 1 na migration.
Alteração = nova versão por migration (SQL versionado e revisado). Sem endpoint de admin.

### `referral_codigos` (existente)
- Códigos existentes continuam válidos.
- Novos códigos: 10 caracteres base32 Crockford (sem `I L O U`), ~50 bits, gerados com `SecureRandom`.
- É a linha travada por indicador.
- `usos_totais` deixa de ser fonte da verdade (contagem vem do ledger).

### `referrals` (uma por indicado)
`id`, `codigo_id`, `indicador_id`, `indicado_id UNIQUE`, `campanha_id`, snapshot (`snap_dias_indicador`,
`snap_desconto_pct`, `snap_max_recompensas`, `snap_teto_dias`, `snap_carencia_dias`), `status`, `risco`,
`posicao_recompensa` (1..max, nullable), `conversao_gateway_evento_id`, `origem`, `criado_em`,
`atualizado_em`, `convertido_em`.
- `CHECK (indicador_id <> indicado_id)`.
- `CHECK` de `status` e `risco` (`LOW`, `MEDIUM`, `HIGH`, `REVIEW`, `BLOCKED`).
- `UNIQUE(indicador_id, posicao_recompensa)` — impede fisicamente recompensas além das posições.

### `referral_eventos` (append-only)
`id`, `referral_id`, `de_status`, `para_status`, `motivo`, `origem` (`MP`, `APPLE`, `GOOGLE`, `SISTEMA`,
`LEGACY`), `gateway_evento_id`, `criado_em`. `UNIQUE(referral_id, para_status, gateway_evento_id)`.

### `referral_ledger` (append-only, sem UPDATE/DELETE no código)
`id`, `indicador_id`, `referral_id`, `tipo` (`GRANT`, `HOLD`, `RELEASE`, `REVERSAL`, `CAP_ZERO`), `dias`
(com sinal), `liberar_em`, `idempotency_key UNIQUE`, `criado_em`.
Saldo de dias e número de recompensas = soma do ledger lida sob a trava.

### Limpeza e legado
- `DROP TABLE referral_conversoes` (V52, sem uso).
- Backfill: para cada `personais` com `referral_conversao_processada = true` e código válido, cria
  `referrals` com origem `LEGACY`, ordenadas por data; posições 1..3 como `REWARD_GRANTED` + ledger `GRANT`;
  excedentes como `CONVERTED_NO_REWARD` + `CAP_ZERO`. Nenhum dia já concedido é removido.

## 6. Máquina de estados

```
ATTRIBUTED ─→ TRIAL ─→ CONVERTED
ATTRIBUTED ──────────→ CONVERTED
CONVERTED  → REWARD_GRANTED | REWARD_HELD | CONVERTED_NO_REWARD | BLOCKED
REWARD_HELD → REWARD_GRANTED | BLOCKED | REVERSED
REWARD_GRANTED → REVERSED
CONVERTED_NO_REWARD → REVERSED
INVALID (autoindicação / atribuição rejeitada) — terminal
```

`CONVERTED` é transitório dentro da mesma transação (registrado no histórico, nunca persistido como estado
final).

Transições fora deste grafo lançam exceção e são cobertas por teste.

## 7. Fluxos

### Atribuição (cadastro)
`AuthService` chama `ReferralAttributionService.atribuir(indicado, codigo, sinais)`.
- Sinais: IP, e-mail e telefone normalizados, CPF se houver.
- Código inválido: ignorado em silêncio, sem quebrar o cadastro.
- Autoindicação (mesmo personal ou sinal forte de mesma pessoa): `INVALID`, auditado.
- Válido: `ATTRIBUTED` + snapshot da campanha ativa + risco inicial.
- `GET /api/referral/validar/{codigo}`: responde só válido/inválido, sem ecoar o código; rate limit mantido.
- Início de trial do indicado: evento `TRIAL` (informativo, nunca converte).

### Conversão
`ReferralConversionService.onPaymentConfirmed(indicadoId, origem, gatewayEventId, valorPago, trial)` substitui
`processarBonusPrimeiraAssinatura` nos três pontos: `WebhookController` (pagamento avulso e
`authorized_payment`) e `IapController.verify`. Chamado após o `claimSaasCredit`/idempotência existentes.

1. Trava a linha do código do indicador (único ponto de trava; ordem fixa evita deadlock).
2. Status diferente de `ATTRIBUTED`/`TRIAL` → no-op (webhook repetido).
3. `trial = true` ou `valorPago <= 0` → não converte.
4. Recompensas concedidas + retidas ≥ `snap_max_recompensas`, ou dias + `snap_dias_indicador` >
   `snap_teto_dias` → `CONVERTED_NO_REWARD` + `CAP_ZERO` (0 dias).
5. Risco `BLOCKED` → `BLOCKED`.
6. Risco `HIGH` ou `REVIEW` → `REWARD_HELD` + `HOLD` com `liberar_em = agora + snap_carencia_dias`; posição reservada.
7. Caso contrário → `REWARD_GRANTED` + `GRANT`; `planoValidoAte = max(agora, planoValidoAte) + dias`.

FCM e auditoria rodam em `afterCommit`, com chave idempotente.

### Liberação (job com ShedLock, de hora em hora)
`REWARD_HELD` vencidas e sem reversão: trava o indicador, `RELEASE`, aplica dias, `REWARD_GRANTED`.

### Reversão (Mercado Pago)
Webhook passa a tratar status `refunded` e `charged_back` via `onPaymentReversed(gatewayPaymentId, motivo)`,
idempotente por claim do evento.
- Retida → `REVERSED`, nenhum dia concedido.
- Concedida → `REVERSAL` com dias negativos; `planoValidoAte` reduzido, nunca antes de agora.
- **Reembolso libera a posição; chargeback não libera** e eleva o risco das próximas indicações do indicador.

## 8. Antifraude

Sinais calculados no servidor: mesmo IP de cadastro do indicador, mesmo e-mail/telefone normalizado ou CPF,
rajada de cadastros com o mesmo código em janela curta, chargeback anterior do indicador.
- Sinal forte de mesma pessoa → `BLOCKED`.
- Sinais fracos acumulados → `HIGH` (retenção com liberação automática).
- `REVIEW` tem o mesmo tratamento de `HIGH` no ciclo 1 (retenção); existe para distinguir casos marcados
  manualmente via runbook.
- Demais → `LOW`/`MEDIUM`.
Tudo auditado. Correção manual só por SQL/runbook documentado.

## 9. Segurança

- Nenhuma regra comercial no Flutter; o app só exibe dados do servidor.
- Operações sob `TenantContext` + `@PreAuthorize("hasRole('PERSONAL')")`; um personal só vê as próprias
  indicações, com nome do indicado mascarado.
- Rate limit em `validar`, `GET /api/referral` e cadastro com código.
- Webhook mantém HMAC e claim de evento; reversão usa o mesmo mecanismo.
- Sem logs de e-mail, telefone, CPF, tokens ou valores. Transições relevantes em `AuditoriaService`.
- Sem dependência nova. Repositório público: nenhum segredo, host autenticado ou dado real em código,
  testes ou docs.

## 10. API

`GET /api/referral` (compatível, com campos novos):
`codigo`, `link`, `recompensasConcedidas`, `maxRecompensas`, `diasGanhos`, `tetoDias`, `diasPorIndicacao`,
`descontoIndicadoPct`, `limiteAtingido`, `usosTotais` (alias temporário) e
`indicacoes[]` com `nomeMascarado`, `status` (`PENDING`, `TRIAL`, `CONVERTED`, `REWARD_GRANTED`,
`REWARD_HELD`, `NO_REWARD`, `REVERSED`) e `data`.

## 11. App (ajuste mínimo)

Tela `/referral` mostra "X de N recompensas · Y de M dias" com valores do servidor, estado de limite
atingido e lista simples de indicações. Textos novos em `app_pt.arb`, `app_en.arb`, `app_es.arb`.

## 12. Testes

Backend (`./gradlew test`), cobrindo os 40 obrigatórios, com destaque para:
- **Concorrência crítica**: 10 conversões paralelas do mesmo indicador → exatamente 3 `GRANT` e 7 `CAP_ZERO`.
  Se o H2 não reproduzir a trava fielmente, as constraints `UNIQUE` sustentam o limite e o teste as verifica.
- Webhook repetido, trial, autoindicação, código inválido, snapshot não retroativo, teto de dias,
  retenção/liberação, reembolso vs. chargeback, transições inválidas, backfill legado,
  `MigrationRlsContractTest`, isolamento entre personais.

App: repositório (parse do novo payload) e estados da tela.

## 13. Documentação da implementação

`focux-app/docs/FOCUX_REFERRAL_SYSTEM.md` e `focux-app/docs/FOCUX_REFERRAL_SECURITY.md`.
