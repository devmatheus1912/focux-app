import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/utils/plano_capability.dart';
import '../../subscription/plan_entitlements.dart';
import '../data/aluno_repository.dart';
import 'aluno360_operacao_logic.dart';

/// Módulos da aba Ferramentas sujeitos a gate de plano.
enum Aluno360FerramentasGatedModule { iaProgresso, feedbackVideo }

/// Catálogo de módulos Ferramentas (S3) — fold priorizado vs. overflow (A30).
enum Aluno360FerramentasModule {
  treinos,
  equipamentos,
  iaProgresso,
  composicao,
  aderencia,
  planoSucesso,
  trilhas,
  engajamento,
  anamnese,
  mensalidades,
  chat,
  feedbackVideo,
}

/// Grupo visual do módulo no catálogo completo.
enum Aluno360FerramentasModuleGroup { treino, perfil }

/// Campo de medida corporal na aba Ferramentas.
enum Aluno360MeasurementField { idade, altura, gordura, massaMagra }

/// Linha de medida para tiles inset.
class Aluno360MeasurementRow {
  const Aluno360MeasurementRow({
    required this.field,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.complete,
    required this.highlight,
  });

  final Aluno360MeasurementField field;
  final String label;
  final String subtitle;
  final String value;
  final bool complete;
  final bool highlight;
}

/// Layout + copy helpers for the Ferramentas tab (Aluno 360).
abstract final class Aluno360FerramentasLogic {
  Aluno360FerramentasLogic._();

  static const double sectionHeaderGap = TokensStrip.s2;
  static const double sectionDividerGap = FxSettingsLayout.groupGap;

  static const String medidasCaption =
      'Idade, altura e composição para acompanhar evolução.';
  static const String treinoCaption =
      'O que precisa de atenção agora — o resto em Mais.';
  static const String perfilCaption =
      'Cadastro, financeiro e comunicação.';

  /// Máximo de módulos no first paint (sem contar "Mais ferramentas").
  static const int foldModuleLimit = 3;

  /// Duplicados do fold (já cobertos em Operação/Evolução/sticky) — só em Mais.
  static const Set<Aluno360FerramentasModule> foldOverflowOnly = {
    Aluno360FerramentasModule.treinos,
    Aluno360FerramentasModule.chat,
    Aluno360FerramentasModule.iaProgresso,
    Aluno360FerramentasModule.aderencia,
    Aluno360FerramentasModule.mensalidades,
  };

  static Aluno360FerramentasModuleGroup moduleGroup(
    Aluno360FerramentasModule module,
  ) {
    return switch (module) {
      Aluno360FerramentasModule.treinos ||
      Aluno360FerramentasModule.equipamentos ||
      Aluno360FerramentasModule.iaProgresso ||
      Aluno360FerramentasModule.composicao ||
      Aluno360FerramentasModule.aderencia ||
      Aluno360FerramentasModule.planoSucesso ||
      Aluno360FerramentasModule.trilhas ||
      Aluno360FerramentasModule.engajamento =>
        Aluno360FerramentasModuleGroup.treino,
      Aluno360FerramentasModule.anamnese ||
      Aluno360FerramentasModule.mensalidades ||
      Aluno360FerramentasModule.chat ||
      Aluno360FerramentasModule.feedbackVideo =>
        Aluno360FerramentasModuleGroup.perfil,
    };
  }

  static int modulePriority(
    Aluno360FerramentasModule module, {
    required Aluno aluno,
    String? bf,
    String? massaMagra,
    String? anamneseStatus,
    List<Map<String, dynamic>>? aderenciaSemanal,
  }) {
    final financeHot =
        aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente;
    final composicaoHot = composicaoCorporalPending(bf: bf, massaMagra: massaMagra);
    final anamneseHot = anamneseNeedsAttention(anamneseStatus);
    final aderenciaHot = aderenciaNeedsAttention(
      aluno: aluno,
      aderenciaSemanal: aderenciaSemanal,
    );

    return switch (module) {
      // Duplicados da home/operação → overflow (prioridade baixa).
      Aluno360FerramentasModule.treinos => 5,
      Aluno360FerramentasModule.chat => 4,
      Aluno360FerramentasModule.iaProgresso => 3,
      Aluno360FerramentasModule.mensalidades => financeHot ? 220 : 2,
      Aluno360FerramentasModule.aderencia => aderenciaHot ? 180 : 1,
      Aluno360FerramentasModule.anamnese => anamneseHot ? 200 : 55,
      Aluno360FerramentasModule.composicao => composicaoHot ? 190 : 50,
      Aluno360FerramentasModule.equipamentos => 60,
      Aluno360FerramentasModule.planoSucesso => 35,
      Aluno360FerramentasModule.trilhas => 30,
      Aluno360FerramentasModule.engajamento => 25,
      Aluno360FerramentasModule.feedbackVideo => 20,
    };
  }

