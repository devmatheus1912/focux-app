import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_followup_store.dart';
import '../data/aluno_repository.dart';

/// `aderenciaPercent` do servidor cobre os últimos 30 dias.
const alunoHeroAderenciaLabel = 'Aderência 30 dias';

/// Score do servidor (treinos em 30 dias + pagamentos). Não é a prontidão
/// física do wearable — esse nome fica reservado para o aluno.
const alunoSituacaoLabel = 'Situação do aluno';
const alunoSituacaoHint = 'Treinos e pagamentos';

/// Modelo de alertas (`emRisco`/`riscoNivel`): dias sem treino, aderência
/// abaixo do mínimo e mensalidade em atraso. "Risco de churn" é só da retenção.
const riscoOperacionalLabel = 'Risco operacional';

class AlunoHeroPrimarySignal {
  const AlunoHeroPrimarySignal({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;
}

class AlunoHeroStatusVisual {
  const AlunoHeroStatusVisual({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

/// Hide status badge when the dominant metric already communicates risk.
bool alunoHeroShouldShowStatusBadge({
  required AlunoHeroPrimarySignal signal,
  required AlunoHeroStatusVisual status,
}) {
  if (signal.label == riscoOperacionalLabel && status.label == 'Em risco') {
    return false;
  }
  return true;
}

AlunoHeroStatusVisual alunoHeroStatusVisual(
  Aluno aluno, {
  bool isDark = true,
}) {
  if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
    return AlunoHeroStatusVisual(
      label: 'Inadimplente',
      background:
          isDark ? Colors.white.withValues(alpha: 0.14) : EagleTokens.badSoft,
      foreground: isDark ? EagleTokens.riskCoralLight : EagleTokens.bad,
    );
  }
  if (aluno.status == 'INATIVO') {
    return AlunoHeroStatusVisual(
      label: 'Inativo',
      background:
          isDark ? Colors.white.withValues(alpha: 0.14) : EagleTokens.warnSoft,
      foreground: isDark ? EagleTokens.warmPeach : EagleTokens.warn,
    );
  }
  if (aluno.emRisco) {
    return AlunoHeroStatusVisual(
      label: 'Em risco',
      background: EagleTokens.dangerBrown,
      foreground: Colors.white,
    );
  }
  // Claro: verde escuro sobre verde claro (nunca claro sobre claro).
  return AlunoHeroStatusVisual(
    label: 'Ativo',
    background:
        isDark ? Colors.white.withValues(alpha: 0.14) : EagleTokens.goodSoft,
    foreground: isDark ? EagleTokens.goodAccent : EagleTokens.good,
  );
}

AlunoHeroPrimarySignal alunoHeroPrimarySignal(Aluno aluno) {
  final dias = aluno.diasSemTreino;
  final ader = aluno.aderenciaPercent;
  final diasCritico =
      dias != null && dias >= AlunoFollowUpStore.diasSemTreinoLimite;
  final priorizarDias =
      aluno.emRisco ||
      aluno.inadimplente ||
      aluno.statusFinanceiro == 'INADIMPLENTE' ||
      diasCritico ||
      (dias != null && dias >= 3);

  if (aluno.emRisco &&
      (dias == null || dias == 0) &&
      (ader == null || ader == 0)) {
    return AlunoHeroPrimarySignal(
      label: riscoOperacionalLabel,
      value: formatRiscoNivel(aluno.riscoNivel),
    );
  }

  if (priorizarDias && dias != null) {
    return AlunoHeroPrimarySignal(
      label: 'Sem treino',
      value: '$dias',
      suffix: dias == 1 ? ' dia' : ' dias',
    );
  }
  if (ader != null) {
    return AlunoHeroPrimarySignal(
      label: alunoHeroAderenciaLabel,
      value: '$ader',
      suffix: '%',
    );
  }
  if (dias != null) {
    return AlunoHeroPrimarySignal(
      label: 'Sem treino',
      value: '$dias',
      suffix: dias == 1 ? ' dia' : ' dias',
    );
  }
  return AlunoHeroPrimarySignal(
    label: alunoSituacaoLabel,
    value: aluno.scoreProntidao == null ? '—' : '${aluno.scoreProntidao}',
  );
}

String alunoHeroCaption(Aluno aluno, AlunoHeroPrimarySignal signal) {
  if (signal.label == 'Sem treino') {
    final dias = aluno.diasSemTreino ?? 0;
    if (dias >= AlunoFollowUpStore.diasSemTreinoLimite) {
      return 'Parado há $dias dias — contato hoje';
    }
    if (dias >= 3) {
      return '$dias dias parado — vale check-in';
    }
    return 'Rotina em dia';
  }
  if (signal.label == alunoHeroAderenciaLabel) {
    final ader = aluno.aderenciaPercent ?? 0;
    if (ader < 50) return 'Aderência baixa em 30 dias — reforce o hábito';
    if (ader < 70) return 'Aderência moderada em 30 dias';
    return 'Aderência saudável em 30 dias';
  }
  if (signal.label == riscoOperacionalLabel) {
    return aluno.emRisco ? 'Priorize contato hoje' : 'Monitorar sinais';
  }
  return alunoSituacaoHint;
}

/// Hero caption without repeating the dominant metric label.
String alunoHeroContextLine(AlunoHeroPrimarySignal signal, String caption) {
  // Caption already carries the signal (aderência / risco) — avoid
  // "Aderência 30 dias · Aderência baixa — …" wrap in the identity strip.
  if (signal.label == riscoOperacionalLabel ||
      signal.label == alunoHeroAderenciaLabel) {
    return caption;
  }
  return '${signal.label} · $caption';
}

/// Identity strip subtitle — in contact-priority mode, omit contact captions
/// already surfaced by Prioridade do dia + sticky CTA.
String alunoHeroIdentitySubtitle({
  required bool compactContactPriority,
  required bool objectiveDefined,
  required String objective,
  required String contextLine,
}) {
  if (compactContactPriority) return objective;
  return objectiveDefined ? '$objective · $contextLine' : contextLine;
}
