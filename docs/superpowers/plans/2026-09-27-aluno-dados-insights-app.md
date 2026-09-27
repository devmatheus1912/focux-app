# Dados e insights do aluno — App (Flutter) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Home do aluno consome o payload novo do BFF (`insight`, `forcaDeltaPercent`, `recoveryStale`, `aluno` sem CRM): mostra um insight por vez no card do topo, texto de força honesto (1RM estimado) e estado de prontidão desatualizada.

**Architecture:** Parse na borda (`AlunoHomeInsight.tryParse`, tolerante a payload velho/malformado) → texto localizado em função pura (`alunoInsightTexto`, ARB pt/en/es, fallback para o texto pt do servidor) → widget fino (`AlunoHomeInsightLine`) no `_TodayFocusCard`, com a pill de ritmo como fallback. Analytics só com `tipo` e `confianca`.

**Tech Stack:** Flutter, Riverpod, go_router, gen-l10n (`S`), flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-25-aluno-dados-insights-design.md` (Parte 3).
**Pré-requisito:** plano do backend (`2026-09-27-aluno-dados-insights-backend.md`) em produção ou pelo menos mergeado. O app tolera o payload antigo, então a ordem só importa para ver o insight de verdade.

## Global Constraints

- Nunca rodar `dart format` em arquivo existente; formatar só o que for criado.
- Sem pub/versão: `pubspec.yaml` fica em `1.2.1+116`.
- Sem dependência nova.
- Nada de número de saúde/desempenho em analytics ou log.
- Não apagar nem enfraquecer teste existente; os que mudam de contrato são reescritos com asserção equivalente ou mais forte.
- Depois de `flutter gen-l10n`, reaplicar o fallback pt em `lib/l10n/app_localizations.dart` (`Localizations.of<S>(context, S) ?? lookupS(const Locale('pt'))`), como diz `l10n.yaml`.
- Verificação: `flutter analyze --fatal-warnings --fatal-infos --no-pub` e `flutter test --no-pub -r failures-only`.
- Commit: `git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "..."`, subject curto, sem trailer.

## File Map

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `lib/features/dashboard/data/aluno_home_insight.dart` | criar | modelo + parse tolerante |
| `lib/features/dashboard/data/dashboard_repository.dart` | editar | bundle lê `insight`, `forcaDeltaPercent`, `recoveryStale` |
| `lib/features/dashboard/utils/aluno_insight_display.dart` | criar | texto localizado + ícone por tipo |
| `lib/features/dashboard/utils/aluno_insight_analytics.dart` | criar | eventos com dedupe por sessão |
| `lib/features/dashboard/widgets/aluno_home_insight_line.dart` | criar | linha do insight no card do topo |
| `lib/core/analytics/analytics_service.dart` | editar | 2 constantes em `ProductEvents` |
| `lib/features/dashboard/screens/aluno_dashboard_screen.dart` | editar | passa `insight`, `forcaDeltaPercent`, `recoveryStale` |
| `lib/features/dashboard/screens/aluno_dashboard_screen_header.part.dart` | editar | insight no lugar da pill; card de evolução sem `score` |
| `lib/features/dashboard/utils/aluno_performance_evolution.dart` | editar | força só por `forcaDeltaPercent`; remove score |
| `lib/features/dashboard/utils/aluno_home_display.dart` | editar | "Como calculamos" explica Epley |
| `lib/features/health/widgets/aluno_recovery_card.dart` | editar | estado `recoveryStale` |
| `lib/core/health/recovery_score.dart` | editar | acentos |
| `lib/l10n/app_{pt,en,es}.arb` | editar | chaves `insight*` |
| testes (ver cada task) | criar/editar | |

---

### Task A1: Modelo do insight e bundle

**Files:**
- Create: `lib/features/dashboard/data/aluno_home_insight.dart`
- Modify: `lib/features/dashboard/data/dashboard_repository.dart`
- Create: `test/features/dashboard/data/aluno_home_insight_test.dart`
- Modify: `test/features/dashboard/data/aluno_dashboard_home_bundle_test.dart`

- [ ] **Step 1: Write the failing test** — `test/features/dashboard/data/aluno_home_insight_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';

