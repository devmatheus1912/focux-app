# 06 — Async

**Normativo.** Primer: message queues, task queues, back pressure. Focux hoje: **schedulers + webhooks**, não Kafka.

## Regras

1. **Jobs `@Scheduled` com ShedLock** — uma instância executa; lockAtMost/AtLeast explícitos.
2. **Webhooks fail-closed** (HMAC / secret). Replay: UNIQUE `(provider, event_id)` em `webhook_events`.
3. **SaaS só com captura:** grant via fatura `payment.status=approved` (`grantFromAuthorizedPayment`). Status `authorized` do preapproval = lifecycle only.
4. **Dunning não faz pause/reativar MP** como substitute de invoice. Notifica; MP retenta sozinho.
5. **FCM best-effort:** falha de push não reverte write de negócio; payload navega com sanitize no app.
6. **Backpressure:** rate limit em endpoints que disparam fan-out; jobs não enfileiram trabalho sem teto.
7. **Cliente não mint `FOCUX_SUBSCRIPTION`** em `/api/dunning/registrar-falha` — só webhook/interno.

## Por quê

Fila dedicada adiciona ops. Schedulers + idempotência cobrem o volume atual. O bug histórico (reativar → webhook authorized → +1 mês grátis) prova por que async sem prova de pagamento é P0.

## Onde no código

- `TrialExpirationJob`, `OutboxProcessorJob`, dunning `executarRetentativas`
- `WebhookController`, `SubscriptionAccessGrant`
- `DunningService`, `DunningController`
- `FcmService`

## Gate

- [ ] Webhook novo: assinatura + idempotência + teste de replay.
- [ ] Nenhum job “cura” plano pago sem payment/IAP.
- [ ] ShedLock presente em cron que muta dado.
