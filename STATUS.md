# Focux App — Status de Design (Análise de Fidelidade ao Handoff)

Atualizado em: 26/04/2026
Baseado em: análise completa do arquivo `Focux Personal Design.html` comparado ao app atual

---

## RESULTADO GERAL

🟢 **22 gaps analisados — 20 resolvidos.** App está substancialmente fiel ao handoff de design. Dois itens restam fora de escopo desta rodada.

---

## O QUE FOI FEITO (todas as rodadas)

### Rodada 1 — Críticos (commits 0ba5790, 5f704f8, ba1414c)

1. ✅ **Floating glass dock** — BackdropFilter blur 24px, 5 tabs, StatefulShellRoute.indexedStack
2. ✅ **Logo BlendMode.screen** — ShaderMask + RadialGradient para F-eagle luminoso
3. ✅ **Auth gradient button** — LinearGradient 135° brand→brandInk + boxShadow brand 60%
4. ✅ **Hero card** — label lowercase `Receita · {mes}`, subtítulo mostra previsão real, mini-stat PENDENTE
5. ✅ **Dashboard atalhos** — seção Ferramentas→Atalhos, 6 ações do design (Gerar treino IA, Novo aluno, Agenda, Mensagens, Cobrar PIX, Leads)
6. ✅ **QuickTile** — Spacer() → SizedBox(10), valor logo abaixo do ícone

### Rodada 2 — Altos/Médios (commits ba1414c, 7f51a01)

7. ✅ **Avatares 2 iniciais** — `fxInitials()` em alunos_list, aluno_detail, editar_aluno, alertas, chat, dashboard
8. ✅ **Chip Novos** — `AlunoFiltro.novos` via `senhaProvisoria != null`
9. ✅ **Treino hero full-bleed** — grid texture (CustomPainter 26px branco 6%), ribbon Duração/Exercícios/Volume com cálculo real
10. ✅ **Financeiro ring** — tamanho 96 → 120px
11. ✅ **Chat bolhas** — gradiente brand→brandInk em bolhas do personal, appBar com IA + more_vert

### Rodada 3 — Polimento (commits 2560dc3)

12. ✅ **Space Grotesk padrão** — `fontFamily: GoogleFonts.spaceGrotesk().fontFamily` no ThemeData, cascateia para todos widgets sem fontFamily explícito
13. ✅ **Borders dark mode** — eliminados todos `isDark ? null : Border.all()` em 10 arquivos; dark mode agora usa `darkLine` em todos cards

### Já implementado (não precisou alteração)

14. ✅ **Check-in completa** — timer 56px, barra progresso, cards de séries com grid, card IA ao vivo, rest timer flutuante
15. ✅ **IA Copiloto** — segmented control Treino/Dieta/Progressão, chips de contexto, progress card com checkmarks, result card header gradiente
16. ✅ **Perfil hero** — grid texture + stat strip 4 colunas com blur semitransparente
17. ✅ **Onboarding glow** — tile 120×120px com BoxShadow dinâmico por accent color do slide + BackdropFilter + RadialGradient interno
18. ✅ **Auth gradientes** — RadialGradient `#1836A0 → #0D1B5C → #070F33` (light) / `#1A3A7A → #060C1E → #020818` (dark) — já corretos
19. ✅ **Tokens dark** — `darkBg #0A0F1E`, `darkCard #121A30`, `darkCardHi #1A2442`, `darkLine #1F2B4A`, `darkInk #F3F4F8`, `darkInkMute #8A94AE` — batem exato com spec
20. ✅ **Divisores 0.5px** — `DividerThemeData(thickness: 0.5)` no tema global

---

## ITENS FORA DE ESCOPO (2 restantes)

### FxIcon SVG personalizado
O design usa conjunto próprio de ícones SVG stroke-based monoline. App usa Material Icons. Substituição exigiria criar ou importar todos ícones customizados e trocar em toda a codebase — esforço de sprint separada.

### Sparkline dados reais de aderência
Dashboard mostra 3 alunos com sparkline de aderência semanal. Dados atualmente são estáticos/mock. Requer endpoint de aderência por aluno + binding na FxSparkline.

---

## Estado da validação técnica

- flutter analyze: 🟢 sem issues
- Commits desta análise: 0ba5790, 5f704f8, ba1414c, b611613, 7f51a01, 2560dc3
- Push em origin/main: 🟢
