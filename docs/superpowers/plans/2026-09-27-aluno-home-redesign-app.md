# Aluno — Home "Hoje" revisão 2 (app + backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar os 27 critérios do contrato (spec §8): Home do aluno com a ação primeiro, pendências por urgência, estado certo na virada do dia e frescor honesto.

**Architecture:** Regras continuam em funções puras em `lib/features/dashboard/utils/`; a tela só compõe e passa um `now` por build. O card de foco sai do `part` para um widget público testável. Backend só marca campos deprecated no OpenAPI.

**Tech Stack:** Flutter, Riverpod 3, go_router 18, gen-l10n (`S`), flutter_test; Spring Boot / Java 21, JUnit.

**Spec:** `docs/superpowers/specs/2026-09-27-aluno-home-redesign-design.md` (revisão 2).

## Global Constraints

- Texto novo só em `lib/l10n/app_pt.arb`. En/es congelados: só remover chave que saiu do pt. Teste afirma texto em PT.
- Depois de `flutter gen-l10n`, reaplicar em `lib/l10n/app_localizations.dart`: `return Localizations.of<S>(context, S) ?? lookupS(const Locale('pt'));`
- `taskId` de autonomia não mudam: `perfil-base`, `foto-dados`, `medida-recente`, `chat-contexto`, `agenda-semana`, `treino-semana`, `financeiro`.
- Um `emphasize: true` na Home (card de foco).
- Limpeza de mortos no mesmo ship; `dart analyze --fatal-warnings --fatal-infos` limpo; `dart run tools/find_orphan_dart.dart` sem órfão.
- Nunca `dart format` em diretório; só nos arquivos tocados.
- PowerShell 5: sem `&&`; usar `; if ($?) { ... }`.
- Commits curtos em PT, sem trailer de IA. Backend com `git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com"`. gitleaks no staged antes do push.

---

### Task 1: Pendências por urgência

**Files:**
- Modify: `lib/features/dashboard/utils/aluno_pendencias.dart`
- Modify: `lib/features/dashboard/utils/aluno_home_texts.dart`
- Modify: `lib/l10n/app_pt.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`
- Test: `test/features/dashboard/utils/aluno_pendencias_test.dart`, `test/features/dashboard/utils/aluno_home_texts_test.dart`

**Interfaces:**
- Produces: `AlunoPendencia(tipo, {primeiraVez, quando, int quantidade = 0})`; `const alunoAgendaPendenciaDesdeDias = 2`; `int alunoDiasAte(DateTime alvo, DateTime agora)`; ARB `alunoPendenciaChatNovas(int n)`.

- [ ] **Step 1: Testes que falham** — em `aluno_pendencias_test.dart`, trocar o teste `ordem de prioridade, sem corte` e o de agenda por:

```dart
    test('urgência: chat, agenda, medida, cadastro', () {
      final list = listAlunoPendenciasAbertas(
        aluno: _aluno(completo: false, fotoUrl: null),
        medidas: const [],
        naoLidasDoPersonal: 2,
        agendaProximoInicio: _horario,
        agendaReviewed: false,
        todayMode: AlunoTodayMode.workoutReady,
        now: _hoje,
      );
      expect(_tipos(list), [
        AlunoPendenciaTipo.chat,
        AlunoPendenciaTipo.agenda,
        AlunoPendenciaTipo.medida,
        AlunoPendenciaTipo.perfil,
      ]);
      expect(list.first.quantidade, 2);
    });

    test('perfil e foto viram 1 item; só a foto falta abre o seletor', () {
      List<AlunoPendenciaTipo> cadastro(Aluno a) => _tipos(
        listAlunoPendenciasAbertas(
          aluno: a,
          medidas: [_medida(_hoje)],
          naoLidasDoPersonal: 0,
          agendaProximoInicio: null,
          agendaReviewed: true,
          todayMode: AlunoTodayMode.workoutReady,
          now: _hoje,
        ),
      );
      expect(cadastro(_aluno(completo: false, fotoUrl: null)), [
        AlunoPendenciaTipo.perfil,
      ]);
      expect(cadastro(_aluno(fotoUrl: null)), [AlunoPendenciaTipo.foto]);
    });

    test('agenda hoje ou amanhã fica no foco; depois vira pendência', () {
      List<AlunoPendencia> agenda(DateTime? inicio) =>
          listAlunoPendenciasAbertas(
            aluno: _aluno(),
            medidas: [_medida(_hoje)],
            naoLidasDoPersonal: 0,
            agendaProximoInicio: inicio,
            agendaReviewed: false,
            todayMode: AlunoTodayMode.workoutReady,
            now: _hoje,
          );
      expect(agenda(null), isEmpty);
      expect(agenda(DateTime(2026, 9, 27, 18)), isEmpty);
      expect(agenda(DateTime(2026, 9, 28, 7, 30)), isEmpty);
      final list = agenda(_horario);
      expect(_tipos(list), [AlunoPendenciaTipo.agenda]);
      expect(list.single.quando, _horario);
    });
```

  No teste `não repete o P0 de perfil`, trocar `_aluno(completo: false)` por `_aluno(completo: false, fotoUrl: null)` e manter a expectativa `[chat, agenda]` (foto também não entra com o foco em perfil). No `mantém os taskId`, acrescentar:

```dart
      expect(AlunoPendenciaTipo.agenda.taskTitlePt, 'Conferir próximo horário');
```

  Em `aluno_home_texts_test.dart`, no group `alunoPendenciaTexto`, acrescentar:

