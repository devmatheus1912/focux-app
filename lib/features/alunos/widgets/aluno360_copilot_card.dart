import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/data/command_action_item.dart';
import '../../dashboard/widgets/command_action_tile.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../../planos/utils/plano_capability.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../utils/aluno360_copilot_task_actions.dart';
import '../widgets/aluno360_copilot_profile_gaps_sheet.dart';
import '../widgets/aluno360_copilot_executar_button.dart';
import '../widgets/aluno360_copilot_ia_refresh_button.dart';
import '../widgets/aluno360_copilot_prescription.dart';
import '../widgets/aluno360_copilot_support.dart';
import 'aluno360_help_sheets.dart';
import 'aluno360_operacao_focus_toggle.dart';
import 'aluno360_copilot_locked_section.dart';
import 'aluno360_copilot_ia_prompt_section.dart';
import '../widgets/aluno_outreach_message_sheet.dart';

class Aluno360CopilotCard extends ConsumerWidget {
  final Aluno aluno;
  final int alunoId;
  final AsyncValue<AlunoAutonomiaResumo> resumoAsync;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final bool isDark;
  final bool showFocusToggle;
  final bool focusMode;

  const Aluno360CopilotCard({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.resumoAsync,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.isDark,
    this.showFocusToggle = false,
    this.focusMode = false,
  });

  Future<void> _openProfileGap(
    BuildContext context,
    Aluno aluno,
    CopilotProfileGap gap,
  ) async {
    if (gap.route == 'measures') {
      await context.push('/alunos/${aluno.id}/evolucao', extra: aluno.nome);
      return;
    }
    if (gap.route == 'equipment') {
      await context.push('/alunos/${aluno.id}/equipamentos');
      return;
    }
    await context.push('/alunos/${aluno.id}/editar', extra: aluno);
  }

  Future<void> _completeProfile(BuildContext context, Aluno aluno) async {
    final gaps = copilotProfileGapsForCard(aluno);
    if (gaps.isEmpty) return;
    if (gaps.length == 1) {
      await _openProfileGap(context, aluno, gaps.first);
      return;
    }
    await showAluno360CopilotProfileGapsSheet(
      context,
      aluno: aluno,
      gaps: gaps,
      onSelectGap: (gap) => _openProfileGap(context, aluno, gap),
    );
  }

