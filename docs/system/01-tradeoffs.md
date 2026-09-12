# 01 — Trade-offs

**Normativo.** Fonte conceitual: [System Design Primer — Performance vs scalability / Latency / CAP](https://github.com/donnemartin/system-design-primer).

## Regras

1. **Dinheiro, tenant, entitlement e LGPD = consistência forte.** Leitura/escrita no Postgres na mesma transação quando o resultado muda acesso pago ou ownership.
2. **Feed, FCM, freshness de UI = eventual ok.** Pode atrasar segundos; nunca mentir status de pagamento.
3. **Otimize latência do caminho crítico do aluno** (check-in, chat, agenda) antes de “escalar horizontalmente”.
4. **Throughput sem correção de dado é dívida.** Duplicar cobrança para “não perder request” é proibido.

## Por quê

O primer ensina que tudo é trade-off: sistemas podem ser rápidos numa máquina (performance) e ainda falhar com mais usuários (scalability). CAP: sob partição, escolhemos CP em dinheiro (recusar/esperar) em vez de AP (servir plano errado).

## Onde no código

| Domínio | Consistência | Evidência |
|---------|--------------|-----------|
| Assinatura SaaS | Forte (só fatura capturada) | `WebhookController.grantFromAuthorizedPayment`, `SubscriptionAccessGrant` |
| Entitlement gates | Forte no BE | `PlanoEntitlement`, feature gates |
| Tenant | Forte | `TenantContext`, `findByIdAndPersonalId` |
| Notificações | Eventual | `FcmService` |
| Dunning retry | Não substitui pagamento | `DunningService.tentarRetryMercadoPago` (skip pause/reativar) |

## Gate

- [ ] Money path tem prova de captura ou IAP verify — nunca status de lifecycle sozinho.
- [ ] Scorecard §22 marca P0 se UI esconde inconsistência de plano/tenant.
- [ ] Não há “retry que reabre PRO” sem fatura `payment.status=approved`.
