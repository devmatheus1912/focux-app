import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../alunos/data/aluno_repository.dart';
import '../constants/dashboard_layout.dart';

String dashboardGreeting(String? nome, {bool compact = false}) {
  final hour = DateTime.now().hour;
  final prefix =
      hour < 12
          ? 'Bom dia'
          : hour < 18
          ? 'Boa tarde'
          : 'Boa noite';
  final first = nome?.split(' ').first.trim();
  if (first == null || first.isEmpty) return prefix;
  final display = fxTitleCaseName(first);
  if (compact && display.length > 10) {
    return '$prefix, ${display.substring(0, 9)}…';
  }
  return '$prefix, $display';
}

bool isRiskEchoCopy(String text) {
  final lower = text.toLowerCase();
  return lower.contains('risco') ||
      lower.contains('abandono') ||
      lower.contains('aderência') ||
      lower.contains('aderencia');
}

String attentionSignalLabel(Aluno aluno) {
  if (aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE') {
    return 'Inadimplente';
  }
  final dias = aluno.diasSemTreino;
  if (dias != null && dias >= 7) return '${dias}d s/ treino';
  if (aluno.emRisco) return 'Prioridade hoje';
  return 'Acompanhar';
}

String attentionSignalSub(Aluno aluno) {
  if (aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE') {
    return 'Financeiro e aderência exigem contato';
  }
  final dias = aluno.diasSemTreino;
  if (dias != null && dias >= 14) {
    return 'Retomada urgente antes de perder ritmo';
  }
  if (dias != null && dias >= 7) {
    return 'Contato rápido para voltar ao treino';
  }
  return 'Acompanhar antes de perder ritmo';
}

TextStyle dashboardSectionKickerStyle(
  BuildContext context, {
  required bool isDark,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  return Theme.of(context).textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: BrandPalette.sectionLink(primary, dark: isDark),
  );
}

String financeInadimplLabel(double width) =>
    DashboardLayout.isCompact(width) || width < 360 ? 'Inadimpl.' : 'Inadimplentes';

String financePercentLabel(double progressRaw, {required bool exceeded}) {
  if (exceeded) {
    final extra = ((progressRaw - 1) * 100).round();
    if (extra > 0) {
      return 'Meta batida · +$extra% acima do previsto';
    }
    return 'Meta batida';
  }
  final pct = (progressRaw * 100).round().clamp(0, 100);
  return '$pct% da meta';
}

Color pulseCheckinsAccent({
  required int checkinsHoje,
  required Color neutralAccent,
  Color? emptyAccent,
}) =>
    checkinsHoje > 0
        ? EagleTokens.good
        : (emptyAccent ?? neutralAccent);