```dart
    test('chat diz quantas mensagens', () {
      String detalhe(int n) => alunoPendenciaTexto(
        _pt,
        AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: n),
      ).detalhe;
      expect(detalhe(1), '1 mensagem nova');
      expect(detalhe(3), '3 mensagens novas');
    });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/features/dashboard/utils/aluno_pendencias_test.dart test/features/dashboard/utils/aluno_home_texts_test.dart`
Expected: FAIL (ordem antiga, `quantidade` não existe).

- [ ] **Step 3: Implementar** — `aluno_pendencias.dart`:

```dart
  agenda('agenda-semana', 'Conferir próximo horário', '/agenda/aluno');
```

```dart
class AlunoPendencia {
  final AlunoPendenciaTipo tipo;

  /// Medida: aluno nunca registrou (texto de primeira medida).
  final bool primeiraVez;

  /// Agenda: início do próximo horário.
  final DateTime? quando;

  /// Chat: mensagens do personal não lidas.
  final int quantidade;

  const AlunoPendencia(
    this.tipo, {
    this.primeiraVez = false,
    this.quando,
    this.quantidade = 0,
  });
}

const alunoPendenciasMax = 3;
const alunoMedidaValidadeDias = 14;

/// Horário de hoje e amanhã fica na linha do card de foco.
const alunoAgendaPendenciaDesdeDias = 2;

/// Dias de calendário entre hoje e [alvo] (negativo = passado), sem horário de verão.
int alunoDiasAte(DateTime alvo, DateTime agora) => DateTime.utc(
  alvo.year,
  alvo.month,
  alvo.day,
).difference(DateTime.utc(agora.year, agora.month, agora.day)).inDays;
```

  Corpo de `listAlunoPendenciasAbertas` (mesma assinatura):

```dart
  final agora = now ?? DateTime.now();
  final hoje = _dateOnly(agora);
  final ultimaMedida = _ultimaMedida(medidas);
  final medidaVencida =
      ultimaMedida == null ||
      hoje.difference(ultimaMedida).inDays > alunoMedidaValidadeDias;
  final inicio = agendaProximoInicio;
  final agendaPendente =
      inicio != null &&
      !agendaReviewed &&
      alunoDiasAte(inicio, agora) >= alunoAgendaPendenciaDesdeDias;
  final cadastroNoFoco = todayMode == AlunoTodayMode.profileSetup;

  return [
    if (naoLidasDoPersonal > 0)
      AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: naoLidasDoPersonal),
    if (agendaPendente) AlunoPendencia(AlunoPendenciaTipo.agenda, quando: inicio),
    if (medidaVencida)
      AlunoPendencia(
        AlunoPendenciaTipo.medida,
        primeiraVez: ultimaMedida == null,
      ),
    if (!cadastroNoFoco && alunoProfileCompletion(aluno) < 100)
      const AlunoPendencia(AlunoPendenciaTipo.perfil)
    else if (!cadastroNoFoco && !_filled(aluno.fotoUrl))
      const AlunoPendencia(AlunoPendenciaTipo.foto),
  ];
```

  Atualizar o doc da função: "Em ordem de urgência. Perfil e foto nunca aparecem juntos. Agenda só depois de amanhã e ainda não vista."

  `app_pt.arb`: apagar `alunoPendenciaChatDetalhe` e criar:

```json
  "alunoPendenciaChatNovas": "{n, plural, =1{1 mensagem nova} other{{n} mensagens novas}}",
  "@alunoPendenciaChatNovas": { "placeholders": { "n": { "type": "int" } } },
```

  Apagar `alunoPendenciaChatDetalhe` de `app_en.arb` e `app_es.arb`.

  `aluno_home_texts.dart`, caso chat:

```dart
      AlunoPendenciaTipo.chat => (
        titulo: s.alunoPendenciaChatTitulo,
        detalhe: s.alunoPendenciaChatNovas(p.quantidade),
      ),
```

  Em `alunoAgendaQuandoTexto`, trocar o cálculo manual de `dias` por `alunoDiasAte(quando, hoje ?? DateTime.now())`.

- [ ] **Step 4: Gerar l10n e rodar**

Run: `flutter gen-l10n` e reaplicar o fallback em `lib/l10n/app_localizations.dart` (Global Constraints). Depois `flutter test test/features/dashboard/utils/aluno_pendencias_test.dart test/features/dashboard/utils/aluno_home_texts_test.dart test/l10n`
Expected: PASS.

- [ ] **Step 5: Commit** — `git commit -m "feat(home-aluno): pendências por urgência"`

---

### Task 2: Aviso com atestado primeiro

**Files:**
- Modify: `lib/features/dashboard/utils/aluno_pendencias.dart`, `lib/features/dashboard/utils/aluno_home_view.dart`, `lib/features/dashboard/screens/aluno_dashboard_screen_header.part.dart`
- Test: `test/features/dashboard/utils/aluno_pendencias_test.dart`, `test/features/dashboard/utils/aluno_home_view_test.dart`

**Interfaces:**
- Produces: `enum AlunoHomeAviso { atestado, financeiro, anamnese, coach, nenhum }`; `resolveAlunoHomeAviso({required bool inadimplente, required AlunoAnamnesePendente? anamnese, required int coachMensagens})`.

- [ ] **Step 1: Teste que falha** — substituir o group `resolveAlunoHomeAviso` por:

