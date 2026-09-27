# Aluno — Home "Hoje" (app) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesenhar a Home do aluno em torno de "o que tenho hoje / como estou / estou evoluindo / próximo passo", com um P0, fatos de treino do servidor e textos em pt, en e es.

**Architecture:** Regras em funções puras em `lib/features/dashboard/utils/` (ação do dia, pendências, aviso, resumo da semana) e textos em funções `(S, dado) → texto`, testáveis sem widget. Widgets novos em `lib/features/dashboard/widgets/`; a tela só compõe. `aluno_autonomy_plan.dart` e os widgets do fold antigo são apagados.

**Tech Stack:** Flutter, Riverpod 3, go_router, gen-l10n (`S`), flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-27-aluno-home-redesign-design.md`
**Depende de:** plano backend (campo `concluidosSemanaIso`); o app tolera a ausência.

## Global Constraints

- Um `emphasize: true` na tela (card de foco). Nenhum CTA full-width. Chips ≤ 3 por card.
- Todo texto visível da Home em `app_pt.arb`, `app_en.arb`, `app_es.arb`. Depois de `flutter gen-l10n`, conferir que `S.of` mantém o fallback `?? lookupS(const Locale('pt'))` em `lib/l10n/app_localizations.dart`.
- Eventos de autonomia: mesmos `taskId` e `taskTitle` pt de hoje (`perfil-base`, `foto-dados`, `medida-recente`, `chat-contexto`, `agenda-semana`, `treino-semana`, `financeiro`).
- Nada vira zero fingindo dado: bloco sem dado some.
- Limpeza de mortos no mesmo ship; `flutter analyze --fatal-warnings --fatal-infos --no-pub` limpo.
- Commits curtos em pt, sem trailer de IA; gitleaks no staged.

---

### Task 1: Bundle lê `concluidosSemanaIso` e perde `volumeMesKg`

**Files:**
- Modify: `lib/features/dashboard/data/dashboard_repository.dart` (`AlunoDashboardHomeBundle`)
- Test: `test/features/dashboard/data/aluno_dashboard_home_bundle_test.dart`

**Interfaces:** Produces `final int? concluidosSemanaIso` no bundle (`num` → `toInt()`, outro tipo → `null`).

- [ ] Teste: payload com `concluidosSemanaIso: 2` → `2`; sem a chave → `null`; `"x"` → `null`. Remover as asserções de `volumeMesKg`.
- [ ] Rodar e ver falhar; implementar; rodar `flutter test --no-pub test/features/dashboard/data/aluno_dashboard_home_bundle_test.dart`.

### Task 2: Ação do dia (`aluno_today_action.dart`)

**Files:**
- Create: `lib/features/dashboard/utils/aluno_today_action.dart`
- Test: `test/features/dashboard/utils/aluno_today_action_test.dart`

**Interfaces (Produces):**

```dart
enum AlunoTodayMode { financialHold, workoutReady, awaitingRelease, profileSetup, noWorkout }

class AlunoTodayAction {
  final AlunoTodayMode mode;
  final String route;
  final Object? routeExtra;
  final String? treinoNome;
  final int exerciseCount;
  final bool comeback;
  final DateTime? prazoFim;
}

int alunoProfileCompletion(Aluno aluno); // contato (telefone|whatsapp), objetivo, genero, peso, altura, dataNascimento
AlunoTodayAction resolveAlunoTodayAction({
  required Aluno aluno,
  required List<ExecucaoTreino> treinos,
  List<ExecucaoTreino> historico = const [],
});
```

Ordem: `inadimplente` → `/financeiro/aluno`; `proximoTreinoParaHoje` → `/checkin/executar` (`routeExtra: treinoId`, `comeback = (diasSemTreino ?? 0) >= 7`, `prazoFim = parseIsoDate(dataFim)`); `isTreinoAguardandoLiberacao` → `/checkin/treinos`; completude < 60 → `/aluno/perfil`; senão `/chat/aluno`.

- [ ] Testes: um por modo; inadimplente vence treino pronto; foto ausente com treino pronto → `workoutReady`; `diasSemTreino` 6 → `comeback == false`, 7 → `true`; rodízio (A concluído → B) e `EM_ANDAMENTO` antes de girar (casos portados do teste antigo); telefone + WhatsApp contam uma vez.
- [ ] Ver falhar, implementar, ver passar.

### Task 3: Pendências, aviso e resumo da semana

**Files:**
- Create: `lib/features/dashboard/utils/aluno_pendencias.dart`
- Create: `lib/features/dashboard/utils/aluno_home_week.dart`
- Test: `test/features/dashboard/utils/aluno_pendencias_test.dart`
- Test: `test/features/dashboard/utils/aluno_home_week_test.dart`

**Interfaces (Produces):**

```dart
enum AlunoPendenciaTipo { perfil, foto, medida, chat, agenda }

class AlunoPendencia {
  final AlunoPendenciaTipo tipo;
  final String route;
  String get taskId;       // perfil-base, foto-dados, medida-recente, chat-contexto, agenda-semana
  String get taskTitlePt;  // título pt fixo enviado ao backend
}

List<AlunoPendencia> resolveAlunoPendencias({
  required Aluno aluno,
  required List<MedidaCorporal> medidas,
  required int naoLidasDoPersonal,
  required bool agendaReviewed,
  required AlunoTodayMode todayMode,
  DateTime? now,
}); // ordem perfil, foto, medida (>14 dias ou nenhuma), chat (>0), agenda; exclui perfil se todayMode == profileSetup; take(3)

enum AlunoHomeAviso { anamnese, coach, nenhum }
AlunoHomeAviso resolveAlunoHomeAviso({required bool anamnesePendente, required int coachMensagens});

