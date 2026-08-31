import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';

/// Signal rows inside the copiloto inset group (not a 2×2 KPI well).
class Aluno360CopilotSignalsGrid extends StatelessWidget {
  const Aluno360CopilotSignalsGrid({super.key, required this.signals});

  final List<Aluno360CopilotSignal> signals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      onTap: () {},
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
      onTap: () {},
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
      FeedbackHelper.showSuccess(context, 'Tarefa concluída.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
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

    final tiles = <Widget>[];
    if (!hidePrimary) {
      if (hasTask) {
        if (widget.existingTask != null) {
          tiles.add(
            FxSettingsTile(
              icon: Icons.check_circle_outline_rounded,
              label: 'Concluir',
              subtitle: 'Marcar a tarefa do copiloto como feita',
              value: '',
              accent: widget.primary,
              showDivider: true,
              semanticsLabel: 'Concluir tarefa do copiloto',
              accessory:
                  _completing
                      ? const FxLoading(size: 18, strokeWidth: 2)
                      : null,
              onTap: _completing ? () {} : _completeOpenTask,
            ),
          );
        }
        tiles.add(
          FxSettingsTile(
            icon: Icons.open_in_new_rounded,
            label: FocuxMicrocopy.commandCenter,
            subtitle: 'Abrir a fila de ações',
            value: '',
            accent: widget.primary,
            showDivider: !widget.hideChatCta,
            semanticsLabel: 'Abrir ${FocuxMicrocopy.commandCenter}',
            onTap: _handlePrimary,
          ),
        );
      } else {
        tiles.add(
          FxSettingsTile(
            icon: Icons.task_alt_rounded,
            label: _creating ? 'Criando...' : 'Criar tarefa',
            subtitle: 'Mandar para o ${FocuxMicrocopy.commandCenter}',
            value: '',
            accent: widget.primary,
            highlight: true,
            showDivider: !widget.hideChatCta,
            accessory:
                _creating ? const FxLoading(size: 18, strokeWidth: 2) : null,
            onTap: _creating ? () {} : _handlePrimary,
          ),
        );
      }
    }
    if (!widget.hideChatCta) {
      tiles.add(
        FxSettingsTile(
          icon: Icons.chat_bubble_outline,
          label: 'Abrir chat',
          subtitle: 'Mensagem sugerida com ${widget.aluno.nome}',
          value: '',
          accent: widget.primary,
          showDivider: false,
          semanticsLabel: 'Abrir chat com ${widget.aluno.nome}',
          onTap: () => widget.onPrepareMessage(widget.acao),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tiles,
    );
  }
}
