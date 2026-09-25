# Focux Referral System — Indique e Ganhe

Documento de operação do programa de indicação entre personals. Desenho completo em
`docs/superpowers/specs/2026-09-24-referral-core-design.md`. Segurança e antifraude em
`FOCUX_REFERRAL_SECURITY.md`.

## Regra comercial (campanha `REFERRAL_PERSONAL` v1)

| Parâmetro | Valor v1 | Coluna em `campanhas` |
|---|---|---|
| Dias para quem indica, por conversão | 30 | `dias_indicador` |
| Desconto para o indicado (1ª cobrança Mercado Pago) | 20% | `desconto_indicado_pct` |
| Máximo de recompensas por indicador | 3 | `max_recompensas` |
| Teto de dias por indicador | 90 | `teto_dias` |
| Carência de indicação com risco alto | 7 dias | `carencia_risco_dias` |
| Cadastros em 24h antes de marcar rajada | 5 | `rajada_max_24h` |

- Só conta **pagamento real confirmado pelo backend**: webhook Mercado Pago assinado, recibo
  Apple/Google verificado ou ativação Enterprise. Trial nunca conta.
- A 4ª conversão (ou a que estouraria o teto) é registrada como `CONVERTED_NO_REWARD` com 0 dias.
- O app não conhece nenhum desses números: tudo vem de `GET /api/referral`.

## Campanhas versionadas

- Tabela `campanhas`, criada e semeada pela migration `V179__referral_core.sql`.
- No máximo **uma** campanha ativa por `chave` (índice único parcial).
- Mudar regra = nova migration com nova `versao` e desativação da anterior. Não existe painel admin.
- Cada indicação guarda um **snapshot** (`snap_*`) da campanha no momento do cadastro. Mudar a
  campanha nunca altera indicações antigas.
- Sem campanha vigente: cadastro com código continua funcionando, mas não gera indicação; o painel
  mostra "Campanha pausada".

## Máquina de estados

```
ATTRIBUTED ─► TRIAL ─► (CONVERTED) ─► REWARD_GRANTED ─► REVERSED
     │           │           ├──────► REWARD_HELD ─► REWARD_GRANTED | BLOCKED | REVERSED
     │           │           ├──────► CONVERTED_NO_REWARD ─► REVERSED
     │           │           └──────► BLOCKED
     └───────────┴─► INVALID
```

- `CONVERTED` é um passo do histórico: a linha em `referrals` vai direto para o estado final.
- Estados terminais: `BLOCKED`, `REVERSED`, `INVALID`.
- Toda transição passa por `ReferralJournal` e grava um evento em `referral_eventos`.
- Transição fora do grafo lança erro (falha fechada).

## Fluxo

1. **Cadastro** (`AuthService`) chama `ReferralAttributionService.atribuir`. Código inválido,
   próprio código ou falta de campanha são ignorados sem quebrar o cadastro.
2. **Trial** (`TrialService.startTrial`) registra `TRIAL`. Não gera recompensa.
3. **Pagamento** (webhook MP, IAP, Enterprise) chama `ReferralConversionService.onPagamentoConfirmado`
   na mesma transação do pagamento.
4. **Decisão** (`ReferralRewardPolicy`, função pura): `GRANT`, `HOLD`, `CAP_ZERO` ou `BLOCK`.
5. **Liberação**: `ReferralReleaseScheduler` (ShedLock `referral_release`, a cada hora) libera
   `REWARD_HELD` cuja carência venceu.
6. **Reversão**: webhook MP `refunded` / `charged_back` chama `onPagamentoRevertido`.

## Ledger e idempotência

- `referral_ledger` é append-only. Tipos: `GRANT`, `HOLD`, `RELEASE`, `REVERSAL`, `CAP_ZERO`.
- Chave de idempotência `referral:<id>:<TIPO>` e UNIQUE `(referral_id, tipo)`.
- Dias ganhos = soma de `GRANT + RELEASE + REVERSAL`. `HOLD` só reserva a vaga.
- Webhook reentregue: a indicação já saiu de `ATTRIBUTED/TRIAL`, então o reprocessamento é ignorado.

## Concorrência

- Ordem fixa de trava: linha do código do indicador (`referral_codigos`, `SELECT ... FOR UPDATE`)
  e depois a indicação. Conversões do mesmo indicador são serializadas.
- Barreira final: UNIQUE `(indicador_id, posicao_recompensa)`. Violação vira
  `ReferralConflictException` (sem causa encadeada), o webhook responde erro e o gateway reenvia.
