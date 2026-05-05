# Focux — Master prompt: design polish & consistency (EN)

Full specification and checklist: see **`DESIGN_IMPROVEMENT_MASTER_PROMPT.md`** (Portuguese, canonical).

## Non-negotiables (summary)

- Colors: `ColorScheme` + `EagleTokens`; avoid stray `Color(0xFF…)`.
- Radii: `EagleTokens.radius*`.
- Errors: never show raw `$e` / exceptions to end users — use `friendlyError`.
- Loading: prefer shimmer / shared patterns on key surfaces (e.g. Command Center).

## Implemented in repo (batch)

- `command_center_widget.dart`: shimmer loading, `friendlyError` + retry, dropdown theming, `radiusSm` on tiles.
- `empty_state_widget.dart`: message color → `onSurfaceVariant`.
- `register_screen.dart`: email / lock / phone icons (semantic).
- `paywall_screen.dart`: PT-BR accents on plan copy and footers.
- `esqueci_senha_screen.dart`: PT-BR accents on user-facing strings.
- `perfil_screen.dart`: “Informações” title.
- `conversation_screen.dart`: composer hint “Digite sua mensagem…”; delivery status icon-only + `Tooltip`.
- `exercicio_taxonomy_labels.dart`: “Avançado”.

## Remaining (from master doc)

- Shortcuts dock: distinct icons (Financeiro ≠ close, IA vs Qualidade, Mensagens vs Suporte).
- Student home: fix “0 exercícios” vs CTA logic; pluralization; name capitalization.
- Feed: empty state; copy review.
- Paywall / tabs: visual rhythm (optional P2).

## Short agent prompt (EN)

```
Repo: focux_app (Flutter M3, Riverpod, GoRouter). Goal: App Store–level polish without rewriting the app.

Rules: ColorScheme + EagleTokens; EagleTokens radii; textTheme; friendlyError for users; no raw exceptions in UI.

Continue from DESIGN_IMPROVEMENT_MASTER_PROMPT.md section 4–6. Verify checklist §6. Run flutter analyze on touched files.
```
