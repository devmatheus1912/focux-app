# 09 — Observabilidade

**Normativo.** Sem métricas, “escalar” é chute.

## Regras

1. **Logs estruturados** com requestId; sem PII desnecessária (tokens, corpo de anamnese).
2. **Crashlytics no app:** overflow/layout não silenciados (§39).
3. **Actuator:** endpoints sensíveis protegidos; `/info` não vaza secret (SHA ok, LOW).
4. **Antes de evoluir infra**, medir: p95 API hot paths, error rate webhooks, tamanho DB, conexões PG, hit rate cache.
5. **Alertas mínimos:** webhook FAILED em massa; job ShedLock stuck; 5xx spike.

## Por quê

O primer e blogs de empresa repetem: não otimize o que não mede. Observabilidade barata evita Kafka “por medo”.

## Onde no código

- Logging Spring + requestId no `GlobalExceptionHandler`
- Actuator/Prometheus (README backend)
- Crashlytics / FCM no app

## Gate

- [ ] Feature P0 money tem log de sucesso/falha reconciliável (payment id).
- [ ] Job crítico loga contagem processada.
- [ ] Não abrir `/actuator` público em prod.
