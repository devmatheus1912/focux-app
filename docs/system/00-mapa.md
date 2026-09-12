# 00 — Mapa: primer → Focux

**Normativo.** Constitui a Parte VIII do [FOCUX_DESIGN_REFERENCE.md](../FOCUX_DESIGN_REFERENCE.md). Em conflito, o índice canônico vence.

## Origem

Conceitos e vocabulário de trade-offs vêm do [System Design Primer](https://github.com/donnemartin/system-design-primer) (Donne Martin et al.), licença **CC BY-SA 4.0**. Não copiamos o README: traduzimos em **decisões Focux** para a topologia real (Flutter + Spring monolítico + Postgres + Redis + Cloudinary + webhooks).

## Como usar

1. Classifique a tela/feature (taxonomia S1–S9 + job §36).
2. Antes de endpoint novo, money path, cache ou job async: leia o capítulo relevante abaixo e marque o gate em `11-gates-feature.md`.
3. Cite o capítulo no scorecard / proposta §22 (“system: 05-cache”).

## Índice da árvore

| Cap | Arquivo | Quando abrir |
|-----|---------|--------------|
| 01 | [tradeoffs](01-tradeoffs.md) | Consistência vs disponibilidade; latência |
| 02 | [topologia](02-topologia.md) | Onde vive cada peça hoje |
| 03 | [dados](03-dados.md) | Postgres, tenant, dinheiro, índices |
| 04 | [api](04-api.md) | REST, paginação, idempotência, timeouts |
| 05 | [cache](05-cache.md) | TTL, evict, freshness FE |
| 06 | [async](06-async.md) | Schedulers, webhooks, FCM |
| 07 | [media-cdn](07-media-cdn.md) | Cloudinary, MoveKit, SSRF |
| 08 | [seguranca-sistema](08-seguranca-sistema.md) | HMAC, JWT, pins, secrets |
| 09 | [observabilidade](09-observabilidade.md) | Logs, health, métricas de escala |
| 10 | [evolucao](10-evolucao.md) | Gatilhos para crescer infra |
| 11 | [gates-feature](11-gates-feature.md) | Checklist obrigatório de feature |

Contrato pareado app↔API: [CONTRATO_APP_BACKEND.md](../CONTRATO_APP_BACKEND.md).

## Glossário curto

| Termo | No Focux |
|-------|----------|
| SSOT de produto | Este índice + árvore `docs/system/` |
| SSOT de dado | Postgres (entidades por `personalId` / `alunoId`) |
| Entitlement | `PlanoEntitlement` + `planoValidoAte` / trial |
| Capture proof | Pagamento MP com `payment.status=approved` (não status `authorized` do preapproval) |
| Fail-closed | Webhook/HMAC/captcha: sem secret válido → rejeita |

## Atribuição

Trechos conceituais adaptados de *The System Design Primer* © Donne Martin, CC BY-SA 4.0. Decisões normativas e exemplos de código são © Focux.
