import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/aluno_360_layout.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';

class Aluno360CopilotSignalTile extends StatelessWidget {
  final Aluno360CopilotSignal signal;

  const Aluno360CopilotSignalTile({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final semanticsLabel =
        '${signal.label}: ${signal.value}. ${signal.detail}';
    return Semantics(
      label: semanticsLabel,
      button: signal.detail.isNotEmpty,
      child: Tooltip(
        message: signal.detail,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: signal.color.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: signal.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Aluno360Layout.metaStyle(context),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      signal.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Aluno360Layout.inlineMetricStyle(context, ink),
                    ),
                    if (signal.detail.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        signal.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Aluno360Layout.metaStyle(context).copyWith(
                          color: mute,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Aluno360CopilotTaskStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const Aluno360CopilotTaskStatus({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Aluno360Layout.panelTitleStyle(context, ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Aluno360Layout.captionStyle(context).copyWith(
                    color: mute,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Aluno360CopilotActionRow extends ConsumerStatefulWidget {
  final Aluno aluno;
  final Color primary;
  final FilaAcaoResumo? existingTask;
  final bool openTaskHint;
  final bool hidePrimaryCta;
  final bool hideChatCta;
  final String acao;
  final Future<bool> Function(String acao) onAssign;
  final void Function(String acao) onPrepareMessage;

  const Aluno360CopilotActionRow({
    super.key,
    required this.aluno,
    required this.primary,
    required this.existingTask,
    this.openTaskHint = false,
    this.hidePrimaryCta = false,
    this.hideChatCta = false,
    required this.acao,
    required this.onAssign,
    required this.onPrepareMessage,
  });

  @override
  ConsumerState<Aluno360CopilotActionRow> createState() =>
      _Aluno360CopilotActionRowState();
}

class _Aluno360CopilotActionRowState
    extends ConsumerState<Aluno360CopilotActionRow> {
  bool _creating = false;
  bool _completing = false;
  bool _created = false;

  Future<void> _completeOpenTask() async {
    final task = widget.existingTask;
    if (task == null || _completing) return;
    setState(() => _completing = true);
    try {
      await ref
          .read(dashboardRepositoryProvider)
          .completeCommandAction(task.actionKey);
      ref.invalidate(alunoOpenIaActionsProvider(widget.aluno.id));
      ref.invalidate(commandCenterProvider);
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Tarefa concluída.')),
        placement: FeedbackPlacement.operacaoTop,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
        placement: FeedbackPlacement.operacaoTop,
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _handlePrimary() async {
    if (widget.existingTask != null || widget.openTaskHint || _created) {
      context.push('/dashboard/command-center/copiloto');
      return;
    }
    ref.read(alunoCopilotCreatingProvider(widget.aluno.id).notifier).state =
        true;
    setState(() => _creating = true);
    final created = await widget.onAssign(widget.acao);
    if (!mounted) return;
    ref.read(alunoCopilotCreatingProvider(widget.aluno.id).notifier).state =
        false;
    setState(() {
      _creating = false;
      _created = created;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTask =
        widget.existingTask != null || widget.openTaskHint || _created;
    final hidePrimary = widget.hidePrimaryCta && hasTask;
    if (hidePrimary && widget.hideChatCta) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (!hidePrimary) ...[
          Expanded(
            flex: widget.hideChatCta ? 1 : 3,
            child:
                hasTask
                    ? Row(
                      children: [
                        if (widget.existingTask != null) ...[
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: 'Concluir tarefa do copiloto',
                              child: OutlinedButton(
                                onPressed:
                                    _completing ? null : _completeOpenTask,
                                style: Aluno360Layout.operacaoOutlinedButtonStyle(
                                  context,
                                  widget.primary,
                                ),
                                child:
                                    _completing
                                        ? const FxLoading(
                                          size: 18,
                                          strokeWidth: 2,
                                        )
                                        : Text(
                                          'Concluir',
                                          style: Aluno360Layout.chipLabelStyle(
                                            context,
                                            color: widget.primary,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Abrir Command Center',
                            child: TextButton.icon(
                              onPressed: _handlePrimary,
                              icon: Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                                color: widget.primary,
                              ),
                              label: Text(
                                'Command Center',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Aluno360Layout.chipLabelStyle(
                                  context,
                                  color: widget.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    : FxLiquidPrimaryButton(
                      loading: _creating,
                      icon: Icons.task_alt_rounded,
                      label: _creating ? 'Criando...' : 'Criar tarefa',
                      onPressed: _creating ? null : _handlePrimary,
                    ),
          ),
          const SizedBox(width: 8),
        ],
        if (!widget.hideChatCta)
          Expanded(
            flex: hidePrimary ? 1 : 2,
            child: Semantics(
              button: true,
              label: 'Abrir chat com ${widget.aluno.nome}',
              child: SizedBox(
                height: 44,
                child: InkWell(
                  onTap: () {
                    widget.onPrepareMessage(widget.acao);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.primary.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 15,
                          color: widget.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Abrir chat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Aluno360Layout.chipLabelStyle(
                              context,
                              color: widget.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