```dart
  group('resolveAlunoHomeAviso', () {
    AlunoHomeAviso aviso({
      bool inadimplente = false,
      AlunoAnamnesePendente? anamnese,
      int coach = 0,
    }) => resolveAlunoHomeAviso(
      inadimplente: inadimplente,
      anamnese: anamnese,
      coachMensagens: coach,
    );

    test('saúde antes de dinheiro: atestado vence a mensalidade', () {
      expect(
        aviso(
          inadimplente: true,
          anamnese: AlunoAnamnesePendente.precisaAtestado,
          coach: 2,
        ),
        AlunoHomeAviso.atestado,
      );
    });

    test('mensalidade vence anamnese solicitada e coach', () {
      expect(
        aviso(
          inadimplente: true,
          anamnese: AlunoAnamnesePendente.solicitada,
          coach: 2,
        ),
        AlunoHomeAviso.financeiro,
      );
    });

    test('anamnese solicitada vence o coach', () {
      expect(
        aviso(anamnese: AlunoAnamnesePendente.solicitada, coach: 2),
        AlunoHomeAviso.anamnese,
      );
    });

    test('só coach', () => expect(aviso(coach: 1), AlunoHomeAviso.coach));
    test('nenhum', () => expect(aviso(), AlunoHomeAviso.nenhum));
  });
```

  Import no teste: `import 'package:focux_app/features/dashboard/data/aluno_home_anamnese.dart';`

  Em `aluno_home_view_test.dart`, group `atalhos`, acrescentar:

```dart
    test('atestado no aviso tira a anamnese dos atalhos', () {
      final view = buildAlunoHomeView(
        _bundle(anamnese: 'PRECISA_ATESTADO', inadimplente: true),
        agendaReviewed: true,
      );
      expect(view.aviso, AlunoHomeAviso.atestado);
      expect(view.rotasNoTopo, contains('/aluno/anamnese'));
      expect(view.atalhos, isNot(contains('/aluno/anamnese')));
    });
```

- [ ] **Step 2: Rodar e ver falhar** — `flutter test test/features/dashboard/utils/aluno_pendencias_test.dart test/features/dashboard/utils/aluno_home_view_test.dart` → FAIL (parâmetro `anamnese` não existe).

- [ ] **Step 3: Implementar** — `aluno_pendencias.dart` (import `../data/aluno_home_anamnese.dart`):

```dart
/// Um aviso por vez abaixo do card de foco. Saúde antes de dinheiro.
enum AlunoHomeAviso { atestado, financeiro, anamnese, coach, nenhum }

AlunoHomeAviso resolveAlunoHomeAviso({
  required bool inadimplente,
  required AlunoAnamnesePendente? anamnese,
  required int coachMensagens,
}) {
  if (anamnese == AlunoAnamnesePendente.precisaAtestado) {
    return AlunoHomeAviso.atestado;
  }
  if (inadimplente) return AlunoHomeAviso.financeiro;
  if (anamnese == AlunoAnamnesePendente.solicitada) {
    return AlunoHomeAviso.anamnese;
  }
  if (coachMensagens > 0) return AlunoHomeAviso.coach;
  return AlunoHomeAviso.nenhum;
}
```

  `aluno_home_view.dart`: na chamada, `anamnese: home.anamnesePendente,`. Em `rotasNoTopo`:

```dart
    if (aviso == AlunoHomeAviso.atestado || aviso == AlunoHomeAviso.anamnese)
      '/aluno/anamnese',
```

  `aluno_dashboard_screen_header.part.dart`, no `switch (aviso)`:

```dart
      AlunoHomeAviso.atestado ||
      AlunoHomeAviso.anamnese when pendente != null => _anamnese(
        context,
        pendente,
      ),
```

  Atualizar o doc da classe: "atestado, mensalidade atrasada, anamnese, coach".

- [ ] **Step 4: Rodar** — mesmo comando → PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(home-aluno): atestado vem antes da mensalidade"`

---

### Task 3: Card de foco público, com prazo, horário e prontidão

**Files:**
- Create: `lib/features/dashboard/widgets/aluno_today_focus_card.dart`
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen_header.part.dart` (remove `_TodayFocusCard`), `lib/features/dashboard/screens/aluno_dashboard_screen.dart`
- Modify: `lib/features/dashboard/utils/aluno_home_texts.dart`, `lib/features/dashboard/utils/aluno_home_view.dart`, `lib/l10n/app_pt.arb`
- Test: `test/features/dashboard/utils/aluno_home_texts_test.dart`, `test/features/dashboard/utils/aluno_home_view_test.dart`, `test/features/dashboard/widgets/aluno_home_blocks_test.dart`, `test/features/dashboard/screens/aluno_dashboard_visual_contract_test.dart`

**Interfaces:**
- Consumes: `alunoDiasAte`, `alunoAgendaPendenciaDesdeDias` (Task 1).
- Produces: `typedef AlunoTodayTexto = ({String eyebrow, String titulo, String descricao, String? prazo, String cta});` `String alunoHorarioFocoTexto(S s, DateTime quando, {required DateTime hoje})`; `DateTime? alunoHorarioNoFoco(DateTime? inicio, DateTime now)`; `AlunoHomeView.horarioNoFoco`; widget `AlunoTodayFocusCard({required AlunoTodayAction action, required DateTime hoje, required bool isDark, required VoidCallback onAction, AlunoHomeInsight? insight, DateTime? horario, bool prontidaoBaixa = false})`.

- [ ] **Step 1: Testes que falham** — `aluno_home_texts_test.dart`: trocar `prazo entra na descrição do treino` e `prontidão baixa…` por:

```dart
    test('prazo tem linha própria', () {
      final t = alunoTodayTexto(_pt, _treino(prazoFim: _hoje), hoje: _hoje);
      expect(t.descricao, '6 exercícios no treino de hoje');
      expect(t.prazo, 'Vence hoje');
    });

    test('prontidão baixa pede treino leve e mantém o CTA', () {
      final t = alunoTodayTexto(_pt, _treino(), hoje: _hoje, prontidaoBaixa: true);
      expect(t.descricao, 'Prontidão baixa: prefira um treino leve ou mobilidade.');
      expect(t.cta, 'Treinar agora');
    });

    test('horário no foco: hoje ou amanhã', () {
      final manha = DateTime(2026, 9, 27, 8);
      expect(
        alunoHorarioFocoTexto(_pt, DateTime(2026, 9, 27, 18), hoje: manha),
        'Horário com seu personal: hoje às 18:00',
      );
      expect(
        alunoHorarioFocoTexto(_pt, DateTime(2026, 9, 28, 7, 30), hoje: manha),
        'Horário com seu personal: amanhã às 07:30',
      );
    });