  /// Split A30: top-N no fold; resto atrás de um toque.
  static ({
    List<Aluno360FerramentasModule> fold,
    List<Aluno360FerramentasModule> overflow,
  }) splitModulesForFold({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
    String? anamneseStatus,
    List<Map<String, dynamic>>? aderenciaSemanal,
    int limit = foldModuleLimit,
  }) {
    final ranked = Aluno360FerramentasModule.values.toList(growable: false)
      ..sort((a, b) {
        final pa = modulePriority(
          a,
          aluno: aluno,
          bf: bf,
          massaMagra: massaMagra,
          anamneseStatus: anamneseStatus,
          aderenciaSemanal: aderenciaSemanal,
        );
        final pb = modulePriority(
          b,
          aluno: aluno,
          bf: bf,
          massaMagra: massaMagra,
          anamneseStatus: anamneseStatus,
          aderenciaSemanal: aderenciaSemanal,
        );
        if (pa != pb) return pb.compareTo(pa);
        return a.index.compareTo(b.index);
      });
    final foldCandidates =
        ranked.where((m) => !foldOverflowOnly.contains(m)).toList();
    final forcedOverflow =
        ranked.where(foldOverflowOnly.contains).toList(growable: false);
    final fold = foldCandidates.take(limit).toList(growable: false);
    final overflow = [
      ...foldCandidates.skip(limit),
      ...forcedOverflow,
    ];
    return (fold: fold, overflow: overflow);
  }

  static List<double> aderenciaSparklineValues(
    List<Map<String, dynamic>>? raw,
  ) {
    final points = parseAderenciaSemanal(raw);
    if (points.isEmpty) return const [];
    return points.map((p) => p.checkins).toList(growable: false);
  }

  static String aderenciaModuleSub({
    required Aluno aluno,
    List<Map<String, dynamic>>? aderenciaSemanal,
  }) {
    final summary = summarizeAderenciaWeek(
      parseAderenciaSemanal(aderenciaSemanal),
    );
    if (summary.hasAnyCheckin) {
      final n = summary.totalCheckins;
      return '$n check-in${n == 1 ? '' : 's'} na semana';
    }
    final dias = aluno.diasSemTreino;
    if (dias != null && dias >= 7) {
      return '$dias dias sem treino';
    }
    return 'Sem check-ins nesta semana';
  }

  static int measurementsPendingCount({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
  }) {
    var pending = 0;
    if (aluno.idade == null) pending++;
    if (aluno.altura == null) pending++;
    if (bf == null) pending++;
    if (massaMagra == null) pending++;
    return pending;
  }

  static String measurementsSummary({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
  }) {
    final pending = measurementsPendingCount(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
    );
    if (pending == 0) return 'Perfil e composição completos';
    if (pending == 4) return 'Nenhuma medida registrada ainda';
    return '$pending de 4 campos pendentes';
  }

  static String pendingFieldValue({required bool complete}) {
    return complete ? 'OK' : 'Pendente';
  }

  static List<Aluno360MeasurementRow> measurementRows({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
  }) {
    final idadeOk = aluno.idade != null;
    final alturaOk = aluno.altura != null;
    final gorduraOk = bf != null;
    final massaOk = massaMagra != null;

    return [
      Aluno360MeasurementRow(
        field: Aluno360MeasurementField.idade,
        label: 'Idade',
        subtitle:
            idadeOk ? '${aluno.idade} anos' : 'Informar data de nascimento',
        value: pendingFieldValue(complete: idadeOk),
        complete: idadeOk,
        highlight: !idadeOk,
      ),
      Aluno360MeasurementRow(
        field: Aluno360MeasurementField.altura,
        label: 'Altura',
        subtitle:
            alturaOk
                ? '${(aluno.altura! * 100).round()} cm'
                : 'Cadastrar no perfil',
        value: pendingFieldValue(complete: alturaOk),
        complete: alturaOk,
        highlight: !alturaOk,
      ),
      Aluno360MeasurementRow(
        field: Aluno360MeasurementField.gordura,
        label: 'Gordura corporal',
        subtitle: gorduraOk ? '$bf%' : 'Registrar na evolução',
        value: pendingFieldValue(complete: gorduraOk),
        complete: gorduraOk,
        highlight: !gorduraOk,
      ),
      Aluno360MeasurementRow(
        field: Aluno360MeasurementField.massaMagra,
        label: 'Massa magra',
        subtitle: massaOk ? '$massaMagra kg' : 'Registrar na evolução',
        value: pendingFieldValue(complete: massaOk),
        complete: massaOk,
        highlight: !massaOk,
      ),
    ];
  }

