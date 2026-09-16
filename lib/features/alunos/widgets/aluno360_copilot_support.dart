import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';

/// Signal rows in one Fx card (Perfil / Financeiro / Autonomia / Contexto).
class Aluno360CopilotSignalsGrid extends StatelessWidget {
  const Aluno360CopilotSignalsGrid({super.key, required this.signals});

  final List<Aluno360CopilotSignal> signals;

  @override
  Widget build(BuildContext context) {
    return FxSettingsGroup(
      children: [
        for (var i = 0; i < signals.length; i++)
          Aluno360CopilotSignalTile(
            signal: signals[i],
            showDivider: i < signals.length - 1,
          ),
      ],
    );
  }
}

class Aluno360CopilotSignalTile extends StatelessWidget {
  const Aluno360CopilotSignalTile({
    super.key,
    required this.signal,
    this.showDivider = true,
  });

  final Aluno360CopilotSignal signal;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return FxSettingsTile(
      icon: Icons.insights_outlined,
      label: signal.label,
      subtitle: signal.detail.isEmpty ? null : signal.detail,
      value: signal.value,
      numeric: true,
      accent: signal.color,
      showDivider: showDivider,
      semanticsLabel: '${signal.label}: ${signal.value}. ${signal.detail}',
    );
  }
}

class Aluno360CopilotTaskStatus extends StatelessWidget {
  const Aluno360CopilotTaskStatus({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return FxSettingsTile(
      icon: icon,
      label: title,
      subtitle: subtitle,
      value: '',
      showDivider: false,
    );
  }
}

class Aluno360CopilotActionRow extends ConsumerStatefulWidget {
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

  final Aluno aluno;
  final Color primary;
  final FilaAcaoResumo? existingTask;
  final bool openTaskHint;
  final bool hidePrimaryCta;
  final bool hideChatCta;
  final String acao;
  final Future<bool> Function(String acao) onAssign;
  final void Function(String acao) onPrepareMessage;

  @override
  ConsumerState<Aluno360CopilotActionRow> createState() =>
      _Aluno360CopilotActionRowState();
}

class _Aluno360CopilotActionRowState
    extends ConsumerState<Aluno360CopilotActionRow> {
  bool _completing = false;

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
      FeedbackHelper.showSuccess(context, 'Tarefa concluída.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _openCommandCenter() {
    context.push('/dashboard/command-center/copiloto');
  }

  @override
  Widget build(BuildContext context) {
    final hasTask = widget.existingTask != null || widget.openTaskHint;
    // Criar tarefa / Abrir chat vivem no sticky secondary ou Mais (#10).
    final hidePrimary = widget.hidePrimaryCta && hasTask;
    if (hidePrimary || !hasTask) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    void add(Widget child) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: FxSettingsLayout.groupGap));
      }
      children.add(child);
    }

    if (widget.existingTask != null) {
      add(
        _commandButton(
          label: _completing ? 'Concluindo...' : 'Concluir',
          semanticsLabel: 'Concluir tarefa do copiloto',
          loading: _completing,
          onPressed: _completing ? null : _completeOpenTask,
        ),
      );
    }
    add(
      FxSettingsTile(
        icon: Icons.open_in_new_rounded,
        label: FocuxMicrocopy.commandCenter,
        subtitle: 'Abrir a fila de ações',
        value: '',
        accent: widget.primary,
        showDivider: false,
        semanticsLabel: 'Abrir ${FocuxMicrocopy.commandCenter}',
        onTap: _openCommandCenter,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _commandButton({
    required String label,
    required VoidCallback? onPressed,
    String? semanticsLabel,
    bool loading = false,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(
            FxSettingsLayout.rowMinHeight,
            FxSettingsLayout.rowMinHeight,
          ),
          alignment: Alignment.centerLeft,
        ),
        child:
            loading
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FxLoading(size: 18, strokeWidth: 2, color: widget.primary),
                    const SizedBox(width: FxSettingsLayout.iconGap),
                    Text(label),
                  ],
                )
                : Text(label),
      ),
    );
  }
}