```

  `aluno_home_view_test.dart`, group `buildAlunoHomeView`:

```dart
    test('horário no foco só hoje ou amanhã', () {
      final agora = DateTime(2026, 9, 27, 8);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 27, 18), agora), isNotNull);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 28, 7), agora), isNotNull);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 29, 7), agora), isNull);
      expect(alunoHorarioNoFoco(null, agora), isNull);
      expect(
        buildAlunoHomeView(
          _bundle(agendaInicio: '2026-09-27T18:00:00'),
          agendaReviewed: true,
          now: agora,
        ).horarioNoFoco,
        DateTime(2026, 9, 27, 18),
      );
    });
```

  `aluno_home_blocks_test.dart`, novo group (usar o `_pump` existente do arquivo; import do widget novo):

```dart
  group('AlunoTodayFocusCard', () {
    const acao = AlunoTodayAction(
      mode: AlunoTodayMode.workoutReady,
      route: '/checkin/executar',
      treinoNome: 'Treino A',
      exerciseCount: 6,
    );

    testWidgets('prazo e horário aparecem com fonte 2x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        AlunoTodayFocusCard(
          action: AlunoTodayAction(
            mode: acao.mode,
            route: acao.route,
            treinoNome: acao.treinoNome,
            exerciseCount: 6,
            prazoFim: DateTime(2026, 9, 27),
          ),
          hoje: DateTime(2026, 9, 27, 8),
          horario: DateTime(2026, 9, 27, 18),
          prontidaoBaixa: true,
          isDark: false,
          onAction: () {},
        ),
      );
      expect(find.text('Vence hoje'), findsOneWidget);
      expect(
        find.text('Horário com seu personal: hoje às 18:00'),
        findsOneWidget,
      );
      expect(
        find.text('Prontidão baixa: prefira um treino leve ou mobilidade.'),
        findsOneWidget,
      );
    });
  });
```

  `aluno_dashboard_visual_contract_test.dart`: trocar `'_TodayFocusCard('` por `'AlunoTodayFocusCard('` nas duas linhas e trocar o teste de `emphasize` por:

```dart
    final foco = File(
      'lib/features/dashboard/widgets/aluno_today_focus_card.dart',
    ).readAsStringSync();
    expect('emphasize: true'.allMatches(screen), isEmpty);
    expect('emphasize: true'.allMatches(foco), hasLength(1));
```

- [ ] **Step 2: Rodar e ver falhar** — `flutter test test/features/dashboard` → FAIL.

- [ ] **Step 3: Implementar**

  `app_pt.arb`: `alunoHojeProntidaoBaixa` vira `"Prontidão baixa: prefira um treino leve ou mobilidade."` e criar:

```json
  "alunoHojeHorarioHoje": "Horário com seu personal: hoje às {hora}",
  "@alunoHojeHorarioHoje": { "placeholders": { "hora": { "type": "DateTime", "format": "Hm" } } },
  "alunoHojeHorarioAmanha": "Horário com seu personal: amanhã às {hora}",
  "@alunoHojeHorarioAmanha": { "placeholders": { "hora": { "type": "DateTime", "format": "Hm" } } },
```

  `aluno_home_texts.dart`: typedef com `String? prazo`; todos os modos passam `prazo: null`, e `_treinoTexto` devolve `descricao: base, prazo: alunoPrazoTexto(s, a.prazoFim, hoje: hoje)`. Novo:

```dart
/// Linha do card de foco para horário de hoje ou amanhã ([alunoHorarioNoFoco]).
String alunoHorarioFocoTexto(S s, DateTime quando, {required DateTime hoje}) =>
    alunoDiasAte(quando, hoje) == 0
        ? s.alunoHojeHorarioHoje(quando)
        : s.alunoHojeHorarioAmanha(quando);