Map<String, dynamic> _pr() => {
  'tipo': 'PR',
  'confianca': 'HIGH',
  'chave': 'insightPr',
  'params': {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': 2},
  'titulo': 'Novo recorde',
  'mensagem': 'Supino: 82,5 kg',
  'evidencia': 'Registrado há 2 dias',
  'acao': {'rota': '/checkin/historico', 'cta': 'Ver histórico'},
};

void main() {
  test('lê o insight completo do BFF', () {
    final i = AlunoHomeInsight.tryParse(_pr())!;
    expect(i.tipo, AlunoInsightTipo.pr);
    expect(i.confianca, AlunoInsightConfianca.high);
    expect(i.chave, 'insightPr');
    expect(i.params, {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': '2'});
    expect(i.evidencia, 'Registrado há 2 dias');
    expect(i.acao?.rota, '/checkin/historico');
  });

  test('mapeia todos os tipos do servidor', () {
    const wire = {
      'NOVO': AlunoInsightTipo.novo,
      'RECUPERACAO': AlunoInsightTipo.recuperacao,
      'PR': AlunoInsightTipo.pr,
      'RETORNO': AlunoInsightTipo.retorno,
      'META_ATINGIDA': AlunoInsightTipo.metaAtingida,
      'FORCA_SUBINDO': AlunoInsightTipo.forcaSubindo,
      'VOLUME_SUBINDO': AlunoInsightTipo.volumeSubindo,
      'CONSISTENTE': AlunoInsightTipo.consistente,
      'RITMO_CAIU': AlunoInsightTipo.ritmoCaiu,
      'DADOS_INSUFICIENTES': AlunoInsightTipo.dadosInsuficientes,
    };
    for (final e in wire.entries) {
      expect(AlunoHomeInsight.tryParse(_pr()..['tipo'] = e.key)?.tipo, e.value);
    }
  });

  test('payload ausente, desconhecido ou malformado vira null', () {
    expect(AlunoHomeInsight.tryParse(null), isNull);
    expect(AlunoHomeInsight.tryParse('PR'), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..['tipo'] = 'NOVO_TIPO_FUTURO'), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..['confianca'] = 'ALTA'), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..remove('titulo')), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..['mensagem'] = 3), isNull);
  });

  test('campos opcionais malformados não derrubam o insight', () {
    final i = AlunoHomeInsight.tryParse(
      _pr()
        ..['params'] = 'x'
        ..['evidencia'] = 7
        ..['chave'] = null
        ..['acao'] = null,
    )!;
    expect(i.params, isEmpty);
    expect(i.evidencia, isNull);
    expect(i.chave, '');
    expect(i.acao, isNull);
  });

  test('ação só aceita rota interna', () {
    for (final rota in ['https://evil.example', '//evil.example', 'saude', '']) {
      final i = AlunoHomeInsight.tryParse(
        _pr()..['acao'] = {'rota': rota, 'cta': 'Abrir'},
      )!;
      expect(i.acao, isNull, reason: rota);
    }
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test --no-pub test/features/dashboard/data/aluno_home_insight_test.dart`
Expected: FAIL (arquivo `aluno_home_insight.dart` não existe).

- [ ] **Step 3: Create `lib/features/dashboard/data/aluno_home_insight.dart`**

```dart
/// Insight único da Home do aluno, decidido pelo BFF (`GET /api/dashboard/aluno/home`).
enum AlunoInsightTipo {
  novo,
  recuperacao,
  pr,
  retorno,
  metaAtingida,
  forcaSubindo,
  volumeSubindo,
  consistente,
  ritmoCaiu,
  dadosInsuficientes,
}

enum AlunoInsightConfianca { high, medium, low }

const _tiposWire = <String, AlunoInsightTipo>{
  'NOVO': AlunoInsightTipo.novo,
  'RECUPERACAO': AlunoInsightTipo.recuperacao,
  'PR': AlunoInsightTipo.pr,
  'RETORNO': AlunoInsightTipo.retorno,
  'META_ATINGIDA': AlunoInsightTipo.metaAtingida,
  'FORCA_SUBINDO': AlunoInsightTipo.forcaSubindo,
  'VOLUME_SUBINDO': AlunoInsightTipo.volumeSubindo,
  'CONSISTENTE': AlunoInsightTipo.consistente,
  'RITMO_CAIU': AlunoInsightTipo.ritmoCaiu,
  'DADOS_INSUFICIENTES': AlunoInsightTipo.dadosInsuficientes,
};

const _confiancaWire = <String, AlunoInsightConfianca>{
  'HIGH': AlunoInsightConfianca.high,
  'MEDIUM': AlunoInsightConfianca.medium,
  'LOW': AlunoInsightConfianca.low,
};

class AlunoInsightAcao {
  const AlunoInsightAcao({required this.rota, required this.cta});

  final String rota;
  final String cta;
}

class AlunoHomeInsight {
  const AlunoHomeInsight({
    required this.tipo,
    required this.confianca,
    required this.chave,
    required this.titulo,
    required this.mensagem,
    this.params = const {},
    this.evidencia,
    this.acao,
  });

  final AlunoInsightTipo tipo;
  final AlunoInsightConfianca confianca;

  /// Chave ARB do texto; vazia quando o servidor não mandou.
  final String chave;
  final Map<String, String> params;

  /// Texto pt do servidor — fallback quando a chave não existe no app.
  final String titulo;
  final String mensagem;
  final String? evidencia;
  final AlunoInsightAcao? acao;

  /// `null` quando o payload falta, tem tipo desconhecido ou vem malformado.
  static AlunoHomeInsight? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final tipo = _tiposWire[raw['tipo']];
    final confianca = _confiancaWire[raw['confianca']];
    final titulo = raw['titulo'];
    final mensagem = raw['mensagem'];
    if (tipo == null ||
        confianca == null ||
        titulo is! String ||
        mensagem is! String) {
      return null;
    }
    final chave = raw['chave'];
    final evidencia = raw['evidencia'];
    return AlunoHomeInsight(
      tipo: tipo,
      confianca: confianca,
      chave: chave is String ? chave : '',
      params: _parseParams(raw['params']),
      titulo: titulo,
      mensagem: mensagem,
      evidencia: evidencia is String ? evidencia : null,
      acao: _parseAcao(raw['acao']),
    );
  }

  static Map<String, String> _parseParams(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.value != null) '${e.key}': '${e.value}',
    };
  }

  static AlunoInsightAcao? _parseAcao(Object? raw) {
    if (raw is! Map) return null;
    final rota = raw['rota'];
    final cta = raw['cta'];
    if (rota is! String ||
        cta is! String ||
        !rota.startsWith('/') ||
        rota.startsWith('//')) {
      return null;
    }
    return AlunoInsightAcao(rota: rota, cta: cta);
  }
}
```

- [ ] **Step 4: Run the model test**

Run: `flutter test --no-pub test/features/dashboard/data/aluno_home_insight_test.dart`
Expected: PASS (5 testes).

- [ ] **Step 5: Add failing bundle assertions** — em `aluno_dashboard_home_bundle_test.dart`:

No `_payload()`, antes do fechamento `};` (depois de `'recovery': {...},`), adicionar:

```dart
  'forcaDeltaPercent': 4.5,
  'recoveryStale': false,
  'insight': {
    'tipo': 'META_ATINGIDA',
    'confianca': 'HIGH',
    'chave': 'insightMetaAtingida',
    'params': {'feitos': '4', 'meta': '4'},
    'titulo': 'Meta da semana atingida',
    'mensagem': '4 de 4 treinos nesta semana',
    'acao': {'rota': '/checkin/treinos', 'cta': 'Ver treinos'},
  },
```

No teste `parses the aggregated BFF payload`, depois de `expect(bundle.frequenciaDias, 4);`:

```dart
      expect(bundle.forcaDeltaPercent, 4.5);
      expect(bundle.recoveryStale, isFalse);
      expect(bundle.insight?.tipo, AlunoInsightTipo.metaAtingida);
      expect(bundle.insight?.acao?.rota, '/checkin/treinos');
      // BFF não manda mais campos de CRM do personal; o modelo usa defaults.
      expect(bundle.aluno.emRisco, isFalse);
      expect(bundle.aluno.statusFinanceiro, 'ATIVO');
      expect(bundle.aluno.inadimplente, isFalse);
      expect(bundle.aluno.ultimoContato, isNull);
```

No teste `tolerates missing optional blocks`, acrescentar à cascata `..remove('forcaDeltaPercent')..remove('recoveryStale')..remove('insight')` e, no fim:

```dart
      expect(bundle.forcaDeltaPercent, isNull);
      expect(bundle.recoveryStale, isFalse);
      expect(bundle.insight, isNull);
```

Novo teste no mesmo group:

```dart
    test('insight malformado é ignorado sem derrubar a Home', () {
      final json = _payload()..['insight'] = {'tipo': 'QUALQUER'};
      final bundle = AlunoDashboardHomeBundle.fromJson(json);
      expect(bundle.insight, isNull);
      expect(bundle.aluno.nome, 'Ana Souza');
    });

    test('prontidão velha chega como recovery null + recoveryStale', () {
      final json = _payload()
        ..['recovery'] = null
        ..['recoveryStale'] = true;
      final bundle = AlunoDashboardHomeBundle.fromJson(json);
      expect(bundle.recovery, isNull);
      expect(bundle.recoveryStale, isTrue);
    });
