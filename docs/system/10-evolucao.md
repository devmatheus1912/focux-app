# 10 — Evolução

**Normativo.** Checklist do que **ainda não** fazemos — e quando reconsiderar.

## Ainda não (default)

| Ideia do primer | Status Focux | Gatilho para reabrir |
|-----------------|--------------|----------------------|
| Microsserviços | Não | Domínio com equipe dedicada + deploy independente justificado |
| Kafka / SQS | Não | Webhooks/jobs saturam ShedLock ou backlog > SLO |
| PG read replica | Não | p95 leitura > objetivo com índices já ok |
| Sharding | Não | Single primary não cabe verticalmente |
| Multi-region | Não | Requisitos legais/latência multi-país medidos |
| Redis Cluster obrigatório | Não | >1 instância API + cache stale comprovado |
| CDN edge HTML | Landing pontual | Cache confusion / Host issues resolvidos |

## Regras

1. **Proposta de infra nova** cita métrica de `09-observabilidade` + custo.
2. **Não fatiar monólito** só para “parecer scale-up”.
3. **Horizontal scaling da API** (mais réplicas Railway) é o primeiro passo — sessão/STOMP/Redis alinhados.

## Gate

- [ ] PR de infra tem gatilho mensurável ou é rejeitado.
- [ ] Doc de topologia atualizado no mesmo ship.
