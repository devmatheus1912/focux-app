import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../data/aluno_contact_utils.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../utils/alertas_config_from_home.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../widgets/aluno_operacao_adherence_bars.dart';
import '../widgets/aluno_operacao_adherence_legend.dart';
import '../widgets/aluno_outreach_message_sheet.dart';
import 'aluno360_help_sheets.dart';

class Aluno360OperationalStatusSection extends ConsumerWidget {
  const Aluno360OperationalStatusSection({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.aderenciaSemanal,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final List<Map<String, dynamic>>? aderenciaSemanal;

  void _openTreinos(BuildContext context) {
    context.push('/alunos/$alunoId/treinos-list', extra: aluno.nome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeInitialized = ref.exists(alunosHomeProvider);
    final cachedDias =
        homeInitialized
            ? ref
                .watch(alunosHomeProvider)
                .valueOrNull
                ?.alertasConfig
                .diasSemTreino
            : null;
    final diasLimite = resolveDiasSemTreinoLimiteFromHome(
      alunosHomeInitialized: homeInitialized,
      cachedDiasSemTreino: cachedDias,
    );
    final week = summarizeAderenciaWeek(
      parseAderenciaSemanal(aderenciaSemanal),
    );
    final operacao = ref.watch(aluno360OperacaoProvider(alunoId));
    final heroShowsRisco = operacaoHeroShowsRisco(aluno);
    final dominant = resolveOperacaoDominantMetric(aluno);
    final aderenciaColor = EagleTokens.aderenciaColor(
      (aluno.aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );
    final riscoColor =
        aluno.emRisco
            ? (isDark ? EagleTokens.warnAccent : EagleTokens.warn)
            : EagleTokens.semanticGood(isDark: isDark);
    final neutralIdle =
        isDark
            ? EagleTokens.lineNeutralDark.withValues(alpha: 0.35)
            : EagleTokens.lineNeutral;
    final showCheckinCta = shouldShowOperacaoCheckinCta(
      operacao: operacao,
      weekHasAnyCheckin: week.hasAnyCheckin,
    );
    final adherenceEmpty = resolveOperacaoAdherenceEmptyState(
      week: week,
      operacao: operacao,
    );
    final compactFollowUpVisible = shouldCompactFollowUpForContactPriority(
      contactPriority: operacao?.contactPriority ?? false,
    );
    final statusSubtitle = operacaoStatusSubtitle(
      aluno,
      heroShowsRisco: heroShowsRisco,
      compactFollowUpVisible: compactFollowUpVisible,
    );
    final dias = aluno.diasSemTreino;
    final semTreinoDisplay = formatDiasSemTreinoDisplay(dias);
    final semTreinoSubtitle = semTreinoOperacaoSubtitle(dias);
    final semTreinoAccent =
        (dias ?? 0) >= diasLimite ? EagleTokens.warn : fxScreenMute(context);
    final showLegend = shouldShowOperacaoAdherenceLegend(
      weekHasAnyCheckin: week.hasAnyCheckin,
    );
    final weekPoints =
        week.points.isNotEmpty
            ? week.points
            : summarizeAderenciaWeek(
              padAderenciaWeekToSevenDays(const []),
            ).points;
    final daysWithCheckin = week.points.where((p) => p.checkins > 0).length;
    final weekValue =
        week.points.isEmpty
            ? '—'
            : '$daysWithCheckin/${week.points.length}';

    final tiles = <Widget>[];

    if (!heroShowsRisco) {
      tiles.add(
        FxSettingsTile(
          icon: riscoMetricIcon(dominant.riscoNivel ?? aluno.riscoNivel),
          accent: _dominantAccent(dominant, aderenciaColor, riscoColor, primary),
          label: dominant.label,
          subtitle: dominant.hint,
          value: dominant.value,
          highlight: dominant.kind == OperacaoDominantMetricKind.risco,
          onTap: () => _openTreinos(context),
        ),
      );
    }

    if (heroShowsRisco) {
      tiles.add(
        FxSettingsTile(
          icon: Icons.percent_rounded,
          accent: aderenciaColor,
          label: 'Aderência',
          subtitle: 'Treinos concluídos na semana',
          value: aluno.aderenciaPercent == null ? '—' : '${aluno.aderenciaPercent}%',
          numeric: aluno.aderenciaPercent != null,
          highlight: (aluno.aderenciaPercent ?? 0) <= 0,
          onTap: () => _openTreinos(context),
        ),
      );
      tiles.add(
        FxSettingsTile(
          icon: Icons.pause_circle_outline_rounded,
          accent: semTreinoAccent,
          label: 'Sem treino',
          subtitle: semTreinoSubtitle,
          value: semTreinoDisplay,
          highlight: (dias ?? 0) >= diasLimite,
          onTap: () => _openTreinos(context),
        ),
      );
    } else {
      tiles.addAll([
        FxSettingsTile(
          icon: Icons.speed_rounded,
          accent: primary,
          label: 'Prontidão',
          subtitle: 'Índice operacional',
          value: aluno.scoreProntidao == null ? '—' : '${aluno.scoreProntidao}',
          numeric: aluno.scoreProntidao != null,
          onTap: () => _openTreinos(context),
        ),
        FxSettingsTile(
          icon: Icons.percent_rounded,
          accent: aderenciaColor,
          label: 'Aderência',
          subtitle: 'Treinos concluídos na semana',
          value: aluno.aderenciaPercent == null ? '—' : '${aluno.aderenciaPercent}%',
          numeric: aluno.aderenciaPercent != null,
          highlight: (aluno.aderenciaPercent ?? 0) <= 0,
          onTap: () => _openTreinos(context),
        ),
        FxSettingsTile(
          icon: Icons.pause_circle_outline_rounded,
          accent: semTreinoAccent,
          label: 'Sem treino',
          subtitle: semTreinoSubtitle,
          value: semTreinoDisplay,
          highlight: (dias ?? 0) >= diasLimite,
          onTap: () => _openTreinos(context),
        ),
        FxSettingsTile(
          icon: riscoMetricIcon(aluno.riscoNivel),
          accent: riscoColor,
          label: 'Risco',
          subtitle: aluno.emRisco ? 'Em risco' : 'Estável',
          value: formatRiscoNivel(aluno.riscoNivel),
          highlight: aluno.emRisco,
          onTap: () => _openTreinos(context),
        ),
      ]);
    }

    tiles.add(
      FxSettingsTile(
        icon: Icons.calendar_view_week_rounded,
        accent: week.hasAnyCheckin ? aderenciaColor : EagleTokens.warn,
        label: 'Check-ins · 7 dias',
        subtitle: adherenceEmpty?.message ?? week.caption,
        value: weekValue,
        numeric: week.points.isNotEmpty,
        highlight: !week.hasAnyCheckin && week.points.isNotEmpty,
        showDivider: false,
        onTap: () => _openTreinos(context),
      ),
    );

    final firstName = aluno.nome.split(' ').first;
    final line = ShellChrome.of(context).line;

    return FxSettingsGroup(
      key: const ValueKey('aluno360_operacao_status'),
      header: 'Status operacional',
      caption: statusSubtitle,
      helpTooltip: 'Ajuda sobre status operacional',
      onHelpTap: () => showAluno360StatusOperacionalHelpSheet(context),
      accent: primary,
      children: [
        ...tiles,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: line.withValues(alpha: 0.45),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Calendário da semana',
              style: Aluno360Layout.metaStyle(context).copyWith(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Semantics(
            label: 'Check-ins dos últimos 7 dias',
            child: AlunoOperacaoAdherenceBars(
              points: weekPoints,
              activeColor: EagleTokens.good,
              idleColor: neutralIdle,
              missColor: isDark ? EagleTokens.warn : EagleTokens.riskCoral,
              todayRingColor: primary,
              emptyWeek: !week.hasAnyCheckin,
            ),
          ),
        ),
        if (showLegend)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AlunoOperacaoAdherenceLegend(
              activeColor: EagleTokens.good,
              missColor: isDark ? EagleTokens.warn : EagleTokens.riskCoral,
              todayRingColor: primary,
            ),
          ),
        if (showCheckinCta && (adherenceEmpty?.showCheckinCta ?? true))
          FxSettingsTile(
            icon: Icons.message_outlined,
            accent: primary,
            label: 'Pedir check-in',
            subtitle: 'Mensagem pronta para $firstName',
            value: '',
            showDivider: false,
            onTap:
                () => showAlunoCheckinMessageSheet(
                  context,
                  alunoId: alunoId,
                  alunoNome: aluno.nome,
                ),
          ),
      ],
    );
  }

  Color _dominantAccent(
    OperacaoDominantMetric metric,
    Color aderenciaColor,
    Color riscoColor,
    Color primary,
  ) {
    return switch (metric.kind) {
      OperacaoDominantMetricKind.risco => riscoColor,
      OperacaoDominantMetricKind.aderencia => aderenciaColor,
      OperacaoDominantMetricKind.prontidao => primary,
    };
  }
}
