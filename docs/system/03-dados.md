# 03 — Dados

**Normativo.** Primer: RDBMS, replication, sharding, denormalization — **só adotamos o que o Focux precisa agora**.

## Regras

1. **Postgres é o SSOT.** Toda entidade de negócio persistida lá (Flyway).
2. **Tenant por `personalId` (e `alunoId` quando papel aluno).** Queries: `findByIdAndPersonalId` / equivalente. JWT de aluno traz `personalId` do trainer — **nunca** tratar isso como autoridade de personal.
3. **Dinheiro = `BigDecimal`** com escala definida. Proibido `double`/`float` em cobrança.
4. **Transação no write sensível** (pagamento, plano, exclusão LGPD, seats).
5. **Índice para caminho quente** (lista por personal, webhook event id único). Sem índice “por precaução” em coluna morta.
6. **Sem sharding / federation** até gatilho em `10-evolucao`. Um banco, um writer.
7. **Denormalização** só com dono de write único e teste de inconsistência.

## Por quê

RDBMS dá consistência forte e joins que o domínio fitness precisa (aluno↔treino↔mensalidade). Sharding cedo multiplica ops sem carga que justifique.

## Onde no código

- Entidades: `Personal`, `Aluno`, módulos `financeiro`, `pagamentos`, `planos`
- AuthZ tenant: `TenantContext`, repositórios `*AndPersonalId*`
- Entitlement: `PlanoEntitlement`, `planoValidoAte`, `TrialExpirationJob` (limpa `mpPreapprovalId` no revert)
- Migrações: `focux-backend` Flyway `V*`

## Gate

- [ ] Nenhum endpoint `hasAnyRole(PERSONAL,ALUNO)` confia só em `personalId != null` para write de peer.
- [ ] Proposta §22 lista tabela + índice + risco de N+1.
- [ ] Money fields tipados; webhook idempotente (`webhook_events` UNIQUE).