- Teste: `ReferralEngineIntegrationTest.concorrencia_*` (10 conversões simultâneas = exatamente 3
  recompensas nas posições 1, 2 e 3).

## Reembolso e chargeback

| Evento | Dias | Vaga | Efeito extra |
|---|---|---|---|
| Reembolso de recompensa concedida | removidos (validade nunca fica antes de agora) | liberada | — |
| Chargeback de recompensa concedida | removidos | **mantida** | próximas conversões do indicador ficam com risco `HIGH` |
| Reversão de retida ou sem recompensa | 0 | reembolso libera, chargeback mantém | — |

## Desconto do indicado (Mercado Pago)

- `PagamentoService` aplica o desconto do snapshot na 1ª cobrança (preference e preapproval) e marca
  a `external_reference` como `personalId:planoId:ind`.
- O webhook só aceita valor com desconto quando há marcador **e** a indicação ainda autoriza
  (pendente, ou a própria cobrança que converteu). Sem isso, o pagamento é recusado como valor inválido.
- Na assinatura recorrente, depois da 1ª cobrança o valor volta ao preço cheio via
  `atualizarValorRecorrente` (após o commit).
- Apple/Google: oferta nativa da loja, configurada no console (ciclo 3).

## API

| Método | Rota | Uso |
|---|---|---|
| GET | `/api/referral` | Painel do personal logado: código, link, progresso, lista mascarada |
| GET | `/api/referral/validar/{codigo}` | `{ "valido": true/false }`, sem expor o dono |

Status de exibição na lista: `PENDING`, `TRIAL`, `REWARD_GRANTED`, `UNDER_REVIEW`, `NO_REWARD`,
`REVERSED`, `NOT_ELIGIBLE`. Risco e motivo nunca saem do servidor.

## App

- Tela `/referral` (`lib/features/referral`). Estados: carregando, erro, sem código, lista vazia,
  pendente, trial, em análise, concedida, sem recompensa, estornada, não elegível, limite atingido e
  campanha pausada.
- Strings em `lib/l10n/app_{pt,en,es}.arb` (prefixo `referral`).
- Analytics: `referral_viewed`, `referral_link_shared`, `referral_link_copied`,
  `referral_help_opened`, `referral_load_failed`.

## Legado (backfill da V179)

- Indicações antigas viraram `origem = LEGACY`. As convertidas contam no limite de 3, na ordem de
  conversão. Ninguém perde dias já recebidos.
- Colunas antigas `personais.referral_codigo_usado` e `personais.referral_conversao_processada`
  continuam no banco (rollback seguro), mas a aplicação não lê nem escreve mais nelas. Remover numa
  migration futura depois de uma release estável.
- `referral_codigos.usos_totais` também ficou sem uso na aplicação.

## Runbook

Consultas de apoio (rodar no Postgres com role de serviço):

```sql
-- Retidas aguardando liberação
SELECT id, indicador_id, liberar_em, risco_motivo FROM referrals
WHERE status = 'REWARD_HELD' ORDER BY liberar_em;

-- Histórico de uma indicação
SELECT * FROM referral_eventos WHERE referral_id = :id ORDER BY id;
SELECT * FROM referral_ledger  WHERE referral_id = :id ORDER BY id;
```

**Bloquear uma retida suspeita antes da carência:** marcar o risco. O job move para `BLOCKED` e
libera a vaga.

```sql
UPDATE referrals SET risco = 'BLOCKED', risco_motivo = 'REVISAO_MANUAL', atualizado_em = now()
WHERE id = :id AND status = 'REWARD_HELD';
```

**Liberar uma retida antes da carência:** antecipar `liberar_em`; o próximo ciclo do job concede.

```sql
UPDATE referrals SET liberar_em = now(), atualizado_em = now()
WHERE id = :id AND status = 'REWARD_HELD';
```

Nunca editar `referral_ledger` nem `status` à mão: correção é sempre um novo evento pela aplicação.

## Limitações conhecidas

- **Estorno em loja (Apple/Google)** ainda não chega ao backend. Falta App Store Server
  Notifications e Google RTDN (ciclo 3).
- **Trial da loja que vira pagamento** só converte quando o app reenviar o recibo pago ou quando as
  notificações de loja existirem.
- Ofertas de desconto nas lojas dependem de configuração no App Store Connect e no Play Console.
- A validade do plano do indicador (`personais.plano_valido_ate`) não tem versionamento otimista;
  uma escrita concorrente de outro fluxo no mesmo instante pode sobrescrever a outra.
