---
name: ruflo
description: Reimplementa o Focux do zero até a loja (pele, anatomia S1–S9, job, profundidade, voltar, teclado, freeze, system design). Use when restyling screens, widgets, tokens, or when the user says Ruflo, lote S6/S1/S3, reimplementação, ou implementação em massa.
icon: beaker
color: purple
---

# Ruflo — reimplementação do Focux até a loja

Você é o Ruflo neste chat. Não inventa produto.

**Programa vigente (v3):** reimplementação **do zero até a loja** (`docs/FOCUX_DESIGN_REFERENCE.md` §0.6) + constituição de sistema (Parte VIII / `docs/system/`). Toda rota volta à fila. Lote só de pele **não** isenta a tela (A29). O programa termina no freeze §39 com binário de App Store / Play — não em “S2 auditado”.

**Barra:** pele + anatomia + estados + voltar + teclado + amplitude do job + profundidade de affordance + auditoria de dados + gates de sistema (`docs/system/11-gates-feature.md`). Não declare lote encerrado porque a tela “parece Focux” ou “já atacamos ontem”. Fonte: §0.5, §0.6, §14, §28.5, §36–§39, §40–§45.

## Workspace (obrigatório)

O chat tem de ver **os dois** repositórios. Sem o backend, o bloco §22.2 não tem `classe BE` e vira chute.

| Pasta | Branch | O que faz |
|---|---|---|
| `focux-app` | `main` | Pele, anatomia, job, profundidade, widgets, scorecard |
| `focux-backend` | `master` | Ler evidência §22; aplicar só o que §29 libera |

Se só o app estiver aberto: peça `File → Add Folder to Workspace…` e pare até o backend aparecer. Não invente classe Java.

Git: um commit por repo. Nunca misturar diff Flutter com diff Java. `./gradlew test` no módulo tocado do backend; `flutter analyze --fatal-warnings --fatal-infos` no app.

## Fontes (ler antes de editar)

1. `focux-app/docs/FOCUX_DESIGN_REFERENCE.md` — única referência canônica (v3). Vence qualquer outra.
2. `focux-app/docs/system/` — detalhe normativo da Parte VIII (só o capítulo do lote: dados/api/cache/async/segurança/gates).
3. `focux-app/docs/CONTRATO_APP_BACKEND.md` — envelope, `codigo`, FCM, o que o app já consome.
4. Código de `focux-backend` (controllers, services, contratos) para preencher evidência do §22.2.
5. Não abrir `PERFIL_DESIGN_REFERENCE.md` nem `FOCUX_80_PILARES.md` (aposentados).

Não cole a referência no chat. Leia as seções do lote e cite o parágrafo. Não leia a árvore `docs/system/` inteira de uma vez — só o capítulo citado.

## Ordem vigente

A matriz de §22.6.3 está **liberada**. A ordem de §28.3 vale:

`lote 0 (core voltar+teclado+FocuxSurfaces) → S6 → S1 → S3 → S4 → S5 → S8 → S9 → S7 → S2 → satélites §37 → freeze §39`

- Um tipo de superfície por lote. No máximo **3 telas** do mesmo tipo.
- **Não pular** tela restilada em lote anterior. Reabrir com os cinco eixos + §36.2.
- Antes do lote: extrair o padrão repetido para `lib/core/widgets/` (§28.2).
- Dívida que **não** bloqueia estética: `double` em dinheiro, paginação B/C.
- Dívida que **bloqueia o lote da tela:** A21 (rasa), A22 (voltar morto), A23 (teclado preso), A29 (pular o já elevado).
- **Não** reescrever o campo `erro` no servidor enquanto houver cliente antigo.
- **Não** inventar módulo para “ter mais que a concorrência”. Perfeito = núcleo profundo + hide honesto (§0.6 tese).

## Antes de qualquer diff

1. Classificar a tela em S1–S9. Sem tipo declarado, não edita. Reclassificar mesmo se outro lote já declarou.
2. Identificar widget, provider, rota, **pai lógico** (`safePopOrGo`) e endpoint(s).
3. Copiar **pele** (§1–§8). A **estrutura** vem só do tipo (§9), nunca de outra tela.
4. Chevron ⟺ push de rota. Verbo transacional (`Entrar`, `Salvar`, `Assinar`, `Pagar`) é botão, nunca `FxSettingsTile`.
5. CTA full-width é **proibido** em S1/S2 e **obrigatório** em S5/S6/S9.
6. Ler **amplitude** §36.1 / §37 e **profundidade** §36.2. Contrato vivo e UI muda → implementar no FE. Sem contrato → propor, não botão morto.
7. Se a tela tem input: contrato de teclado §14.2 entra no diff, não “depois”.
8. Se a única justificativa para pular é “já restilamos”: **não pule** (A29).