  static String composicaoCorporalValue({
    String? bf,
    String? massaMagra,
  }) {
    final bfOk = bf != null && bf.trim().isNotEmpty;
    final mmOk = massaMagra != null && massaMagra.trim().isNotEmpty;
    if (bfOk && mmOk) return 'OK';
    if (bfOk || mmOk) return 'Parcial';
    return 'Pendente';
  }

  /// Pendente só sem gordura e sem massa; um preenchido = parcial (não hot).
  static bool composicaoCorporalPending({
    String? bf,
    String? massaMagra,
  }) {
    final bfOk = bf != null && bf.trim().isNotEmpty;
    final mmOk = massaMagra != null && massaMagra.trim().isNotEmpty;
    return !bfOk && !mmOk;
  }

  static String anamneseValue(String? status) {
    switch (status) {
      case 'SOLICITADA':
        return 'Pendente';
      case 'PREENCHIDA':
        return 'Revisar';
      case 'REVISADA':
        return 'OK';
      case 'PRECISA_ATESTADO':
        return 'Atestado';
      case 'NAO_INICIADA':
      default:
        return 'Solicitar';
    }
  }

  static String anamneseSubtitle(String? status) {
    switch (status) {
      case 'SOLICITADA':
        return 'Aguardando o aluno preencher';
      case 'PREENCHIDA':
        return 'Pronta para revisão';
      case 'REVISADA':
        return 'Ficha revisada';
      case 'PRECISA_ATESTADO':
        return 'Aguardando atestado';
      case 'NAO_INICIADA':
      default:
        return 'Aluno preenche · você revisa';
    }
  }

  static bool anamneseNeedsAttention(String? status) {
    return status == 'SOLICITADA' ||
        status == 'PREENCHIDA' ||
        status == 'PRECISA_ATESTADO' ||
        status == null ||
        status == 'NAO_INICIADA';
  }

  static bool aderenciaNeedsAttention({
    required Aluno aluno,
    List<Map<String, dynamic>>? aderenciaSemanal,
  }) {
    final percent = aluno.aderenciaPercent ?? 0;
    if (percent > 0) return false;
    final summary = summarizeAderenciaWeek(
      parseAderenciaSemanal(aderenciaSemanal),
    );
    return !summary.hasAnyCheckin;
  }

  static bool measurementsAllComplete({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
  }) {
    return measurementsPendingCount(
          aluno: aluno,
          bf: bf,
          massaMagra: massaMagra,
        ) ==
        0;
  }

  static String measurementsCompleteSummary({
    required Aluno aluno,
    String? bf,
    String? massaMagra,
  }) {
    if (bf != null && massaMagra != null) {
      return 'Gordura $bf% · Massa magra $massaMagra kg';
    }
    final parts = <String>[];
    if (aluno.idade != null) parts.add('${aluno.idade} anos');
    if (aluno.altura != null) {
      parts.add('${(aluno.altura! * 100).round()} cm');
    }
    if (parts.isEmpty) return 'Perfil e composição completos';
    return parts.join(' · ');
  }

  static String? gatedModuleCapability(Aluno360FerramentasGatedModule module) {
    return switch (module) {
      Aluno360FerramentasGatedModule.iaProgresso => 'iaCopiloto',
      Aluno360FerramentasGatedModule.feedbackVideo => 'poseCoach',
    };
  }

  static bool isGatedModuleLocked({
    required PlanoFeatures features,
    required Aluno360FerramentasGatedModule module,
  }) {
    final capability = gatedModuleCapability(module);
    if (capability == null) return false;
    return !PlanoCapability.has(features, capability);
  }

  static String gatedModulePlanLabel(Aluno360FerramentasGatedModule module) {
    final capability = gatedModuleCapability(module);
    final plan = PlanEntitlements.targetPlan(capability: capability);
    return PlanEntitlements.displayPlanName(plan);
  }

  static String aderenciaSparkSemanticsLabel(
    List<Map<String, dynamic>>? aderenciaSemanal,
  ) {
    final points = parseAderenciaSemanal(aderenciaSemanal);
    final summary = summarizeAderenciaWeek(points);
    if (points.isEmpty) {
      return 'Sem dados de aderência nesta semana';
    }
    if (!summary.hasAnyCheckin) {
      return 'Sem check-ins nos últimos 7 dias';
    }
    final dayParts = <String>[];
    for (final point in points) {
      final day = weekdayNameFromIso(point.date);
      if (day.isEmpty) continue;
      final status =
          point.checkins > 0
              ? '${point.checkins.round()} check-in${point.checkins == 1 ? '' : 's'}'
              : 'sem registro';
      dayParts.add('$day $status');
    }
    if (dayParts.isNotEmpty) {
      return 'Aderência semanal: ${dayParts.join(', ')}';
    }
    final n = summary.totalCheckins;
    return 'Tendência semanal: $n check-in${n == 1 ? '' : 's'} nos últimos dias';
  }
}