```

Import no topo: `import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';`

- [ ] **Step 6: Run to verify it fails**

Run: `flutter test --no-pub test/features/dashboard/data/aluno_dashboard_home_bundle_test.dart`
Expected: FAIL (getters `forcaDeltaPercent`, `recoveryStale`, `insight` não existem).

- [ ] **Step 7: Bundle** — em `dashboard_repository.dart`:

Import: `import 'aluno_home_insight.dart';` (junto de `import 'command_center_data.dart';`).

Campos, depois de `final int? frequenciaDias;`:

```dart
  /// e1RM médio, semana atual vs anterior (só exercícios em comum); null = sem base.
  final double? forcaDeltaPercent;
  /// Última prontidão tem mais de 1 dia: o BFF manda `recovery: null` + true.
  final bool recoveryStale;
  final AlunoHomeInsight? insight;
```

Construtor, depois de `this.frequenciaDias,`:

```dart
    this.forcaDeltaPercent,
    this.recoveryStale = false,
    this.insight,
```

`fromJson`, depois de `frequenciaDias: (json['frequenciaDias'] as num?)?.toInt(),`:

```dart
      forcaDeltaPercent: (json['forcaDeltaPercent'] as num?)?.toDouble(),
      recoveryStale: json['recoveryStale'] as bool? ?? false,
      insight: AlunoHomeInsight.tryParse(json['insight']),
```

- [ ] **Step 8: Run bundle + model tests**

Run: `flutter test --no-pub test/features/dashboard/data/`
Expected: PASS.

- [ ] **Step 9: Commit**

```powershell
git add lib/features/dashboard/data/aluno_home_insight.dart lib/features/dashboard/data/dashboard_repository.dart test/features/dashboard/data/aluno_home_insight_test.dart test/features/dashboard/data/aluno_dashboard_home_bundle_test.dart
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "feat(home-aluno): lê insight e força do BFF"
```

---

### Task A2: Texto localizado do insight

**Files:**
- Modify: `lib/l10n/app_pt.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` (+ gerados `lib/l10n/app_localizations*.dart`)
- Create: `lib/features/dashboard/utils/aluno_insight_display.dart`
- Create: `test/features/dashboard/utils/aluno_insight_display_test.dart`

Params do servidor (backend Task 4): `insightPr` → `exercicio`, `cargaKg` (ponto decimal), `dias`; `insightRecuperacao` → `score`; `insightRetorno` → `dias`; `insightMetaAtingida` → `feitos`, `meta`; `insightForcaSubindo` → `pct` (ponto decimal), `n`; `insightVolumeSubindo` → `pct` (inteiro); `insightConsistente`/`insightRitmoCaiu` → `feitos`; `insightSequencia` → `semanas`.

- [ ] **Step 1: ARB pt** — em `app_pt.arb`, colocar vírgula depois do último valor (`"referralHelpRulesBody": "..."`) e inserir antes do `}` final:

```json
  "insightNovoTitulo": "Seu histórico começa aqui",
  "insightNovoDetalhe": "Complete seu primeiro treino.",
  "insightRecuperacaoTitulo": "Dia para ir mais leve",
  "insightRecuperacaoDetalhe": "Prontidão {score}/100. Alinhe o treino com seu personal.",
  "@insightRecuperacaoDetalhe": { "placeholders": { "score": { "type": "int" } } },
  "insightPrTitulo": "Novo recorde",
  "insightPrDetalhe": "{exercicio}: {carga} kg · {dias, plural, =0{hoje} =1{ontem} other{há {dias} dias}}",
  "@insightPrDetalhe": { "placeholders": { "exercicio": { "type": "String" }, "carga": { "type": "String" }, "dias": { "type": "int" } } },
  "insightRetornoTitulo": "Bora retomar",
  "insightRetornoDetalhe": "{dias} dias sem treinar. Seu próximo treino está pronto.",
  "@insightRetornoDetalhe": { "placeholders": { "dias": { "type": "int" } } },
  "insightMetaAtingidaTitulo": "Meta da semana atingida",
  "insightMetaAtingidaDetalhe": "{feitos} de {meta} treinos nesta semana",
  "@insightMetaAtingidaDetalhe": { "placeholders": { "feitos": { "type": "int" }, "meta": { "type": "int" } } },
  "insightForcaSubindoTitulo": "Sua força está subindo",
  "insightForcaSubindoDetalhe": "+{pct}% vs semana passada ({n} exercícios)",
  "@insightForcaSubindoDetalhe": { "placeholders": { "pct": { "type": "String" }, "n": { "type": "int" } } },
  "insightVolumeSubindoTitulo": "Seu volume está subindo",
  "insightVolumeSubindoDetalhe": "+{pct}% vs média das 6 semanas anteriores",
  "@insightVolumeSubindoDetalhe": { "placeholders": { "pct": { "type": "String" } } },
  "insightConsistenteTitulo": "Ritmo forte",
  "insightTreinos7dDetalhe": "{feitos, plural, =1{1 treino nos últimos 7 dias} other{{feitos} treinos nos últimos 7 dias}}",
  "@insightTreinos7dDetalhe": { "placeholders": { "feitos": { "type": "int" } } },
  "insightSequenciaDetalhe": "{semanas} semanas seguidas treinando",
  "@insightSequenciaDetalhe": { "placeholders": { "semanas": { "type": "int" } } },
  "insightRitmoCaiuTitulo": "Seu ritmo caiu esta semana",
  "insightDadosInsuficientesTitulo": "Continue treinando",
  "insightDadosInsuficientesDetalhe": "Continue treinando para construirmos seu histórico.",
  "insightCtaTreinos": "Ver treinos",
  "insightCtaHistorico": "Ver histórico",
  "insightCtaSaude": "Ver prontidão"
```

- [ ] **Step 2: ARB en** — mesma posição em `app_en.arb` (sem blocos `@`):

