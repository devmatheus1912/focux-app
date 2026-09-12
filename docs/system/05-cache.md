# 05 — Cache

**Normativo.** Primer: cache-aside, write-through, TTL, invalidation.

## Regras

1. **Padrão = cache-aside.** Lê cache → miss → DB → popula. Write atualiza DB e **invalida** (não “esqueci o evict”).
2. **TTL explícito** em todo cache nomeado (Caffeine BFF, prefs locais não-PII).
3. **Multi-instância:** se Redis ligado, invalidação distribuída no writer; senão assume single-node e documenta.
4. **Proibido cachear entitlement pago** (`planoValidoAte`, feature gates) sem invalidação no webhook/IAP/expiry.
5. **FE:** freshness visível (§13); limpar caches de tenant no logout.
6. **Não usar cache para esconder N+1** — corrija a query.

## Por quê

Cache sem evict serve mentira. Entitlement stale = PRO grátis ou feature sumindo. O primer lista padrões; Focux escolhe cache-aside por simplicidade no monólito.

## Onde no código

- BFF Caffeine: home / Aluno 360 (ver README backend)
- Evictors: ex. `DunningHomeCacheEvictor`
- App: wipe de tenant BFF no logout; prefs não-PII ok

## Gate

- [ ] Todo `@Cacheable` tem caminho de evict no writer listado na proposta §22.
- [ ] Logout limpa estado de tenant no app.
- [ ] Scorecard P1 se freshness ausente em hub com cache.
