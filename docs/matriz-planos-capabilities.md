# Matriz oficial — planos e capabilities (Focux Personal)

**Fonte de verdade:** tabela `planos_saas` + endpoint `GET /api/planos/me`.  
O app **não** deve inventar features fora desta matriz.

## Tiers

| Capability | FREE | PREMIUM | ENTERPRISE | ENTERPRISE PRO |
|------------|------|---------|------------|----------------|
| Alunos ativos | 5 | 20 | ilimitado | ilimitado |
| Treinos / check-in / exercícios | sim | sim | sim | sim |
| Agenda | básica | completa | completa | completa |
| Financeiro + CRM | não | sim | sim | sim |
| Relatórios avançados | não | sim | sim | sim |
| IA Copiloto | não | sim (cota/mês) | sim | sim |
| IA ilimitada + RAG | não | não | sim | sim |
| White-label e identidade visual | não | não | sim | sim |
| Landing page COMPLETA | não | não | não | sim |
| Preço (BRL) | 0 | 79 | 149,90 | 199,90 |

## SKUs loja (mobile)

| Plano | Mensal | Anual (−20% vs 12× mensal) |
|-------|--------|---------------------------|
| Premium | `focux_premium_monthly` | `focux_premium_yearly` |
| Enterprise | `focux_enterprise_monthly` | `focux_enterprise_yearly` |
| Enterprise Pro | `focux_enterprise_pro_monthly` | `focux_enterprise_pro_yearly` |

Criar os **seis** SKUs como assinatura auto-renovável nas consoles. O app abre com **Anual** pré-selecionado.

## UX de venda

- Paywall único: `/assinatura` (`/planos` redireciona).
- Gates por `capability` no `FeatureGate`.
- Aviso soft em 80% de alunos ou IA; hard stop no backend.
- CTA contextual: “Assinar Premium para Financeiro”, etc.

*Atualizado em maio/2026.*
