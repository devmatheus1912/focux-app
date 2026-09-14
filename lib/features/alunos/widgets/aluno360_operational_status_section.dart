import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
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
    this.aderenciaBundle,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final List<Map<String, dynamic>>? aderenciaSemanal;
  final AderenciaSemanalBundle? aderenciaBundle;

  void _openDestination(
    BuildContext context, {
    required OperacaoStatusCardDestination dest,
    required Aluno360OperacaoSnapshot? operacao,
  }) {
    if (dest == OperacaoStatusCardDestination.noop) return;

    HapticFeedback.selectionClick();
    switch (dest) {
      case OperacaoStatusCardDestination.chat:
        _openChat(context, operacao: operacao);
      case OperacaoStatusCardDestination.engajamento:
        context.push('/alunos/$alunoId/engajamento', extra: aluno.nome);
      case OperacaoStatusCardDestination.treinos:
        context.push('/alunos/$alunoId/treinos-list', extra: aluno.nome);
      case OperacaoStatusCardDestination.noop:
        return;
    }
  }

  void _openChat(
    BuildContext context, {
    required Aluno360OperacaoSnapshot? operacao,
  }) {
    final draft =
        operacao?.effectiveProxima?.mensagemSugerida?.trim() ??
        operacao?.outreachMessage.trim() ??
        '';
    if (draft.isNotEmpty) {
      showAlunoOutreachMessageSheet(
        context,
        alunoId: alunoId,
        alunoNome: aluno.nome,
        message: draft,
        title: 'Mensagem sugerida',
        subtitle: 'Copiloto · revise antes de enviar.',
        icon: Icons.auto_awesome_rounded,
      );
      return;
    }
    context.push(
      '/alunos/$alunoId/chat',
      extra: alunoChatRouteExtra(nome: aluno.nome),
    );
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
      bundle: aderenciaBundle,
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
    final semTreinoLabel = formatSemTreinoOperacaoLabel(dias);
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
              bundle: aderenciaBundle,
            ).points;
    final weekValue = week.weekRatioLabel;

    final mute = fxScreenMute(context);
    final line = ShellChrome.of(context).line;

    Widget metric({
      required String label,
      required String value,
      required String hint,
      required Color color,
      required bool alert,
      required OperacaoStatusCardKind kind,
      IconData? icon,
    }) {
      final dest = resolveOperacaoStatusCardDestination(
        kind: kind,
        contactPriority: operacao?.contactPriority ?? false,
        proximaAcao: operacao?.effectiveProxima,
      );
      final tile = OperationalMetricTile(
        label: label,
        value: value,
        hint: hint,
        color: color,
        isDark: isDark,
        leadingIcon: icon,
        emphasis:
            alert
                ? OperationalMetricEmphasis.alert
                : OperationalMetricEmphasis.normal,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
        child:
            dest == OperacaoStatusCardDestination.noop
                ? tile
                : InkWell(
                  onTap:
                      () => _openDestination(
                        context,
                        dest: dest,
                        operacao: operacao,
                      ),
                  borderRadius: BorderRadius.circular(12),
                  child: tile,
                ),
      );
    }

    Widget tileForKind(OperacaoStatusCardKind kind) {
      return switch (kind) {
        OperacaoStatusCardKind.focoDoDia => metric(
          label: dominant.label,
          value: dominant.value,
          hint: dominant.hint,
          color: _dominantAccent(dominant, aderenciaColor, riscoColor, primary),
          alert: dominant.kind == OperacaoDominantMetricKind.risco,
          kind: kind,
          icon: riscoMetricIcon(dominant.riscoNivel ?? aluno.riscoNivel),
        ),
        OperacaoStatusCardKind.prontidao => metric(
          label:
              dominant.kind == OperacaoDominantMetricKind.prontidao
                  ? dominant.label
                  : 'Prontidão',
          value:
              dominant.kind == OperacaoDominantMetricKind.prontidao
                  ? dominant.value
                  : (aluno.scoreProntidao == null
                      ? '—'
                      : '${aluno.scoreProntidao}'),
          hint:
              dominant.kind == OperacaoDominantMetricKind.prontidao
                  ? dominant.hint
                  : 'Índice operacional',
          color: primary,
          alert: false,
          kind: kind,
          icon: Icons.speed_rounded,
        ),
        OperacaoStatusCardKind.aderencia => metric(
          label:
              dominant.kind == OperacaoDominantMetricKind.aderencia &&
                      !heroShowsRisco
                  ? dominant.label
                  : 'Aderência',
          value:
              dominant.kind == OperacaoDominantMetricKind.aderencia &&
                      !heroShowsRisco
                  ? dominant.value
                  : (aluno.aderenciaPercent == null
                      ? '—'
                      : '${aluno.aderenciaPercent}%'),
          hint:
              dominant.kind == OperacaoDominantMetricKind.aderencia &&
                      !heroShowsRisco
                  ? dominant.hint
                  : 'Concluídos / iniciados · 30 dias',
          color: aderenciaColor,
          alert: (aluno.aderenciaPercent ?? 0) <= 0,
          kind: kind,
          icon: Icons.percent_rounded,
        ),
        OperacaoStatusCardKind.ultimoTreino => metric(
          label: semTreinoLabel,
          value: semTreinoDisplay,
          hint: semTreinoSubtitle,
          color: semTreinoAccent,
          alert: (dias ?? 0) >= diasLimite,
          kind: kind,
          icon: Icons.pause_circle_outline_rounded,
        ),
        OperacaoStatusCardKind.risco => metric(
          label: 'Risco',
          value: formatRiscoNivel(aluno.riscoNivel),
          hint: aluno.emRisco ? 'Em risco' : 'Estável',
          color: riscoColor,
          alert: aluno.emRisco,
          kind: kind,
          icon: riscoMetricIcon(aluno.riscoNivel),
        ),
        OperacaoStatusCardKind.checkins7d => metric(
          label: 'Check-ins · 7 dias',
          value: weekValue,
          hint: adherenceEmpty?.message ?? week.caption,
          color: week.hasAnyCheckin ? aderenciaColor : EagleTokens.warn,
          alert: !week.hasAnyCheckin && week.points.isNotEmpty,
          kind: kind,
          icon: Icons.calendar_view_week_rounded,
        ),
      };
    }

    final metrics = resolveOperacaoStatusMetricKinds(
      heroShowsRisco: heroShowsRisco,
      dominantKind: dominant.kind,
    ).map(tileForKind).toList(growable: false);

    return Column(
      key: const ValueKey('aluno360_operacao_status'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: 'Status operacional',
          actionLabel: 'Ajuda',
          onAction: () => showAluno360StatusOperacionalHelpSheet(context),
        ),
        if (statusSubtitle != null && statusSubtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            statusSubtitle,
            style: Aluno360Layout.metaStyle(context).copyWith(color: mute),
          ),
        ],
        const SizedBox(height: TokensStrip.s3),
        ...metrics,
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
                color: mute,
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
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label: 'Pedir check-in',
              accent: primary,
              isDark: isDark,
              onPressed: () async {
                try {
                  await ref.read(alunoRepositoryProvider).cobrarTreino(alunoId);
                  if (!context.mounted) return;
                  FeedbackHelper.showSuccess(
                    context,
                    'Lembrete enviado',
                    placement: FeedbackPlacement.operacaoTop,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  FeedbackHelper.showError(context, friendlyError(e));
                }
              },
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
