# Focux — Auditoria de código morto e plano de refatoração

**Data:** 21/05/2026 · **Escopo:** `focux-app` (271 arquivos `lib/`) + `focux-backend` (limpo)

---

## Resumo executivo

| Categoria | Itens | Ação nesta rodada |
|-----------|-------|-------------------|
| Arquivos órfãos (zero imports) | 2 | **Removidos** |
| Tela legada sem rota útil | 1 (`planos_screen.dart`) | **Removida** |
| Classes/widgets mortos | 2 (`ShimmerCardLoading`, `_EmptyFeed`) | **Removidos** |
| Imports / variáveis não usados | 22 warnings `dart analyze` | **Corrigidos** |
| Módulo QA (debug) | 6 arquivos | **Mantido** (ferramenta dev) |
| `fx_strip_components.dart` | Só QA showcase | **Mantido** (design lab) |

---

## 1. Arquivos removidos (alta confiança)

| Arquivo | Motivo |
|---------|--------|
| `lib/core/theme/cockpit_theme.dart` | `CockpitTheme` nunca importado |
| `lib/core/widgets/fx_strip_sub_screen.dart` | `FxStripSubScreen` nunca importado |
| `lib/features/planos/screens/planos_screen.dart` | Stub: `/planos` já redireciona para `/assinatura`; `/planos-legado` sem links no app |

---

## 2. Código morto por arquivo (analyzer + grep)

### Widgets / classes

| Símbolo | Arquivo | Motivo |
|---------|---------|--------|
| `ShimmerCardLoading` | `loading_shimmer.dart` | Só `ShimmerListLoading` é usado |
| `_EmptyFeed` | `feed_screen.dart` | Declarado, nunca instanciado |
| `_ClaudeInlineNote.onTap` / `actionLabel` | `claude_paywall_layout.dart` | Parâmetros opcionais nunca passados |

### Imports não utilizados (corrigidos)

`cinematic_mesh_background`, `fx_logo`, `analytics_screen`, `resetar_senha_screen`, `cinematic_splash_scene`, `chat_aluno_screen`, `chat_screen`, `checkin_screen`, `engajamento_screen`, `evolucao_fotos_screen`, `ia_aluno_screen`, `onboarding_screen`, `identidade_visual_screen`, `enterprise_promo_screen`, `relatorio_screen`, `exercise_search_highlight`, `assinatura_screen` (`dart:ui`), `fx_glass_surface` (`dart:ui`).

### Variáveis locais não lidas

| Variável | Arquivo |
|----------|---------|
| `isDark` | `conversation_screen.dart` |
| `bg` (×2) | `perfil_screen.dart` |

---

## 3. Mantidos de propósito (não remover)

| Item | Motivo |
|------|--------|
| `features/qa/**` | Smoke + token showcase (`kDebugMode`) |
| `fx_strip_components.dart` | Galeria `/qa/tokens-strip` |
| `planos_repository.dart`, `plano_features_provider.dart` | Assinatura, gates, API `/api/planos/me` |
| `paywall_screen.dart` | Fluxo alternativo de conversão |
| `empty_state.dart` | Usado em `plano_sucesso_screen.dart` |

---

## 4. Backend (`focux-backend`)

- Working tree limpo; `.gitignore` já ignora `.agents/`, `.claude/`, `temp_design/`, secrets.
- Nenhum arquivo órfão crítico identificado nesta passada.

---

## Plano de tarefas e subtarefas

### Fase A — Limpeza imediata ✅ (esta sessão)

- [x] A.1 Deletar `cockpit_theme.dart`, `fx_strip_sub_screen.dart`
- [x] A.2 Remover `planos_screen.dart`, rota `/planos-legado`, ajustar QA + testes
- [x] A.3 Remover `ShimmerCardLoading`, `_EmptyFeed`, params mortos em `_ClaudeInlineNote`
- [x] A.4 Corrigir todos os `unused_import` / `unused_local_variable` do analyzer
- [x] A.5 Rodar `dart analyze` + testes + commit/push

### Fase B — Arquitetura de rotas (próxima sprint)

- [ ] B.1 Unificar `PaywallScreen` vs `AssinaturaScreen` (um funil só)
- [ ] B.2 QA: `qa_route_preview` espelhar redirects reais do `GoRouter`
- [ ] B.3 Imports condicionais de `features/qa` só em `kDebugMode` (build release menor)

### Fase C — Widgets duplicados (médio prazo)

- [ ] C.1 Migrar `EmptyStateWidget` → `FxEmptyState` onde fizer sentido
- [ ] C.2 Auditar `fx_strip_components` vs `fx_motion` / `fx_strip` — usar só design system ativo
- [ ] C.3 Inventário de `google_fonts` — tema central vs imports por tela

### Fase D — Qualidade contínua

- [ ] D.1 CI: `dart analyze --fatal-warnings` em PR
- [ ] D.2 Script `tools/find_orphan_dart.dart` (grep de imports)
- [ ] D.3 Revisão trimestral de `features/*` sem rota nem import

---

## Comandos de verificação

```bash
cd focux-app
dart analyze
flutter test
```

---

*Focux Personal · dead-code audit v1.0*