```json
  "insightNovoTitulo": "Your history starts here",
  "insightNovoDetalhe": "Complete your first workout.",
  "insightRecuperacaoTitulo": "A day to go lighter",
  "insightRecuperacaoDetalhe": "Readiness {score}/100. Check today's workout with your trainer.",
  "insightPrTitulo": "New record",
  "insightPrDetalhe": "{exercicio}: {carga} kg · {dias, plural, =0{today} =1{yesterday} other{{dias} days ago}}",
  "insightRetornoTitulo": "Let's get back to it",
  "insightRetornoDetalhe": "{dias} days without training. Your next workout is ready.",
  "insightMetaAtingidaTitulo": "Weekly goal reached",
  "insightMetaAtingidaDetalhe": "{feitos} of {meta} workouts this week",
  "insightForcaSubindoTitulo": "Your strength is going up",
  "insightForcaSubindoDetalhe": "+{pct}% vs last week ({n} exercises)",
  "insightVolumeSubindoTitulo": "Your volume is going up",
  "insightVolumeSubindoDetalhe": "+{pct}% vs the previous 6-week average",
  "insightConsistenteTitulo": "Strong rhythm",
  "insightTreinos7dDetalhe": "{feitos, plural, =1{1 workout in the last 7 days} other{{feitos} workouts in the last 7 days}}",
  "insightSequenciaDetalhe": "{semanas} weeks in a row",
  "insightRitmoCaiuTitulo": "Your rhythm dropped this week",
  "insightDadosInsuficientesTitulo": "Keep training",
  "insightDadosInsuficientesDetalhe": "Keep training so we can build your history.",
  "insightCtaTreinos": "See workouts",
  "insightCtaHistorico": "See history",
  "insightCtaSaude": "See readiness"
```

- [ ] **Step 3: ARB es** — mesma posição em `app_es.arb`:

```json
  "insightNovoTitulo": "Tu historial empieza aquí",
  "insightNovoDetalhe": "Completa tu primer entrenamiento.",
  "insightRecuperacaoTitulo": "Día para ir más suave",
  "insightRecuperacaoDetalhe": "Preparación {score}/100. Coordina el entrenamiento con tu entrenador.",
  "insightPrTitulo": "Nuevo récord",
  "insightPrDetalhe": "{exercicio}: {carga} kg · {dias, plural, =0{hoy} =1{ayer} other{hace {dias} días}}",
  "insightRetornoTitulo": "A retomar",
  "insightRetornoDetalhe": "{dias} días sin entrenar. Tu próximo entrenamiento está listo.",
  "insightMetaAtingidaTitulo": "Meta semanal cumplida",
  "insightMetaAtingidaDetalhe": "{feitos} de {meta} entrenamientos esta semana",
  "insightForcaSubindoTitulo": "Tu fuerza está subiendo",
  "insightForcaSubindoDetalhe": "+{pct}% vs la semana pasada ({n} ejercicios)",
  "insightVolumeSubindoTitulo": "Tu volumen está subiendo",
  "insightVolumeSubindoDetalhe": "+{pct}% vs el promedio de las 6 semanas anteriores",
  "insightConsistenteTitulo": "Ritmo fuerte",
  "insightTreinos7dDetalhe": "{feitos, plural, =1{1 entrenamiento en los últimos 7 días} other{{feitos} entrenamientos en los últimos 7 días}}",
  "insightSequenciaDetalhe": "{semanas} semanas seguidas entrenando",
  "insightRitmoCaiuTitulo": "Tu ritmo bajó esta semana",
  "insightDadosInsuficientesTitulo": "Sigue entrenando",
  "insightDadosInsuficientesDetalhe": "Sigue entrenando para construir tu historial.",
  "insightCtaTreinos": "Ver entrenamientos",
  "insightCtaHistorico": "Ver historial",
  "insightCtaSaude": "Ver preparación"
```

- [ ] **Step 4: Gerar l10n e reaplicar fallback**

Run: `flutter gen-l10n`
Expected: sem erro nem "untranslated messages".
Depois, em `lib/l10n/app_localizations.dart`, conferir que `S.of` continua `return Localizations.of<S>(context, S) ?? lookupS(const Locale('pt'));` (o gerador troca por `!`; reaplicar se mudou). `git diff lib/l10n/app_localizations.dart` deve mostrar só getters/métodos `insight*` adicionados.

- [ ] **Step 5: Write the failing test** — `test/features/dashboard/utils/aluno_insight_display_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_insight_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

AlunoHomeInsight _insight(
  String chave,
  Map<String, String> params, {
  AlunoInsightTipo tipo = AlunoInsightTipo.pr,
  String? evidencia,
  AlunoInsightAcao? acao,
}) => AlunoHomeInsight(
  tipo: tipo,
  confianca: AlunoInsightConfianca.high,
  chave: chave,
  params: params,
  titulo: 'Título do servidor',
  mensagem: 'Mensagem do servidor',
  evidencia: evidencia,
  acao: acao,
);

void main() {
  final pt = lookupS(const Locale('pt'));
  final en = lookupS(const Locale('en'));

  test('PR em pt usa vírgula decimal e plural de dias', () {
    final t = alunoInsightTexto(
      pt,
      _insight('insightPr', {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': '2'}),
    );
    expect(t.titulo, 'Novo recorde');
    expect(t.detalhe, 'Supino: 82,5 kg · há 2 dias');
  });

  test('PR em en mantém ponto e diz today', () {
    final t = alunoInsightTexto(
      en,
      _insight('insightPr', {'exercicio': 'Bench', 'cargaKg': '82.5', 'dias': '0'}),
    );
    expect(t.detalhe, 'Bench: 82.5 kg · today');
  });

  test('cobre todas as chaves do servidor', () {
    final casos = <String, (Map<String, String>, String)>{
      'insightNovo': (const {}, 'Complete seu primeiro treino.'),
      'insightRecuperacao': (const {'score': '40'}, 'Prontidão 40/100. Alinhe o treino com seu personal.'),
      'insightRetorno': (const {'dias': '9'}, '9 dias sem treinar. Seu próximo treino está pronto.'),
      'insightMetaAtingida': (const {'feitos': '4', 'meta': '3'}, '4 de 3 treinos nesta semana'),
      'insightForcaSubindo': (const {'pct': '4.5', 'n': '3'}, '+4,5% vs semana passada (3 exercícios)'),
      'insightVolumeSubindo': (const {'pct': '12'}, '+12% vs média das 6 semanas anteriores'),
      'insightConsistente': (const {'feitos': '1'}, '1 treino nos últimos 7 dias'),
      'insightSequencia': (const {'semanas': '5'}, '5 semanas seguidas treinando'),
      'insightRitmoCaiu': (const {'feitos': '0'}, '0 treinos nos últimos 7 dias'),
      'insightDadosInsuficientes': (const {}, 'Continue treinando para construirmos seu histórico.'),
    };
    for (final e in casos.entries) {
      expect(alunoInsightTexto(pt, _insight(e.key, e.value.$1)).detalhe, e.value.$2, reason: e.key);
    }
  });

  test('chave desconhecida ou param faltando cai no texto do servidor', () {
    final semChave = alunoInsightTexto(pt, _insight('insightFuturo', const {}, evidencia: 'há 2 dias'));
    expect(semChave.titulo, 'Título do servidor');
    expect(semChave.detalhe, 'Mensagem do servidor · há 2 dias');

    final semParam = alunoInsightTexto(pt, _insight('insightRetorno', const {}));
    expect(semParam.detalhe, 'Mensagem do servidor');

    final paramRuim = alunoInsightTexto(pt, _insight('insightForcaSubindo', const {'pct': 'abc', 'n': '3'}));
    expect(paramRuim.titulo, 'Título do servidor');
  });

  test('CTA localizado pela rota; rota desconhecida usa o cta do servidor', () {
    String? cta(String rota) => alunoInsightTexto(
      en,
      _insight('insightNovo', const {}, acao: AlunoInsightAcao(rota: rota, cta: 'Abrir')),
    ).cta;
    expect(cta('/checkin/treinos'), 'See workouts');
    expect(cta('/checkin/historico'), 'See history');
    expect(cta('/saude'), 'See readiness');
    expect(cta('/outra'), 'Abrir');
    expect(alunoInsightTexto(en, _insight('insightNovo', const {})).cta, isNull);
  });
}
```