  void _prepararMensagem(
    BuildContext context,
    String acao, {
    String? backendMessage,
    String? outreachMessage,
  }) {
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.aluno360OutreachPrepared,
        props: {'aluno_id': aluno.id},
      ),
    );
    showAlunoOutreachMessageSheet(
      context,
      alunoId: aluno.id,
      alunoNome: aluno.nome,
      message:
          outreachMessage ??
          resolveOutreachMessage(
            aluno,
            acao: acao,
            backendMessage: backendMessage,
          ),
      title: 'Mensagem sugerida',
      subtitle: 'Copiloto · revise antes de enviar.',
      icon: Icons.auto_awesome_rounded,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final features = effectivePlanoFeatures(ref);
    if (!PlanoCapability.has(features, 'iaCopiloto')) {
      return Aluno360CopilotLockedSection(primary: primary);
    }

    final forceIa = ref.watch(alunoCopilotoForceIaProvider(aluno.id));
    final iaAsync =
        forceIa ? ref.watch(alunoCopilotoActionProvider(aluno.id)) : null;
    final bundleAsync = ref.watch(aluno360OperacaoBundleProvider(aluno.id));
    final bundle = bundleAsync.valueOrNull;
    // Prefer /360 bundle for open tasks — avoid sidecar GET on first paint.
    final AsyncValue<List<FilaAcaoResumo>> openActionsAsync;
    if (bundle?.openCopilotTasks != null) {
      openActionsAsync = AsyncData(bundle!.openCopilotTasks!);
    } else if (bundle?.hasOpenCopilotTask != null) {
      openActionsAsync = const AsyncData([]);
    } else if (bundle != null) {
      // Legacy payload without open-task fields — only then sidecar.
      openActionsAsync = ref.watch(alunoOpenIaActionsProvider(aluno.id));
    } else {
      openActionsAsync = const AsyncLoading();
    }
    final openActions = openActionsAsync.valueOrNull ?? const <FilaAcaoResumo>[];
    final openTask = findOpenCopilotTask(openActions);
    final hasOpenTask = openTask != null || hasOpenCopilotTask360;
    final bundleLoading = bundleAsync.isLoading && !bundleAsync.hasValue;
    final bundleRefreshing = bundleAsync.isRefreshing && bundleAsync.hasValue;
    final operacao = ref.watch(aluno360OperacaoProvider(aluno.id));
    if (operacao == null) {
      return const SizedBox.shrink();
    }
    final iaRefreshing = ref.watch(alunoCopilotIaRefreshingProvider(aluno.id));
    final iaLoading =
        iaRefreshing ||
        (forceIa && iaAsync != null && iaAsync.isLoading && !iaAsync.hasValue);
    final hasIaContent = aluno360CopilotHasIaGeneratedContent(
      proximaAcao360: proximaAcao360,
      forceIa: forceIa,
      iaHasValue: iaAsync?.hasValue ?? false,
      hasOpenTask: hasOpenTask,
    );
    if (!hasIaContent && !iaLoading) {
      return Aluno360CopilotIaPromptSection(
        alunoId: alunoId,
        primary: primary,
        contactPriority: operacao.contactPriority,
      );
    }

    final resumo = resumoAsync.valueOrNull;
    final profileCompletion = copilotProfileCompletion(aluno);
    final signals = resolveCopilotSignals(
      aluno: aluno,
      resumo: resumo,
      primary: primary,
    );
    final fallback = copilotFallbackAction(aluno, resumo);
    final seed360 =
        proximaAcao360 != null ? copilotActionFrom360(proximaAcao360!) : null;
    final stickyAction = operacao.stickyAction;
    final effectiveProxima = operacao.effectiveProxima;
    final hideCopilotChat = operacao.hideCopilotChatRow;
    final showCopilotPrescription = shouldShowCopilotPrescriptionBlock(
      forceIa: forceIa,
      sticky: stickyAction,
      aluno: aluno,
      proximaAcaoRaw: proximaAcao360?.acao,
      contactPriority: operacao.contactPriority,
    );
    final hideCopilotPrimary =
        operacao.hideCopilotTaskRow ||
        shouldHideCopilotPrimaryCtaWhenMatchesSticky(
          sticky: stickyAction,
          aluno: aluno,
          proximaAcaoRaw: proximaAcao360?.acao,
        );
    final resolvedAcao = resolveCopilotAcao(
      seed360: seed360,
      forceIa: forceIa,
      iaAsync: iaAsync,
      fallback: fallback,
    );
    final showPrepareInPrescription = operacao.showPrepareMessage;
    final wearableRelevant =
        effectiveProxima?.wearableRelevant ??
        bundle?.hasWearableHistory ??
        alunoTemHistoricoWearable(bundle?.recoverySnapshot);
    final compactSubtitle = MediaQuery.sizeOf(context).width < 400;
    final subtitle = copilotCardSubtitle(
      forceIa: forceIa,
      iaAsync: iaAsync,
      resumoLoading: resumoAsync.isLoading && !resumoAsync.hasValue,
      compact: compactSubtitle,
      iaRefreshing: iaRefreshing,
      bundleLoading: bundleLoading,
      bundleRefreshing: bundleRefreshing,
    );
    final showContactBadge = shouldShowCopilotContactBadge(
      contactPriority: operacao.contactPriority,
      sticky: stickyAction,
    );
    final caption =
        showContactBadge ? '$subtitle · Contato prioritário' : subtitle;

    return Semantics(
      container: true,
      label: 'Prioridade do dia, copiloto operacional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: copilotCardTitle(contactPriority: operacao.contactPriority),
            actionLabel: 'Ajuda',
            onAction: () => showAluno360CopilotHelpSheet(context),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              color: fxScreenMute(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          if (showFocusToggle)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Aluno360OperacaoFocusModeToggle(
                      alunoId: alunoId,
                      primary: primary,
                      iconOnly: true,
                    ),
                    Aluno360CopilotIaRefreshButton(
                      alunoId: aluno.id,
                      primary: primary,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Aluno360CopilotIaRefreshButton(
                  alunoId: aluno.id,
                  primary: primary,
                ),
              ),
            ),
          if (iaLoading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: iaRefreshing ? 4 : 3,
                backgroundColor: primary.withValues(alpha: 0.12),
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
          ],
            if (!hasOpenTask && !focusMode && !operacao.contactPriority) ...[
              const SizedBox(height: 10),
              Aluno360CopilotSignalsGrid(signals: signals),
            ],
            if (!hasOpenTask && !focusMode && !operacao.contactPriority)
              const SizedBox(height: 10),
            if (shouldShowCopilotProfileGapsButton(
              aluno,
              profileCompletion,
              sticky: stickyAction,
            )) ...[
              CommandActionTile(
                item: CommandActionItem(
                  icon: 'users',
                  title: copilotProfileGapsButtonLabel(aluno),
                  subtitle: 'Dados que ainda afetam a prescrição',
                  route: '/alunos/${aluno.id}/editar',
                  tone: CommandActionTone.primary,
                ),
                isDark: isDark,
                primary: primary,
                showDivider: false,
                onTap: () => _completeProfile(context, aluno),
              ),
              const SizedBox(height: 10),
            ],
            if (showCopilotPrescription) ...[
              Aluno360CopilotPrescriptionBody(
                aluno: aluno,
                primary: primary,
                fallback: fallback,
                seed360: seed360,
                forceIa: forceIa,
                iaAsync: iaAsync,
                iaRefreshing: iaRefreshing,
                resumoLoading: resumoAsync.isLoading && !resumoAsync.hasValue,
                bundleLoading: bundleLoading,
                bundleRefreshing: bundleRefreshing,
                preferContactPriority: operacao.contactPriority,
                wearableRelevant: wearableRelevant,
                contactPriority: operacao.contactPriority,
                statusMetricsVisible: !focusMode,
                hideMetricFooter: focusMode,
                onPrepareMessage:
                    showPrepareInPrescription
                        ? () => _prepararMensagem(
                          context,
                          resolvedAcao,
                          backendMessage: effectiveProxima?.mensagemSugerida,
                          outreachMessage: operacao.outreachMessage,
                        )
                        : null,
              ),
              const SizedBox(height: 10),
            ],
            if (!hasOpenTask)
              openActionsAsync.maybeWhen(
                loading:
                    () => const Aluno360CopilotTaskStatus(
                      icon: Icons.sync_rounded,
                      title: 'Sincronizando tarefas',
                      subtitle:
                          'Checando ${FocuxMicrocopy.commandCenter} antes de criar.',
                    ),
                orElse: () => const SizedBox.shrink(),
              ),
            if (!hasOpenTask && openActionsAsync.isLoading)
              const SizedBox(height: 10),
            if (!hasOpenTask &&
                shouldShowCopilotExecutarAcao(
                  tipoAcao: effectiveProxima?.tipoAcao,
                  aluno: aluno,
                  proxima: effectiveProxima,
                  outreachMessage: operacao.outreachMessage,
                )) ...[
              Aluno360CopilotExecutarAcaoButton(
                alunoId: aluno.id,
                spec:
                    resolveCopilotExecutarAcao(
                      tipoAcao: effectiveProxima?.tipoAcao,
                      aluno: aluno,
                      proxima: effectiveProxima,
                      outreachMessage: operacao.outreachMessage,
                    )!,
                primary: primary,
              ),
              const SizedBox(height: 10),
            ],
            if (!hasOpenTask)
              Aluno360CopilotActionRow(
                aluno: aluno,
                primary: primary,
                existingTask: openTask,
                openTaskHint: hasOpenCopilotTask360 && openTask == null,
                hidePrimaryCta: hasOpenTask || hideCopilotPrimary,
                hideChatCta: hideCopilotChat,
                acao: resolvedAcao,
                onAssign:
                    (acao) => criarTarefaCopilotoFromAluno360(
                      context: context,
                      ref: ref,
                      aluno: aluno,
                      acao: acao,
                    ),
                onPrepareMessage: (acao) => _prepararMensagem(context, acao),
              ),
        ],
      ),
    );
  }
}