```

  `aluno_home_view.dart`: campo `final DateTime? horarioNoFoco;` (construtor `this.horarioNoFoco`), preenchido em `buildAlunoHomeView` com `alunoHorarioNoFoco(home.agendaProximoInicio, now ?? DateTime.now())`, e:

```dart
/// Hoje ou amanhã: vai para o card de foco em vez de virar pendência.
DateTime? alunoHorarioNoFoco(DateTime? inicio, DateTime now) {
  if (inicio == null) return null;
  final dias = alunoDiasAte(inicio, now);
  return dias >= 0 && dias < alunoAgendaPendenciaDesdeDias ? inicio : null;
}
```

  `aluno_today_focus_card.dart`: mover o corpo de `_TodayFocusCard` do `part` para `class AlunoTodayFocusCard extends StatelessWidget` (mesmos imports de tema: `focux_hub_typography`, `shell_chrome`, `tokens_strip`, `fx_action_chip`, `fx_strip_card`, `aluno_home_insight_line`), com os campos da interface. Depois da descrição:

```dart
          if (texto.prazo case final prazo?) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              prazo,
              style: FocuxHubTypography.bodyMuted(color: mute),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (horario case final h?) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              alunoHorarioFocoTexto(s, h, hoje: hoje),
              style: FocuxHubTypography.bodyMuted(
                color: chrome.ink,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
```

  `alunoTodayTexto(s, action, hoje: hoje, prontidaoBaixa: prontidaoBaixa)`. Apagar `_TodayFocusCard` do `part`. Na tela, import do widget e o bloco passa `hoje: now` e `horario: view.horarioNoFoco` (o `now` chega na Task 4; até lá use `DateTime.now()` local no `_buildHome`).

- [ ] **Step 4: gen-l10n + fallback; rodar** `flutter test test/features/dashboard` → PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(home-aluno): horário e prazo no card de foco"`

---

### Task 4: Um relógio por build e virada do dia

**Files:**
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen.dart`, `lib/features/dashboard/widgets/aluno_pendencias_block.dart`
- Test: `test/features/dashboard/utils/aluno_home_view_test.dart`, `test/features/dashboard/widgets/aluno_home_blocks_test.dart`, `test/features/dashboard/aluno_dashboard_screen_polish_test.dart`

**Interfaces:**
- Produces: `AlunoPendenciasBlock({required pendencias, required DateTime hoje, required onTap, onShown})`; memo `(bundle, vista, dia, view)`.

- [ ] **Step 1: Testes que falham** — `aluno_home_view_test.dart`:

```dart
    test('mesmo bundle no dia seguinte: feito hoje vira treino pronto', () {
      final home = _bundle(fichas: 2, concluidoEm: '2026-09-27T07:30:00');
      expect(
        buildAlunoHomeView(home, agendaReviewed: true, now: DateTime(2026, 9, 27, 20))
            .action
            .mode,
        AlunoTodayMode.workoutDone,
      );
      expect(
        buildAlunoHomeView(home, agendaReviewed: true, now: DateTime(2026, 9, 28, 7))
            .action
            .mode,
        AlunoTodayMode.workoutReady,
      );
    });
```

  `aluno_home_blocks_test.dart`: no `AlunoPendenciasBlock(...)` dos dois testes, acrescentar `hoje: DateTime(2026, 9, 27),`.

  `aluno_dashboard_screen_polish_test.dart`:

```dart
    expect(screen, contains('memo.\$3 == dia'));
    expect(screen, contains('_viewFor(home, now)'));
```

- [ ] **Step 2: Rodar e ver falhar** — `flutter test test/features/dashboard` → FAIL (`hoje` obrigatório, contrato).

- [ ] **Step 3: Implementar** — na tela:

```dart
  (
    AlunoDashboardHomeBundle,
    ({String? inicio})?,
    DateTime,
    AlunoHomeView,
  )? _viewMemo;

  AlunoHomeView _viewFor(AlunoDashboardHomeBundle home, DateTime now) {
    final memo = _viewMemo;
    final vista = _agendaVista;
    final dia = DateUtils.dateOnly(now);
    if (memo != null &&
        identical(memo.$1, home) &&
        memo.$2 == vista &&
        memo.$3 == dia) {
      return memo.$4;
    }
    final view = buildAlunoHomeView(
      home,
      now: now,
      agendaReviewed:
          vista == null ||
          alunoAgendaVista(vista.inicio, home.agendaProximoInicio),
    );
    _viewMemo = (home, vista, dia, view);
    return view;
  }
```

  `_onHomeLoaded` e `_syncAnalytics` chamam `_viewFor(home, DateTime.now())`. `_buildHome` recebe `DateTime now` do `build` (`final now = DateTime.now();` uma vez no `build`) e usa `_viewFor(home, now)`; passa `hoje: now` para `AlunoTodayFocusCard` e `AlunoPendenciasBlock`.

  `aluno_pendencias_block.dart`: campo `final DateTime hoje;` repassado a `_PendenciaRow`, que chama `alunoPendenciaTexto(S.of(context), pendencia, hoje: hoje)`.

- [ ] **Step 4: Rodar** → PASS.
- [ ] **Step 5: Commit** — `git commit -m "fix(home-aluno): Home recalcula quando o dia vira"`

---

### Task 5: Evolução só com força

**Files:**
- Modify: `lib/features/dashboard/widgets/aluno_evolution_card.dart`, `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/dashboard/screens/aluno_dashboard_screen.dart`, `lib/l10n/app_pt.arb`, `app_en.arb`, `app_es.arb`
- Test: `test/features/dashboard/widgets/aluno_home_blocks_test.dart`

**Interfaces:**
- Produces: `AlunoEvolutionCard({required List<double> forcaPorSemana, double? forcaDeltaPercent, RecordePessoal? ultimoRecorde, bool recordeRecente = false})`. Bundle perde `volumePorSemana` (o payload segue mandando).

- [ ] **Step 1: Teste que falha**

```dart
  group('AlunoEvolutionCard', () {
    testWidgets('só força: sem volume no gráfico', (tester) async {
      await _pump(
        tester,
        const AlunoEvolutionCard(
          forcaPorSemana: [0, 80, 82, 0, 85, 86, 88, 90],
          forcaDeltaPercent: 2.3,
        ),
      );
      expect(find.text('Força (1RM est.)'), findsOneWidget);
      expect(find.text('Volume'), findsNothing);
    });
  });
```

- [ ] **Step 2: Rodar e ver falhar** → FAIL (`volumePorSemana` obrigatório).

- [ ] **Step 3: Implementar**
  - Card: remover `volumePorSemana`; `hasChart = alunoTrendPlot(forcaPorSemana) != null`; `_DualTrendChart`/`_DualTrendPainter` viram `_TrendChart`/`_TrendPainter` com uma série (`data`, `color`, `strokeWidth: 2.4`); legenda só com `_LegendDot(color: forcaColor, label: s.alunoEvolucaoLegendaForca)`; semantics `s.alunoEvolucaoGraficoSemantics(forcaPorSemana.length)`.
  - `app_pt.arb`: `alunoEvolucaoGraficoSemantics` → `"Gráfico das últimas {semanas} semanas: força (1RM estimado)"`; apagar `alunoEvolucaoLegendaVolume` em pt, en e es.
  - Bundle: apagar campo, parâmetro e parse de `volumePorSemana`.
  - Tela: apagar `volumePorSemana: home.volumePorSemana,`.
  - Grep `volumePorSemana` em `lib/features/dashboard` → zero.

- [ ] **Step 4: gen-l10n + fallback; rodar** `flutter test test/features/dashboard test/features/checkin/checkin_evolution_contract_test.dart test/l10n` → PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(home-aluno): evolução só com força"`

---

### Task 6: Frescor honesto (304 e subtítulo)

**Files:**
- Modify: `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/dashboard/utils/aluno_dashboard_home_client_cache.dart`, `lib/features/dashboard/providers/dashboard_provider.dart`, `lib/features/dashboard/screens/aluno_dashboard_screen.dart`
- Test: `test/features/dashboard/dashboard_home_client_cache_test.dart`, `test/features/dashboard/aluno_dashboard_screen_polish_test.dart`

**Interfaces:**
- Produces: `AlunoDashboardHomeBundle withFetchedAt(DateTime at)`; `static AlunoDashboardHomeBundle? AlunoDashboardHomeClientCache.revalidar({DateTime? now})`.

- [ ] **Step 1: Testes que falham** — em `dashboard_home_client_cache_test.dart`, novo group:

```dart
  group('AlunoDashboardHomeClientCache.revalidar', () {
    tearDown(AlunoDashboardHomeClientCache.clear);

    test('304 renova a idade e devolve cópia nova', () {
      final t0 = DateTime(2026, 9, 27, 8);
      final bundle = AlunoDashboardHomeBundle.fromJson({
        'aluno': {'id': 7, 'nome': 'Ana', 'email': 'a@focux.test', 'status': 'ATIVO'},
      });
      AlunoDashboardHomeClientCache.put(bundle, now: t0);
      final t1 = t0.add(const Duration(minutes: 2));
      final novo = AlunoDashboardHomeClientCache.revalidar(now: t1)!;
      expect(identical(novo, bundle), isFalse);
      expect(novo.fetchedAt, t1);
      expect(novo.aluno.nome, 'Ana');
      expect(AlunoDashboardHomeClientCache.fetchedAt, t1);
    });

    test('sem bundle → null', () {
      expect(AlunoDashboardHomeClientCache.revalidar(), isNull);
    });
  });
```

  `aluno_dashboard_screen_polish_test.dart`:

```dart
    expect(provider, contains('AlunoDashboardHomeClientCache.revalidar('));
    expect(
      RegExp(r'subtitle: homeAsync\.when\(\s*skipLoadingOnReload: true,\s*skipError: true')
          .hasMatch(screen),
      isTrue,
    );
```

  (com `final provider = File('lib/features/dashboard/providers/dashboard_provider.dart').readAsStringSync();` e `import 'dart:io';`).

- [ ] **Step 2: Rodar e ver falhar** → FAIL.

- [ ] **Step 3: Implementar** — bundle:

```dart
  /// Mesmo conteúdo com outra idade (resposta 304 do servidor).
  AlunoDashboardHomeBundle withFetchedAt(DateTime at) => AlunoDashboardHomeBundle(
    aluno: aluno,
    personalBrand: personalBrand,
    treinos: treinos,
    historico: historico,
    medidas: medidas,
    chat: chat,
    notificacoesNaoLidas: notificacoesNaoLidas,
    coachMensagens: coachMensagens,
    upsellPendentes: upsellPendentes,
    npsDeveResponder: npsDeveResponder,
    recovery: recovery,
    hasWearableHistory: hasWearableHistory,
    streakAtual: streakAtual,
    volumeSemanaKg: volumeSemanaKg,
    concluidosSemanaIso: concluidosSemanaIso,
    forcaPorSemana: forcaPorSemana,
    recordes: recordes,
    frequenciaDias: frequenciaDias,
    forcaDeltaPercent: forcaDeltaPercent,
    recoveryStale: recoveryStale,
    insight: insight,
    anamnesePendente: anamnesePendente,
    recursosIndisponiveis: recursosIndisponiveis,
    agendaProximoInicio: agendaProximoInicio,
    fetchedAt: at,
  );
```

  Cache:

```dart
  /// 304: o servidor confirmou o bundle atual. Renova a idade e devolve uma
  /// cópia nova, para a tela saber que atualizou.
  static AlunoDashboardHomeBundle? revalidar({DateTime? now}) {
    final bundle = getEvenIfStale(now: now);
    if (bundle == null) return null;
    final at = now ?? DateTime.now();
    final renovado = bundle.withFetchedAt(at);
    put(renovado, now: at);
    return renovado;
  }
```

  Provider `alunoDashboardHomeProvider`:
  - SWR: `if (fresh != null) { put(fresh); } else { AlunoDashboardHomeClientCache.revalidar(); } ref.invalidateSelf();`
  - Caminho sem cache: `final stale = AlunoDashboardHomeClientCache.revalidar(); if (stale != null) return stale;` no lugar do bloco `getEvenIfStale` + `put`.
  - `refreshAlunoDashboardHome`: `if (fresh != null) { AlunoDashboardHomeClientCache.put(fresh); } else { AlunoDashboardHomeClientCache.revalidar(); }`

  Tela, subtítulo:

```dart
          subtitle: homeAsync.when(
            skipLoadingOnReload: true,
            skipError: true,
            data: (home) => FxHubFreshness.fromFetchedAt(home.fetchedAt),
            loading: () => null,
            error: (_, __) => null,
          ),
```

- [ ] **Step 4: Rodar** `flutter test test/features/dashboard` → PASS.
- [ ] **Step 5: Commit** — `git commit -m "fix(home-aluno): atualizado de verdade após 304"`

---

### Task 7: Volta do background recarrega a Home do aluno

**Files:**
- Modify: `lib/main.dart` (`_warmSessionThenSoftReload`)
- Test: `test/features/dashboard/aluno_dashboard_screen_polish_test.dart`

- [ ] **Step 1: Teste que falha**

```dart
  test('volta do background recarrega a Home do aluno', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('ref.invalidate(alunoDashboardHomeProvider);'));
  });
```

- [ ] **Step 2: Rodar e ver falhar** → FAIL.
- [ ] **Step 3: Implementar** — no fim de `_warmSessionThenSoftReload`, depois de `ref.invalidate(dashboardHomeProvider);`, invalidar `alunoDashboardHomeProvider` sem limpar o cache: a pausa mínima (2 min) já passa do TTL, então o SWR pinta o bundle anterior e revalida com ETag (304 barato). Limpar jogaria fora o ETag e forçaria o corpo inteiro.

```dart
    ref.invalidate(dashboardHomeProvider);
    // SWR do aluno: pinta o bundle anterior e revalida com ETag.
    ref.invalidate(alunoDashboardHomeProvider);
    ref.invalidate(perfilProvider);
```

- [ ] **Step 4: Rodar** → PASS.
- [ ] **Step 5: Commit** — `git commit -m "fix(home-aluno): recarrega ao voltar do background"`

---

### Task 8: Tela na ordem nova, prontidão sem dica repetida, atalhos e custo

**Files:**
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen.dart`, `lib/features/dashboard/screens/aluno_dashboard_screen_tools.part.dart`, `lib/features/health/widgets/aluno_recovery_card.dart`, `lib/l10n/app_pt.arb`
- Test: `test/features/dashboard/screens/aluno_dashboard_visual_contract_test.dart`, `test/features/dashboard/aluno_dashboard_screen_polish_test.dart`, `test/features/dashboard/widgets/aluno_home_blocks_test.dart`

**Interfaces:**
- Produces: `AlunoRecoveryCard({required RecoverySnapshot? snapshot, bool mostrarDica = true})`; ARB `alunoProntidaoSemanticsRotulo(String nivel)`.

- [ ] **Step 1: Testes que falham** — visual contract, trocar a sequência de `at(...)` por:

```dart
    expect(at('AlunoHomeHeader('), lessThan(at('AlunoTodayFocusCard(')));
    expect(at('AlunoTodayFocusCard('), lessThan(at('_AlunoHomeAviso(')));
    expect(at('_AlunoHomeAviso('), lessThan(at('AlunoPendenciasBlock(')));
    expect(at('AlunoPendenciasBlock('), lessThan(at('AlunoWeekSummaryCard(')));
    expect(at('AlunoWeekSummaryCard('), lessThan(at('AlunoRecoveryCard(')));
    expect(at('AlunoRecoveryCard('), lessThan(at('AlunoEvolutionCard(')));
    expect(at('AlunoEvolutionCard('), lessThan(at('AlunoUpsellCarousel(')));
    expect(at('AlunoUpsellCarousel('), lessThan(at('_StudentToolsSection(')));
    expect(screen, contains('mostrarDica: !view.prontidaoBaixa'));
    expect(screen, contains('if (featured.isNotEmpty)'));
```

  Polish: `expect(screen, contains('if (atual != null && atual.inicio == inicio) return;'));`

  Blocks:

```dart
  group('AlunoRecoveryCard', () {
    const baixa = RecoverySnapshot(
      steps: 0,
      caloriesBurned: 0,
      avgHeartRate: 0,
      sleepHours: 0,
      recoveryScore: 40,
      recoveryLabel: 'Descanso recomendado',
      recoveryHint: 'Sono ou carga baixa',
    );

    testWidgets('sem a dica quando o foco já falou', (tester) async {
      await _pump(tester, const AlunoRecoveryCard(snapshot: baixa, mostrarDica: false));
      expect(find.text('Descanso recomendado'), findsOneWidget);
      expect(find.text('Sono ou carga baixa'), findsNothing);
    });

    testWidgets('movimento reduzido: coração parado', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: const Scaffold(body: AlunoRecoveryCard(snapshot: baixa)),
          ),
        ),
      );
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
```

  (Se `_pump` já monta `MaterialApp`, usar `MediaQuery` por dentro do `home` para o segundo teste; imports de `aluno_recovery_card.dart` e `health_repository.dart`.)

- [ ] **Step 2: Rodar e ver falhar** → FAIL.

- [ ] **Step 3: Implementar**
  - Tela: reordenar `blocos` para header, foco, aviso, pendências (`TokensStrip.s4`), semana (`s4`), prontidão (`view.semanaVisivel ? s3 : s4`), evolução, ofertas, atalhos. Prontidão: `AlunoRecoveryCard(snapshot: home.recovery, mostrarDica: !view.prontidaoBaixa)`.
  - `_loadAgendaVista`:

```dart
  Future<void> _loadAgendaVista() async {
    final inicio = await readAlunoAgendaVista();
    if (!mounted) return;
    final atual = _agendaVista;
    if (atual != null && atual.inicio == inicio) return;
    setState(() => _agendaVista = (inicio: inicio));
    final home = ref.read(alunoDashboardHomeProvider).value;
    if (home != null) _syncAnalytics(home);
  }
```

  - Tools part: envolver o espaçamento e o grupo em `if (featured.isNotEmpty) ...[ const SizedBox(height: FxSettingsLayout.headerToGroup), FxSettingsGroup(...) ]`.
  - Recovery card: campo `mostrarDica`; esconder o `Text(snap.recoveryHint…)` e o `SizedBox` antes dele quando `false`; semantics `mostrarDica ? s.alunoProntidaoSemantics(snap.recoveryLabel, snap.recoveryHint) : s.alunoProntidaoSemanticsRotulo(snap.recoveryLabel)`.
  - `app_pt.arb`:

```json
  "alunoProntidaoSemanticsRotulo": "Prontidão do dia: {nivel}",
  "@alunoProntidaoSemanticsRotulo": { "placeholders": { "nivel": { "type": "String" } } },
```

- [ ] **Step 4: gen-l10n + fallback; rodar** `flutter test test/features/dashboard test/features/health` → PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(home-aluno): ação primeiro na ordem da Home"`

---

### Task 9: Repositório de oferta via provider

**Files:**
- Modify: `lib/features/monetizacao/data/upsell_repository.dart`, `lib/features/monetizacao/screens/ofertas_upsell_screen.dart`, `lib/features/monetizacao/widgets/aluno_upsell_carousel.dart`
- Test: `test/features/dashboard/screens/aluno_dashboard_visual_contract_test.dart`

- [ ] **Step 1: Teste que falha** — no teste de oferta: `expect(carousel, contains('ref.read(upsellRepositoryProvider)'));` e `expect(carousel, isNot(contains('UpsellRepository(')));`
- [ ] **Step 2: Rodar e ver falhar** → FAIL.
- [ ] **Step 3: Implementar** — mover `upsellRepositoryProvider` de `ofertas_upsell_screen.dart` para o fim de `upsell_repository.dart` (imports `flutter_riverpod` e `../../auth/providers/auth_provider.dart`); na tela do personal, apagar a definição (o import de `../data/upsell_repository.dart` já existe); no carrossel, `await ref.read(upsellRepositoryProvider).responder(...)` e remover o import de `auth_provider.dart` se ficar sem uso.
- [ ] **Step 4: Rodar** `flutter test test/features/dashboard test/features/monetizacao` → PASS.
- [ ] **Step 5: Commit** — `git commit -m "refactor(upsell): repositório via provider"`

---

### Task 10: Backend — campos obsoletos no OpenAPI

**Files (focux-backend):**
- Modify: `src/main/java/com/focux/modules/dashboard/dto/AlunoDashboardHomeResponse.java`
- Test: `src/test/java/com/focux/modules/dashboard/AlunoDashboardHomeResponseTest.java`

- [ ] **Step 1: Teste que falha**

```java
    @Test
    void camposQueOAppAtualNaoLeSaoDeprecated() throws Exception {
        for (var campo : List.of("agendaProxima", "volumeMesKg")) {
            var schema = AlunoDashboardHomeResponse.class.getMethod(campo)
                .getAnnotation(io.swagger.v3.oas.annotations.media.Schema.class);
            assertThat(schema.deprecated()).as(campo).isTrue();
        }
    }
```

- [ ] **Step 2: Rodar e ver falhar** — `.\gradlew.bat test --tests "*AlunoDashboardHomeResponseTest" --console=plain` → FAIL.
- [ ] **Step 3: Implementar** — nos dois componentes, `@Schema(deprecated = true, description = "Obsoleto: … (app atual usa agendaProximoInicio / não usa). Sai quando a versão mínima do app subir.")`, mantendo o texto atual depois de "Obsoleto:".
- [ ] **Step 4: Rodar** — `.\gradlew.bat test --console=plain` → BUILD SUCCESSFUL.
- [ ] **Step 5: Commit + push** — `git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "docs(home-aluno): marca campos obsoletos no OpenAPI"`; gitleaks; `git push`.

---

### Task 11: Verificação do contrato e ship do app

**Files:**
- Modify: `docs/superpowers/specs/2026-09-27-aluno-home-redesign-design.md` (§7: `foto` continua no enum, mas nunca junto com `perfil`), `pubspec.yaml` (`1.2.1+120` → `1.2.1+121`)

- [ ] **Step 1:** Ajustar §7 da spec: "Limpeza: série de volume do `AlunoEvolutionCard`, `volumePorSemana` do bundle e `_TodayFocusCard`. `AlunoPendenciaTipo.foto` fica no enum (rota e `taskId` próprios), mas só aparece quando o perfil está completo."
- [ ] **Step 2:** `dart analyze --fatal-warnings --fatal-infos` → No issues.
- [ ] **Step 3:** `dart run tools/find_orphan_dart.dart` → Nenhum órfão.
- [ ] **Step 4:** `flutter test --concurrency=2` → All tests passed.
- [ ] **Step 5:** Conferir C1–C27 da spec §8 um a um contra os testes acima; qualquer critério sem prova vira passo novo antes do commit.
- [ ] **Step 6:** Bump `pubspec.yaml` para `1.2.1+121`; revisar `git diff` (sem reformatação alheia); `git add` só dos arquivos do plano; `gitleaks protect --staged --no-banner`.
- [ ] **Step 7:** `git commit -m "feat(home-aluno): Home do aluno fecha o contrato"`; limpar `GIT_TRACE*`; `git push`.