- [ ] **Step 6: Run to verify it fails**

Run: `flutter test --no-pub test/features/dashboard/utils/aluno_insight_display_test.dart`
Expected: FAIL (`aluno_insight_display.dart` não existe).

- [ ] **Step 7: Create `lib/features/dashboard/utils/aluno_insight_display.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';

typedef AlunoInsightTexto = ({String titulo, String detalhe, String? cta});

/// Texto do insight no idioma do app; chave ou param inválido → texto pt do servidor.
AlunoInsightTexto alunoInsightTexto(S s, AlunoHomeInsight insight) {
  final cta = _cta(s, insight.acao);
  final local = _localizado(s, insight);
  if (local != null) {
    return (titulo: local.$1, detalhe: local.$2, cta: cta);
  }
  final evidencia = insight.evidencia;
  return (
    titulo: insight.titulo,
    detalhe:
        evidencia == null ? insight.mensagem : '${insight.mensagem} · $evidencia',
    cta: cta,
  );
}

IconData alunoInsightIcone(AlunoInsightTipo tipo) => switch (tipo) {
  AlunoInsightTipo.pr => Icons.emoji_events_outlined,
  AlunoInsightTipo.forcaSubindo ||
  AlunoInsightTipo.volumeSubindo => Icons.trending_up_rounded,
  AlunoInsightTipo.recuperacao => Icons.bedtime_outlined,
  AlunoInsightTipo.metaAtingida => Icons.check_circle_outline_rounded,
  AlunoInsightTipo.ritmoCaiu => Icons.trending_down_rounded,
  _ => Icons.insights_rounded,
};

(String, String)? _localizado(S s, AlunoHomeInsight insight) {
  final p = insight.params;
  int? inteiro(String k) => int.tryParse(p[k] ?? '');
  String? numero(String k) {
    final raw = p[k];
    if (raw == null || double.tryParse(raw) == null) return null;
    return s.localeName.startsWith('en') ? raw : raw.replaceAll('.', ',');
  }

  switch (insight.chave) {
    case 'insightNovo':
      return (s.insightNovoTitulo, s.insightNovoDetalhe);
    case 'insightRecuperacao':
      final score = inteiro('score');
      if (score == null) return null;
      return (s.insightRecuperacaoTitulo, s.insightRecuperacaoDetalhe(score));
    case 'insightPr':
      final exercicio = p['exercicio'];
      final carga = numero('cargaKg');
      final dias = inteiro('dias');
      if (exercicio == null || carga == null || dias == null) return null;
      return (s.insightPrTitulo, s.insightPrDetalhe(exercicio, carga, dias));
    case 'insightRetorno':
      final dias = inteiro('dias');
      if (dias == null) return null;
      return (s.insightRetornoTitulo, s.insightRetornoDetalhe(dias));
    case 'insightMetaAtingida':
      final feitos = inteiro('feitos');
      final meta = inteiro('meta');
      if (feitos == null || meta == null) return null;
      return (
        s.insightMetaAtingidaTitulo,
        s.insightMetaAtingidaDetalhe(feitos, meta),
      );
    case 'insightForcaSubindo':
      final pct = numero('pct');
      final n = inteiro('n');
      if (pct == null || n == null) return null;
      return (s.insightForcaSubindoTitulo, s.insightForcaSubindoDetalhe(pct, n));
    case 'insightVolumeSubindo':
      final pct = numero('pct');
      if (pct == null) return null;
      return (s.insightVolumeSubindoTitulo, s.insightVolumeSubindoDetalhe(pct));
    case 'insightConsistente':
      final feitos = inteiro('feitos');
      if (feitos == null) return null;
      return (s.insightConsistenteTitulo, s.insightTreinos7dDetalhe(feitos));
    case 'insightSequencia':
      final semanas = inteiro('semanas');
      if (semanas == null) return null;
      return (s.insightConsistenteTitulo, s.insightSequenciaDetalhe(semanas));
    case 'insightRitmoCaiu':
      final feitos = inteiro('feitos');
      if (feitos == null) return null;
      return (s.insightRitmoCaiuTitulo, s.insightTreinos7dDetalhe(feitos));
    case 'insightDadosInsuficientes':
      return (
        s.insightDadosInsuficientesTitulo,
        s.insightDadosInsuficientesDetalhe,
      );
  }
  return null;
}

String? _cta(S s, AlunoInsightAcao? acao) {
  if (acao == null) return null;
  return switch (acao.rota) {
    '/checkin/treinos' => s.insightCtaTreinos,
    '/checkin/historico' => s.insightCtaHistorico,
    '/saude' => s.insightCtaSaude,
    _ => acao.cta,
  };
}
```

- [ ] **Step 8: Run the display test**

Run: `flutter test --no-pub test/features/dashboard/utils/aluno_insight_display_test.dart`
Expected: PASS. Se o `detalhe` de `insightPr` vier diferente, conferir o gerado em `app_localizations_pt.dart` (plural embutido em texto é suportado pelo gen-l10n atual; se não for, separar em `insightPrQuando` e juntar com `' · '` no resolver).

- [ ] **Step 9: Commit**

```powershell
git add lib/l10n lib/features/dashboard/utils/aluno_insight_display.dart test/features/dashboard/utils/aluno_insight_display_test.dart
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "feat(home-aluno): textos do insight em pt, en e es"
```

---

### Task A3: Insight no card do topo + analytics

**Files:**
- Create: `lib/features/dashboard/utils/aluno_insight_analytics.dart`
- Create: `lib/features/dashboard/widgets/aluno_home_insight_line.dart`
- Modify: `lib/core/analytics/analytics_service.dart`
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen.dart`
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen_header.part.dart`
- Create: `test/features/dashboard/widgets/aluno_home_insight_line_test.dart`