class AlunoWeekSummary {
  final int? feitos;
  final int? meta;
  final int streakSemanas;
  final double? volumeKg;
  bool get isEmpty;
}
AlunoWeekSummary buildAlunoWeekSummary({
  int? concluidosSemanaIso,
  int? frequenciaDias,
  required int streakAtual,
  required double volumeSemanaKg,
}); // meta via alunoWeeklyDayGoal; volume <= 0 → null; streak < 0 → 0
```

- [ ] Testes de pendências: exclusão do P0, corte em 3, lista vazia, medida 14 vs 15 dias, chat 0 vs 1, agenda revisada some.
- [ ] Testes de aviso: anamnese vence coach; só coach; nenhum.
- [ ] Testes da semana: com meta, sem meta, `concluidosSemanaIso` nulo, volume 0 → null, `isEmpty`.
- [ ] Ver falhar, implementar, ver passar.

### Task 4: Textos (ARB + funções de texto)

**Files:**
- Modify: `lib/l10n/app_pt.arb`, `app_en.arb`, `app_es.arb` (chaves `alunoHome*`, `alunoHoje*`, `alunoSemana*`, `alunoEvolucao*`, `alunoPendencia*`)
- Create: `lib/features/dashboard/utils/aluno_home_texts.dart`
- Test: `test/features/dashboard/utils/aluno_home_texts_test.dart`

**Interfaces (Produces):**

```dart
typedef AlunoTodayTexto = ({String eyebrow, String titulo, String descricao, String cta});
AlunoTodayTexto alunoTodayTexto(S s, AlunoTodayAction a, {DateTime? hoje});
String? alunoPrazoTexto(S s, DateTime? prazoFim, {DateTime? hoje}); // atrasado / hoje / até
({String titulo, String detalhe}) alunoPendenciaTexto(S s, AlunoPendenciaTipo tipo, {bool semMedida = false});
String alunoWeekSemantics(S s, AlunoWeekSummary w, String? volumeLabel);
String alunoPrimeiroNome(String nome);
```

- [ ] Testes com `lookupS(const Locale('pt'))` e `en`: cada modo tem texto; `comeback` usa "Volte com {treino}"; 0 exercícios não diz "0 exercícios"; prazo atrasado/hoje/futuro; frase da semana com e sem meta.
- [ ] `flutter gen-l10n`; restaurar o fallback de `S.of` se o gerador o remover; ver passar.
- [ ] Apagar `TreinoAtribuicaoPrazo.homeHint` e seu caso em `test/features/treinos/treino_atribuicao_prazo_test.dart` (sem outro caller).

### Task 5: Widgets novos

**Files:**
- Create: `lib/features/dashboard/widgets/aluno_home_header.dart` (`AlunoHomeHeader`: saudação + linha do personal → `/chat/aluno`)
- Create: `lib/features/dashboard/widgets/aluno_week_summary_card.dart` (`AlunoWeekSummaryCard`: 3 `OperationalMetricTile`, `Semantics` único)
- Create: `lib/features/dashboard/widgets/aluno_pendencias_block.dart` (`AlunoPendenciasBlock`: header de seção + até 3 linhas)
- Create: `lib/features/dashboard/utils/aluno_autonomy_analytics.dart` (`AlunoAutonomyAnalytics.viewed/clicked/resetSessao`; manda `ProductEvents.alunoAutonomyTask*` e `registrarEventoAutonomia`)
- Modify: `lib/core/auth/session_invalidator.dart` (chamar `AlunoAutonomyAnalytics.resetSessao()`)
- Test: `test/features/dashboard/widgets/aluno_home_blocks_test.dart`

- [ ] Testes de widget: cabeçalho sem nome do personal não mostra a linha; semana sem meta mostra "treinos nesta semana"; semana com `feitos` nulo mostra só sequência/volume; pendências vazias → `SizedBox.shrink`.
- [ ] Ver falhar, implementar, ver passar.

### Task 6: Tela composta + limpeza

**Files:**
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen.dart` (título "Hoje", ordem §1 da spec, `MeusTreinosMemCache.save` fora do `build` via `ref.listen`)
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen_header.part.dart` (card de foco novo; Evolução só gráfico + força + recorde; apagar hero, pills, narrativa, badge)
- Delete: `lib/features/dashboard/screens/aluno_dashboard_screen_cards.part.dart`
- Delete: `lib/features/dashboard/data/aluno_autonomy_plan.dart`, `test/features/dashboard/data/aluno_autonomy_plan_test.dart`
- Delete: `lib/features/dashboard/utils/aluno_home_display.dart` (texto vai para o ARB)
- Modify: `lib/features/dashboard/utils/aluno_performance_evolution.dart` (fica só `parseAlunoHomeSeries` e `alunoTrendPlot`), `test/features/dashboard/aluno_performance_evolution_test.dart`
- Modify: `test/features/dashboard/screens/aluno_dashboard_visual_contract_test.dart` (contrato novo)

- [ ] Contrato visual novo: um `emphasize: true`; `AlunoUpsellCarousel` depois de `_PerformanceEvolutionCard`; `_StudentToolsSection` por último; sem `buildAlunoHomeExperience`, `rhythmLabel`, `_AlunoHeroCard`, `_StudentJourneyCard`, `MeusTreinosMemCache.save(` dentro de `data:`.
- [ ] Grep de cada símbolo apagado → zero callers.
- [ ] `flutter analyze --fatal-warnings --fatal-infos --no-pub` e `flutter test --no-pub -r failures-only` verdes.
- [ ] Commits por task; push no fim.
