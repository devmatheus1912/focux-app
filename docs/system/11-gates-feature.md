# 11 — Gates de feature

**Normativo.** Checklist obrigatório ao desenhar feature nova (FE+BE). Ruflo não shipa sem marcar.

## Checklist

### Produto / UI
- [ ] Tipo S# + job §36 (amplitude e profundidade)
- [ ] Quatro estados (§13); voltar (§14.1); teclado (§14.2)
- [ ] Decisão ship/hide/delete (§38) se satélite raso

### Contrato / dados
- [ ] Envelope API conforme [04-api](04-api.md) + CONTRATO
- [ ] Tenant filters ([03-dados](03-dados.md))
- [ ] Money: BigDecimal + idempotência se aplicável

### Sistema
- [ ] Trade-off de consistência explícito ([01-tradeoffs](01-tradeoffs.md))
- [ ] Cache: TTL + evict ou “sem cache” justificado ([05-cache](05-cache.md))
- [ ] Async: ShedLock / webhook HMAC / sem grant fantasma ([06-async](06-async.md))
- [ ] Mídia: sem SSRF ([07-media-cdn](07-media-cdn.md))
- [ ] Segurança §20 + [08](08-seguranca-sistema.md)
- [ ] Log/métrica mínima ([09-observabilidade](09-observabilidade.md))
- [ ] Sem infra nova sem [10-evolucao](10-evolucao.md)

### Freeze
- [ ] Analyze / testes do caminho
- [ ] Proposta §22 se BE tocado
- [ ] Mortos removidos (dead-code-cleanup)

## Saída no chat

Uma linha no scorecard: `system: 11-gates ok | gaps: …`