- [ ] **Step 1: Eventos** — em `ProductEvents` (`analytics_service.dart`), depois da última constante `aluno*` existente:

```dart
  static const alunoInsightViewed = 'aluno_insight_viewed';
  static const alunoInsightActionTapped = 'aluno_insight_action_tapped';
```

- [ ] **Step 2: Write the failing test** — `test/features/dashboard/widgets/aluno_home_insight_line_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_insight_analytics.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_insight_line.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _pr = AlunoHomeInsight(
  tipo: AlunoInsightTipo.pr,
  confianca: AlunoInsightConfianca.high,
  chave: 'insightPr',
  params: {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': '2'},
  titulo: 'Novo recorde',
  mensagem: 'Supino: 82,5 kg',
  acao: AlunoInsightAcao(rota: '/checkin/historico', cta: 'Ver histórico'),
);

Future<void> _pump(WidgetTester tester, AlunoHomeInsight insight, ValueChanged<String> onAction) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(
        body: AlunoHomeInsightLine(insight: insight, onPrimary: Colors.black54, onAction: onAction),
      ),
    ),
  );
}

void main() {
  setUp(AlunoInsightAnalytics.resetSessao);

  testWidgets('mostra título, detalhe e CTA; toque navega para a rota', (tester) async {
    String? rota;
    await _pump(tester, _pr, (r) => rota = r);

    expect(find.text('Novo recorde'), findsOneWidget);
    expect(find.text('Supino: 82,5 kg · há 2 dias'), findsOneWidget);
    expect(find.text('Ver histórico'), findsOneWidget);

    await tester.tap(find.byType(AlunoHomeInsightLine));
    expect(rota, '/checkin/historico');
  });

  testWidgets('sem ação não mostra CTA e não é botão', (tester) async {
    const semAcao = AlunoHomeInsight(
      tipo: AlunoInsightTipo.dadosInsuficientes,
      confianca: AlunoInsightConfianca.low,
      chave: 'insightDadosInsuficientes',
      titulo: 'Continue treinando',
      mensagem: 'Continue treinando para construirmos seu histórico.',
    );
    var tocou = false;
    await _pump(tester, semAcao, (_) => tocou = true);

    expect(find.text('Continue treinando'), findsOneWidget);
    expect(find.textContaining('Ver '), findsNothing);
    await tester.tap(find.byType(AlunoHomeInsightLine));
    expect(tocou, isFalse);
  });

  test('visualização conta uma vez por tipo na sessão', () {
    expect(AlunoInsightAnalytics.viewed(_pr), isTrue);
    expect(AlunoInsightAnalytics.viewed(_pr), isFalse);
    expect(AlunoInsightAnalytics.props(_pr), {'tipo': 'pr', 'confianca': 'high'});
  });
}
```

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test --no-pub test/features/dashboard/widgets/aluno_home_insight_line_test.dart`
Expected: FAIL (arquivos não existem).

- [ ] **Step 4: Create `lib/features/dashboard/utils/aluno_insight_analytics.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../../../core/analytics/analytics_service.dart';
import '../data/aluno_home_insight.dart';

/// Eventos do insight da Home: só tipo e confiança, nunca números de saúde/desempenho.
class AlunoInsightAnalytics {
  AlunoInsightAnalytics._();

  static final Set<AlunoInsightTipo> _vistosNaSessao = {};

  static Map<String, Object?> props(AlunoHomeInsight insight) => {
    'tipo': insight.tipo.name,
    'confianca': insight.confianca.name,
  };

  /// `false` quando o tipo já foi registrado nesta sessão.
  static bool viewed(AlunoHomeInsight insight) {
    if (!_vistosNaSessao.add(insight.tipo)) return false;
    AnalyticsService.instance.track(
      ProductEvents.alunoInsightViewed,
      props: props(insight),
    );
    return true;
  }

  static void actionTapped(AlunoHomeInsight insight) {
    AnalyticsService.instance.track(
      ProductEvents.alunoInsightActionTapped,
      props: props(insight),
    );
  }

  @visibleForTesting
  static void resetSessao() => _vistosNaSessao.clear();
}
```

- [ ] **Step 5: Create `lib/features/dashboard/widgets/aluno_home_insight_line.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';
import '../utils/aluno_insight_analytics.dart';
import '../utils/aluno_insight_display.dart';

/// Um insight por vez no card "Hoje"; substitui a pill de ritmo quando o BFF manda.
class AlunoHomeInsightLine extends StatefulWidget {
  const AlunoHomeInsightLine({
    super.key,
    required this.insight,
    required this.onPrimary,
    required this.onAction,
  });

  final AlunoHomeInsight insight;
  final Color onPrimary;
  final ValueChanged<String> onAction;

  @override
  State<AlunoHomeInsightLine> createState() => _AlunoHomeInsightLineState();
}

class _AlunoHomeInsightLineState extends State<AlunoHomeInsightLine> {
  @override
  void initState() {
    super.initState();
    AlunoInsightAnalytics.viewed(widget.insight);
  }

