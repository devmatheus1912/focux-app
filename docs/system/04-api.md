# 04 — API

**Normativo.** Primer: REST, communication. Contrato detalhado: [CONTRATO_APP_BACKEND.md](../CONTRATO_APP_BACKEND.md).

## Regras

1. **REST JSON** sob `/api/**`. STOMP só para canais allowlisted (chat).
2. **Envelope de paginação** do CONTRATO para endpoints **novos** (`content`, `page`, `size`, `totalElements`, `hasNext`). Não devolver `Page<T>` Spring cru.
3. **Cursor** para feed/histórico novos (`content`, `nextCursor`, `hasNext`).
4. **Timeouts** em todo cliente HTTP outbound (IA, MP, Cloudinary). Loading infinito = regressão (A23 de rede).
5. **Rate limit** em mutações sensíveis (`@RateLimit` / Resilience4j).
6. **Idempotência** em webhook, PIX, IAP, ações financeiras repetíveis (header ou event id persistido).
7. **Validação na borda** (DTO + Bean Validation). Mass assignment de `role`/`plan`/`personalId` pelo client = P0.
8. **Versionamento**: campos novos backward-compatible; breaking change = PR pareado app+BE.

## Por quê

Contrato estável reduz churn mobile. Idempotência evita crédito duplicado sob retry (primer: asynchronism + retries).

## Onde no código

- Controllers `*Controller.java`; DTOs de request
- Webhooks: `WebhookController` + `webhook_events`
- App: `lib/core/api/`, parsers de página
- Rate limit: anotações em dunning/auth/upload

## Gate

- [ ] Endpoint novo documentado no CONTRATO ou justificado legado.
- [ ] Mutação financeira tem chave de idempotência + teste de replay.
- [ ] Client HTTP BE tem timeout; FE trata erro/retry sem freeze.
