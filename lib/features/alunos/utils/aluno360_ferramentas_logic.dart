import 'package:flutter/material.dart';

import '../../planos/data/planos_repository.dart';
import '../../planos/utils/plano_capability.dart';
import '../../subscription/plan_entitlements.dart';
import '../data/aluno_repository.dart';
import 'aluno360_operacao_logic.dart';

/// Módulos da aba Ferramentas sujeitos a gate de plano.
enum Aluno360FerramentasGatedModule { iaProgresso, feedbackVideo }

/// Catálogo de módulos da aba Ferramentas (todos aparecem, em grupos).
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

/// Textos e regras da aba Ferramentas do perfil 360.
abstract final class Aluno360FerramentasLogic {
  Aluno360FerramentasLogic._();

  static IconData moduleIcon(Aluno360FerramentasModule module) {
    return switch (module) {
      Aluno360FerramentasModule.treinos => Icons.fitness_center_outlined,
      Aluno360FerramentasModule.equipamentos => Icons.handyman_outlined,
      Aluno360FerramentasModule.iaProgresso => Icons.auto_awesome_outlined,
      Aluno360FerramentasModule.composicao => Icons.monitor_weight_outlined,
      Aluno360FerramentasModule.aderencia => Icons.event_available_outlined,
      Aluno360FerramentasModule.planoSucesso => Icons.flag_outlined,
      Aluno360FerramentasModule.trilhas => Icons.route_outlined,
      Aluno360FerramentasModule.engajamento =>
        Icons.local_fire_department_outlined,
      Aluno360FerramentasModule.anamnese => Icons.assignment_outlined,
      Aluno360FerramentasModule.mensalidades => Icons.payments_outlined,
      Aluno360FerramentasModule.chat => Icons.chat_bubble_outline_rounded,
      Aluno360FerramentasModule.feedbackVideo => Icons.videocam_outlined,
    };
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
      return '$n check-in${n == 1 ? '' : 's'} em 7 dias';
    }
    final dias = aluno.diasSemTreino;
    if (dias != null && dias >= 7) {
      return '$dias dias sem treino';
    }
    return 'Sem check-ins em 7 dias';
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
    return status == 'PREENCHIDA' ||
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

  static String? gatedModuleCapability(Aluno360FerramentasGatedModule module) {
    return switch (module) {
      Aluno360FerramentasGatedModule.iaProgresso => 'iaCopiloto',
      Aluno360FerramentasGatedModule.feedbackVideo => 'feedbackVideo',
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
      return 'Sem dados dos últimos 7 dias';
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
      return 'Últimos 7 dias: ${dayParts.join(', ')}';
    }
    final n = summary.totalCheckins;
    return 'Últimos 7 dias: $n check-in${n == 1 ? '' : 's'}';
  }
}