  @override
  void didUpdateWidget(covariant AlunoHomeInsightLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insight.tipo != widget.insight.tipo) {
      AlunoInsightAnalytics.viewed(widget.insight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    final texto = alunoInsightTexto(S.of(context), insight);
    final acao = insight.acao;
    final cta = acao == null ? null : texto.cta;
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: cta != null,
      label: [texto.titulo, texto.detalhe, if (cta != null) cta].join('. '),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.s2),
        onTap:
            cta == null
                ? null
                : () {
                  AlunoInsightAnalytics.actionTapped(insight);
                  widget.onAction(acao!.rota);
                },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                alunoInsightIcone(insight.tipo),
                size: 18,
                color: widget.onPrimary,
              ),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      texto.titulo,
                      style: FocuxHubTypography.chip(widget.onPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      texto.detalhe,
                      style: FocuxHubTypography.bodyMuted(color: widget.onPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (cta != null) ...[
                const SizedBox(width: TokensStrip.s2),
                Text(cta, style: FocuxHubTypography.chip(primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run the widget test**

Run: `flutter test --no-pub test/features/dashboard/widgets/aluno_home_insight_line_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 7: Wire no `_TodayFocusCard`** — em `aluno_dashboard_screen_header.part.dart`:

Campo e construtor:

```dart
class _TodayFocusCard extends StatelessWidget {
  final AlunoHomeExperience experience;
  final int streakAtual;
  final AlunoHomeInsight? insight;
  final bool isDark;

  const _TodayFocusCard({
    required this.experience,
    required this.streakAtual,
    required this.isDark,
    this.insight,
  });
```

Trocar o bloco `Wrap(... _WorkoutInsightPill(... label: score.rhythmLabel ...) ...)` (depois de `const SizedBox(height: TokensStrip.s3),`) por:

```dart
          if (insight case final insight?)
            AlunoHomeInsightLine(
              insight: insight,
              onPrimary: mute,
              onAction: (rota) => context.push(rota),
            )
          else
            Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                _WorkoutInsightPill(
                  icon: Icons.trending_up_rounded,
                  label: score.rhythmLabel,
                  onPrimary: mute,
                ),
              ],
            ),
```

Em `aluno_dashboard_screen.dart`: imports `import '../data/aluno_home_insight.dart';` e `import '../widgets/aluno_home_insight_line.dart';` (junto dos outros `../data/` e `../widgets/`), e na chamada:

```dart
                      _TodayFocusCard(
                        experience: experience,
                        streakAtual: home.streakAtual,
                        insight: home.insight,
                        isDark: isDark,
                      ),
```

- [ ] **Step 8: Contratos da Home**

Run: `flutter test --no-pub -r failures-only test/features/dashboard`
Expected: PASS. O contrato visual continua achando `class _WorkoutInsightPill` e `score.rhythmLabel` no fonte (fallback) e nenhum `score.riskLabel`.

- [ ] **Step 9: Commit**

```powershell
git add lib/core/analytics/analytics_service.dart lib/features/dashboard/utils/aluno_insight_analytics.dart lib/features/dashboard/widgets/aluno_home_insight_line.dart lib/features/dashboard/screens/aluno_dashboard_screen.dart lib/features/dashboard/screens/aluno_dashboard_screen_header.part.dart test/features/dashboard/widgets/aluno_home_insight_line_test.dart
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "feat(home-aluno): um insight por vez no card de hoje"
```

---

### Task A4: Força honesta e limpeza do score

**Files:**
- Modify: `lib/features/dashboard/utils/aluno_performance_evolution.dart`
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen_header.part.dart`
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen.dart`
- Modify: `lib/features/dashboard/utils/aluno_home_display.dart`
- Modify: `test/features/dashboard/aluno_performance_evolution_test.dart`

- [ ] **Step 1: Rewrite the test** — `test/features/dashboard/aluno_performance_evolution_test.dart` inteiro:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_performance_evolution.dart';

void main() {
  group('alunoPerformanceForcaDeltaInsight', () {
    test('usa o delta de 1RM estimado do servidor', () {
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: 4.5),
        'Força (1RM est.) +4,5% vs semana passada',
      );
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: -2),
        'Força (1RM est.) -2% vs semana passada',
      );
    });

    test('sem delta não inventa comparação a partir das séries', () {
      expect(
        alunoPerformanceForcaDeltaInsight(
          forcaDeltaPercent: null,
          forcaPorSemana: const [20, 22, 24, 26, 28, 30, 32, 40],
        ),
        'Volume e força nas últimas semanas',
      );
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: 0, volumePorSemana: const [0, 10]),
        'Volume e força nas últimas semanas',
      );
    });

    test('sem série nenhuma pede registro', () {
      expect(
        alunoPerformanceForcaDeltaInsight(forcaDeltaPercent: null),
        'Registre as séries para ver carga e volume.',
      );
    });
  });

  group('buildAlunoPerformanceEvolutionView', () {
    test('monta insight e chart a partir das séries', () {
      final view = buildAlunoPerformanceEvolutionView(
        historico: const [],
        volumeSemanaKg: 240,
        volumeMesKg: 1800,
        volumePorSemana: const [10, 20, 30, 40, 50, 60, 70, 80],
        forcaPorSemana: const [20, 22, 24, 26, 28, 30, 32, 40],
        forcaDeltaPercent: 25,
      );
      expect(view.hasChart, isTrue);
      expect(view.insight, 'Força (1RM est.) +25% vs semana passada');
    });

    test('insight não usa jargão de sinal verde', () {
      final view = buildAlunoPerformanceEvolutionView(
        historico: const [],
        volumeSemanaKg: 0,
        volumeMesKg: 0,
        volumePorSemana: const [],
        forcaPorSemana: const [],
        forcaDeltaPercent: null,
      );
      expect(view.insight, 'Registre as séries para ver carga e volume.');
      expect(view.insight, isNot(contains('Sinal verde')));
      expect(view.ultimoPrLabel, '—');
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test --no-pub test/features/dashboard/aluno_performance_evolution_test.dart`
Expected: FAIL (parâmetro `forcaDeltaPercent` não existe; `score` ainda obrigatório).

- [ ] **Step 3: Util** — em `aluno_performance_evolution.dart`:

1. Remover `import '../data/aluno_autonomy_plan.dart';`.
2. Remover de `AlunoPerformanceEvolutionView` os campos `score` e `scoreLabel` e os `required this.score,` / `required this.scoreLabel,` do construtor.
3. Apagar a função `alunoPerformanceScoreLabel`.
4. Substituir `alunoPerformanceForcaDeltaInsight` por:

```dart
String alunoPerformanceForcaDeltaInsight({
  required double? forcaDeltaPercent,
  List<double> volumePorSemana = const [],
  List<double> forcaPorSemana = const [],
}) {
  final delta = forcaDeltaPercent;
  if (delta != null && delta != 0) {
    final sinal = delta > 0 ? '+' : '';
    return 'Força (1RM est.) $sinal${_fmtNumero(delta)}% vs semana passada';
  }
  final hasSeries =
      volumePorSemana.any((v) => v > 0) || forcaPorSemana.any((v) => v > 0);
  if (hasSeries) return 'Volume e força nas últimas semanas';
  return 'Registre as séries para ver carga e volume.';
}
```

5. Em `buildAlunoPerformanceEvolutionView`: trocar `required FocuxScore score,` por `required double? forcaDeltaPercent,`; remover `score: score.value,` e `scoreLabel: ...`; a chamada do insight vira:

```dart
    insight: alunoPerformanceForcaDeltaInsight(
      forcaDeltaPercent: forcaDeltaPercent,
      forcaPorSemana: forca,
      volumePorSemana: volume,
    ),
```

(`alunoUltimaEvolucaoPerformance` e `ultimaEvolucao` continuam: alimentam `ultimoPrLabel` e a linha "antes → depois" do card.)

- [ ] **Step 4: Card de evolução** — em `aluno_dashboard_screen_header.part.dart`, `_PerformanceEvolutionCard`:
- trocar `final FocuxScore score;` por `final double? forcaDeltaPercent;` e `required this.score,` por `required this.forcaDeltaPercent,`;
- na chamada `buildAlunoPerformanceEvolutionView(`, trocar `score: score,` por `forcaDeltaPercent: forcaDeltaPercent,`;
- legenda: `_LegendDot(color: EagleTokens.good, label: 'Força (1RM est.)'),`.

Em `aluno_dashboard_screen.dart`, na chamada `_PerformanceEvolutionCard(`, trocar `score: experience.score,` por `forcaDeltaPercent: home.forcaDeltaPercent,`.

- [ ] **Step 5: "Como calculamos"** — `aluno_home_display.dart`:

```dart
const alunoHomeComoCalculamos =
    'O foco do dia sai do plano, dos treinos e do último check-in. Prontidão vem do wearable quando você autoriza. '
    'Força é o 1RM estimado (Epley) da melhor série de cada exercício; a variação compara só exercícios feitos nas duas semanas.';
```

- [ ] **Step 6: Mortos**

Run: `rg -n "alunoPerformanceScoreLabel|scoreLabel|view\.score\b" lib test`
Expected: nenhum resultado (a busca é sensível a maiúsculas, então `qualidadeScoreLabel` não casa). `FocuxScore` continua usado (`experience.score.rhythmLabel`, `_mainHomeAction`).

- [ ] **Step 7: Run tests + analyze do pacote**

Run: `flutter test --no-pub -r failures-only test/features/dashboard` e `flutter analyze --fatal-warnings --fatal-infos --no-pub lib/features/dashboard`
Expected: PASS e `No issues found!`.

- [ ] **Step 8: Commit**

```powershell
git add lib/features/dashboard test/features/dashboard/aluno_performance_evolution_test.dart
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "fix(home-aluno): força pelo 1RM estimado, sem score solto"
```

---

### Task A5: Prontidão desatualizada e acentos

**Files:**
- Modify: `lib/features/health/widgets/aluno_recovery_card.dart`
- Modify: `lib/core/health/recovery_score.dart`
- Modify: `lib/features/dashboard/screens/aluno_dashboard_screen.dart`
- Create: `test/features/health/widgets/aluno_recovery_card_stale_test.dart`

- [ ] **Step 1: Write the failing test** — `test/features/health/widgets/aluno_recovery_card_stale_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/widgets/aluno_recovery_card.dart';

Future<void> _pump(WidgetTester tester, {required bool stale, bool hist = true}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AlunoRecoveryCard(
            isDark: false,
            snapshot: null,
            hasWearableHistory: hist,
            recoveryStale: stale,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('prontidão velha pede sincronizar em vez de sumir', (tester) async {
    await _pump(tester, stale: true);
    expect(find.text('Sincronize a Saúde para ver a prontidão de hoje.'), findsOneWidget);
  });

  testWidgets('sem histórico e sem stale continua escondido', (tester) async {
    await _pump(tester, stale: false, hist: false);
    expect(find.byType(InkWell), findsNothing);
    expect(find.textContaining('Sincronize'), findsNothing);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test --no-pub test/features/health/widgets/aluno_recovery_card_stale_test.dart`
Expected: FAIL (parâmetro `recoveryStale` não existe).

- [ ] **Step 3: Card** — em `aluno_recovery_card.dart`:

Construtor e campo:

```dart
  const AlunoRecoveryCard({
    super.key,
    required this.isDark,
    this.snapshot = _unset,
    this.hasWearableHistory,
    this.recoveryStale = false,
  });
```

```dart
  /// Home BFF: última prontidão tem mais de 1 dia (o BFF manda `snapshot: null`).
  final bool recoveryStale;
```

No ramo `_fromBundle` do `build`:

```dart
    if (_fromBundle) {
      final snap = snapshot as RecoverySnapshot?;
      if (snap == null && recoveryStale) {
        return _ConnectCard(
          isDark: isDark,
          message: 'Sincronize a Saúde para ver a prontidão de hoje.',
          onTap: () => context.push('/saude'),
        );
      }
      final hist = hasWearableHistory ?? (snap != null);
      if (!hist || snap == null) return const SizedBox.shrink();
      return _buildFromSnapshot(context, snap);
    }
```

`_ConnectCard` ganha `message` opcional:

```dart
class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.isDark,
    required this.onTap,
    this.message =
        'Conecte Apple Health ou Google Fit para ver sua prontidão diária.',
  });

  final bool isDark;
  final VoidCallback onTap;
  final String message;
```

e o `Text('Conecte Apple Health ou Google Fit para ver sua prontidão diária.', ...)` vira `Text(message, ...)`.

- [ ] **Step 4: Home passa o flag** — em `aluno_dashboard_screen.dart`:

```dart
                      AlunoRecoveryCard(
                        isDark: isDark,
                        snapshot: home.recovery,
                        hasWearableHistory: home.hasWearableHistory,
                        recoveryStale: home.recoveryStale,
                      ),
```

- [ ] **Step 5: Acentos** — `recovery_score.dart`: `'Recuperacao parcial'` → `'Recuperação parcial'`; `'Priorize mobilidade, sono e hidratacao antes de intensificar.'` → `'Priorize mobilidade, sono e hidratação antes de intensificar.'`. Depois: `rg -n "Recuperacao parcial|hidratacao" lib test` → nenhum resultado.

- [ ] **Step 6: Run tests**

Run: `flutter test --no-pub -r failures-only test/features/health test/core/health`
Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/features/health/widgets/aluno_recovery_card.dart lib/core/health/recovery_score.dart lib/features/dashboard/screens/aluno_dashboard_screen.dart test/features/health/widgets/aluno_recovery_card_stale_test.dart
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "fix(saude): prontidão velha pede sincronizar"
```

---

### Task A6: Verificação completa e push

- [ ] **Step 1: Analyze**

Run: `flutter analyze --fatal-warnings --fatal-infos --no-pub`
Expected: `No issues found!` (falha se sobrou `unused_*` do score removido).

- [ ] **Step 2: Suíte completa**

Run: `flutter test --no-pub -r failures-only`
Expected: todos verdes; contagem ≥ a de antes do plano (~3.979) + os novos.

- [ ] **Step 3: Segredos**

Run: `gitleaks git --log-opts="origin/main..HEAD" --no-banner` (ou `gitleaks detect --no-banner` se a versão for antiga)
Expected: `no leaks found`. Conferir também `git diff origin/main --stat`: nada de `.env*`, `google-services.json`, `key.properties`, dumps.

- [ ] **Step 4: Push**

```powershell
git push origin main
```

Se o auto-review bloquear, repetir o mesmo comando pedindo aprovação.

- [ ] **Step 5: Sem pub** — não mexer em `pubspec.yaml` nem gerar build de loja; o dono decide quando sai.