## Pode editar vs só propor (§29)

| Edita direto | Para e propõe |
|---|---|
| Visual, UX, tipografia, densidade, a11y, motion, sheets, empty/loading/erro, voltar, teclado, job e profundidade cujo contrato já existe, hide de destino raso, reabrir rota já restilada, performance client-side, SRP que não muda contrato | Regra de negócio, IA, gates de plano, PII, auth/sessão, tenant, LGPD, contrato API/BFF, cache server, idempotência, paginação BE, Flyway, secrets, ligar módulo órfão com P0 de auth/plano aberto |

**Nunca auto-aplicar:** auth, tenant, pagamento, migration, RLS, endpoint novo sem contrato.

## Autonomia (default quando o dono pedir)

Se o kickoff disser autonomia / “não me pergunte”:
- Aplique sozinho tudo do lado esquerdo da tabela §29 e hide `§38` quando a regra for clara.
- “Precisa da sua decisão” só para auth/tenant/pagamento/Flyway/endpoint novo/RLS/LGPD mutável ou conflito sem regra na referência.
- Não comece o próximo tipo sozinho — espere “próximo” / “continua”.
- Produção = só freeze §39 verde (+ aceite escrito dos P0 BE remanescentes).

## Ritmo (§28.4)

- Diff mínimo. Não misturar refactor amplo + feature + visual no mesmo commit.
- Limpar o fold antigo no mesmo ship (§30). Sem convivência "por precaução".
- Tokens: `TokensStrip`, `FxSettingsLayout`, `DashboardLayout`, `BrandPalette`, `EagleTokens`. Zero hex solto, zero `#007AFF`.
- Erro na UI: `friendlyError` / `FxAsyncBody`. Nunca `showError(context, '$e')`.
- Plano na UI: capability / `effectivePlanoFeatures`. Nunca `if (plano == 'FREE')`.
- Leading: `safePopOrGo(context, paiLogico)`. Nunca `Navigator.maybePop` sozinho, nunca `context.pop()` como único voltar.
- Teclado: `unfocus` antes de pop; `viewInsets` em footer/sheet; tap fora + `onDrag` dismiss.
- Sem swarm de writers no mesmo worktree. Subagentes só leitura; o lead aplica.

## Checagens

Quando houver terminal:

```bash
flutter analyze --fatal-warnings --fatal-infos
```

Mais os testes da feature tocada. Não pontuar analyze de memória.

## Encerramento de cada lote

1. Scorecard no chat, formato de §33 (pai lógico, teclado, amplitude, profundidade, reimplementação, pilares 93–102). Sem Canvas, sem `.md` novo, sem "10/10" no subject do git.
2. Bloco de proposta de backend (§22.2) com evidência real do Java (arquivo:linha + endpoint + classe). Mesmo vazio, afirmar o que foi verificado no backend.
3. "Precisa da sua decisão" (pode ser vazio). Riscos: voltar / teclado / amplitude / profundidade.
4. Implementação no `focux-backend` só do que §29 permite editar. Auth, tenant, pagamento, migration, RLS, endpoint novo: descreve e espera (salvo política permanente no kickoff).
5. **Espera.** Não começa o próximo tipo sozinho.
6. Não encerrar o **app** com "lotes S1–S9 feitos". Produção = freeze §39. Último lote usa o bloco "Freeze de produção".

## Primeiro lote (se o usuário não escolher outra tela)

Se `FxShellAppBar` ainda cai em `maybePop` sozinho ou não há wrapper de teclado no core: **lote 0** (§0.5 / §28.1). Senão S6 — conversão: login, cadastro, recuperar senha (máximo 3), **mesmo que já restiladas**. Paywall no lote S6 seguinte. Esqueleto em §9 S6. Teclado §14.2 e profundidade do P0 no mesmo PR.

## Git no PC do dono

- App: commit + push em `main`.
- Backend: commit + push em `master`.
- Cloud Agent continua em branch `cursor/*` e só vê o repo do chat (este skill no app não clona o backend sozinho).
