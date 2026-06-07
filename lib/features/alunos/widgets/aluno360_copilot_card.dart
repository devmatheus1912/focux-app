import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../utils/aluno360_copilot_task_actions.dart';
import '../widgets/aluno360_copilot_executar_button.dart';
import '../widgets/aluno360_copilot_ia_refresh_button.dart';
import '../widgets/aluno360_copilot_prescription.dart';
import '../widgets/aluno360_copilot_support.dart';
import '../widgets/aluno360_operacao_focus_toggle.dart';
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
    await _showProfileGapSheet(context, aluno, gaps);
  }

  Future<void> _showProfileGapSheet(
    BuildContext context,
    Aluno aluno,
    List<CopilotProfileGap> gaps,
  ) async {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    Future<void> go(CopilotProfileGap gap, BuildContext sheetContext) async {
      Navigator.of(sheetContext).pop();
      await _openProfileGap(context, aluno, gap);
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.of(sheetContext).padding.bottom,
              ),
              child: ShellSurface(
                radius: TokensStrip.rCard,
                accent: primary,
                padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 8, 20, 20),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completar perfil',
                              style: TextStyle(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              gaps.isEmpty
                                  ? 'Perfil pronto para decisões da IA.'
                                  : '${gaps.length} lacuna(s) afetam a prescrição.',
                              style: TextStyle(color: mute, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  if (gaps.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EagleTokens.good.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: EagleTokens.good.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text('Nada pendente no perfil agora.'),
                    )
                  else
                    ...gaps.map(
                      (gap) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => go(gap, sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: fxListCardDecoration(
                              sheetContext,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: BrandPalette.soft(
                                      primary,
                                      dark: isDark,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    gap.icon,
                                    color: primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gap.title,
                                        style: TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        gap.detail,
                                        style: TextStyle(
                                          color: mute,
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: mute),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (gaps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Para ajustes gerais, use Editar nas ações rápidas.',
                        style: TextStyle(color: mute, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
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
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final line = ShellChrome.of(context).line;
    final forceIa = ref.watch(alunoCopilotoForceIaProvider(aluno.id));
    final iaAsync =
        forceIa ? ref.watch(alunoCopilotoActionProvider(aluno.id)) : null;
    final openActionsAsync = ref.watch(alunoOpenIaActionsProvider(aluno.id));
    final openTask = findOpenCopilotTask(openActionsAsync.valueOrNull ?? const []);
    final hasOpenTask = openTask != null || hasOpenCopilotTask360;
    final operacao =
        ref.watch(aluno360OperacaoProvider(aluno.id)) ??
        resolveAluno360OperacaoSnapshot(
          aluno: aluno,
          proximaAcao360: proximaAcao360,
          forceIa: forceIa,
          iaAsync: iaAsync,
          hasOpenTask: hasOpenTask,
          followUpDue: isAlunoFollowUpDue(aluno),
          wearableRelevant: alunoTemHistoricoWearable(
            ref.watch(alunoRecoveryProvider(aluno.id)).valueOrNull,
          ),
        );
    final iaLoading =
        forceIa && iaAsync != null && iaAsync.isLoading && !iaAsync.hasValue;
    final resumo = resumoAsync.valueOrNull;
    final profileCompletion = copilotProfileCompletion(aluno);
    final signals = resolveCopilotSignals(
      aluno: aluno,
      resumo: resumo,
      primary: primary,
    );
    final fallback = copilotFallbackAction(aluno, resumo);
    final seed360 =
        proximaAcao360 != null
            ? copilotActionFrom360(proximaAcao360!)
            : null;
    final stickyAction = operacao.stickyAction;
    final effectiveProxima = operacao.effectiveProxima;
    final hideCopilotChat = operacao.hideCopilotChatRow;
    final showCopilotPrescription = shouldShowCopilotPrescriptionBlock(
      forceIa: forceIa,
      sticky: stickyAction,
      aluno: aluno,
      proximaAcaoRaw: proximaAcao360?.acao,
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
    final cardPadding = hasOpenTask ? 10.0 : 14.0;
    final wearableRelevant =
        effectiveProxima?.wearableRelevant ??
        alunoTemHistoricoWearable(
          ref.watch(alunoRecoveryProvider(aluno.id)).valueOrNull,
        );

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: Aluno360Layout.operacaoInsetSectionDecoration(
        context,
        primary: primary,
        isDark: isDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.hub_outlined, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copilotCardTitle(
                        contactPriority: operacao.contactPriority,
                      ),
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            copilotCardSubtitle(
                              forceIa: forceIa,
                              iaAsync: iaAsync,
                              resumoLoading:
                                  resumoAsync.isLoading && !resumoAsync.hasValue,
                            ),
                            style: TextStyle(
                              color: mute,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (shouldShowCopilotContactBadge(
                          contactPriority: operacao.contactPriority,
                          sticky: stickyAction,
                        )) ...[
                          const SizedBox(width: 8),
                          Aluno360ContactPriorityBadge(primary: primary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (showFocusToggle)
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
          if (iaLoading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: primary.withValues(alpha: 0.12),
                color: primary,
              ),
            ),
          ],
          if (!hasOpenTask) ...[
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.15,
              children:
                  signals
                      .map((signal) => Aluno360CopilotSignalTile(signal: signal))
                      .toList(),
            ),
          ],
          if (!hasOpenTask) const SizedBox(height: 10),
          if (shouldShowCopilotProfileGapsButton(
            aluno,
            profileCompletion,
            sticky: stickyAction,
          )) ...[
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _completeProfile(context, aluno),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: Text(
                  copilotProfileGapsButtonLabel(aluno),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.28)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
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
              resumoLoading: resumoAsync.isLoading && !resumoAsync.hasValue,
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
                    subtitle: 'Checando Command Center antes de criar.',
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
              spec: resolveCopilotExecutarAcao(
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

class Aluno360ContactPriorityBadge extends StatelessWidget {
  const Aluno360ContactPriorityBadge({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.22)),
      ),
      child: Text(
        'Contato',
        style: TextStyle(
          color: EagleTokens.bad,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
