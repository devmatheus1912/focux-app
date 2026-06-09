import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_motion.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../widgets/aluno_outreach_message_sheet.dart';

class Aluno360OperacaoStickyCtaBar extends ConsumerWidget {
  const Aluno360OperacaoStickyCtaBar({super.key, 
    required this.aluno,
    required this.alunoId,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.isDark,
  });

  final Aluno aluno;
  final int alunoId;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final line = ShellChrome.of(context).line;
    final creating = ref.watch(alunoCopilotCreatingProvider(alunoId));
    final openActions = ref.watch(alunoOpenIaActionsProvider(alunoId));
    final operacao = ref.watch(aluno360OperacaoProvider(alunoId));
    if (operacao == null) {
      return const SizedBox.shrink();
    }
    final sticky = operacao.stickyAction;
    final effectiveProxima = operacao.effectiveProxima;
    final hasOpenTask =
        findOpenCopilotTask(openActions.valueOrNull ?? const []) != null ||
        hasOpenCopilotTask360;
    final followUpDue = isAlunoFollowUpDue(aluno);

    void openOutreach() {
      showAlunoOutreachMessageSheet(
        context,
        alunoId: alunoId,
        alunoNome: aluno.nome,
        message: operacao.outreachMessage,
        title: 'Mensagem sugerida',
        subtitle: 'Copiloto · revise antes de enviar.',
        icon: Icons.auto_awesome_rounded,
      );
    }

    void openChat({String? acao}) {
      final actionText = acao?.trim() ?? effectiveProxima?.acao.trim() ?? '';
      if (sticky.isChatAction ||
          (actionText.isNotEmpty && acaoSugereChat(actionText))) {
        openOutreach();
        return;
      }
      context.push('/alunos/$alunoId/chat', extra: aluno.nome);
    }

    void openCommandCenter() {
      context.push('/dashboard/command-center/copiloto');
    }

    void openEvolucao() {
      context.push('/alunos/$alunoId/evolucao', extra: aluno.nome);
    }

    void openEditAluno() {
      context.push('/alunos/$alunoId/editar', extra: aluno);
    }

    void onPrimary() {
      HapticFeedback.lightImpact();
      switch (sticky.destination) {
        case OperacaoStickyDestination.chat:
          openChat(acao: effectiveProxima?.acao);
        case OperacaoStickyDestination.commandCenter:
          openCommandCenter();
        case OperacaoStickyDestination.evolucao:
          openEvolucao();
        case OperacaoStickyDestination.editAluno:
          openEditAluno();
      }
    }
    final showSecondaryCommandCenter = shouldShowStickySecondaryCommandCenter(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
    );
    final showSecondaryChat = shouldShowStickySecondaryChat(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
      followUpDue: followUpDue,
      proximaAcaoText: effectiveProxima?.acao,
    );
    final hasSecondary = showSecondaryCommandCenter || showSecondaryChat;
    final stickyDisplayLabel = operacao.stickyDisplayLabel;

    return SafeArea(
      top: false,
        child: Semantics(
        container: true,
        label: 'Ações rápidas da aba operação',
        child: Container(
        key: const ValueKey('aluno360_operacao_sticky_cta'),
        decoration: BoxDecoration(
          color: ShellChrome.of(context).sheetFill,
          border: Border(top: BorderSide(color: line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: hasSecondary ? 5 : 1,
              child: Semantics(
                button: true,
                label: stickyDisplayLabel,
                child: FxLiquidPrimaryButton(
                  icon: sticky.icon,
                  label: stickyDisplayLabel,
                  loading: creating,
                  loadingLabel: 'Criando…',
                  onPressed: creating ? null : onPrimary,
                ),
              ),
            ),
              if (showSecondaryCommandCenter) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Aluno360OperacaoStickySecondaryButton(
                    label: 'Tarefa',
                    icon: Icons.task_alt_rounded,
                    primary: primary,
                    semanticsLabel: 'Abrir tarefa no Command Center',
                    onPressed: openCommandCenter,
                  ),
                ),
              ],
              if (showSecondaryChat) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Aluno360OperacaoStickySecondaryButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                    primary: primary,
                    semanticsLabel: 'Abrir chat com aluno',
                    onPressed:
                        () => openChat(acao: effectiveProxima?.acao),
                  ),
                ),
              ],
            ],
          ),
      ),
      ),
    );
  }
}

class Aluno360OperacaoStickySecondaryButton extends StatelessWidget {
  const Aluno360OperacaoStickySecondaryButton({super.key, 
    required this.label,
    required this.icon,
    required this.primary,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color primary;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: OutlinedButton(
        onPressed: onPressed,
        style: Aluno360Layout.operacaoOutlinedButtonStyle(context, primary).copyWith(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Aluno360Layout.ctaLabelStyle(context, primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

