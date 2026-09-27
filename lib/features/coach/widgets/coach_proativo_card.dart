import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/coach_proativo_repository.dart';

final coachHomeProvider = FutureProvider.autoDispose<CoachHome>((ref) {
  return CoachProativoRepository(ref.read(apiClientProvider)).getHome();
});

/// Mensagens não lidas do coach na Home do aluno (vêm do BFF).
class CoachProativoCard extends ConsumerStatefulWidget {
  const CoachProativoCard({super.key, required this.mensagens});

  final List<CoachMensagem> mensagens;

  @override
  ConsumerState<CoachProativoCard> createState() => _CoachProativoCardState();
}

class _CoachProativoCardState extends ConsumerState<CoachProativoCard> {
  int _index = 0;
  bool _enviando = false;

  Future<void> _marcarLido(CoachMensagem msg) async {
    setState(() => _enviando = true);
    try {
      await CoachProativoRepository(
        ref.read(apiClientProvider),
      ).marcarLido(msg.id);
      if (!mounted) return;
      invalidateAlunoDashboardHome(ref);
    } catch (_) {
      if (mounted) {
        FeedbackHelper.showError(context, S.of(context).alunoCoachErro);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs = widget.mensagens;
    if (msgs.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final atual = _index.clamp(0, msgs.length - 1);
    final msg = msgs[atual];

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: primary, size: 20),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Text(
                  s.alunoCoachTitulo,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
              ),
              if (msgs.length > 1)
                Text(
                  s.alunoCoachPosicao(atual + 1, msgs.length),
                  style: FocuxHubTypography.chip(chrome.mute),
                ),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(msg.mensagem, style: FocuxHubTypography.body(color: chrome.ink)),
          const SizedBox(height: TokensStrip.s1),
          Row(
            children: [
              if (msgs.length > 1) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: s.alunoCoachAnterior,
                  onPressed:
                      atual == 0
                          ? null
                          : () => setState(() => _index = atual - 1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: s.alunoCoachProxima,
                  onPressed:
                      atual >= msgs.length - 1
                          ? null
                          : () => setState(() => _index = atual + 1),
                ),
              ],
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: _enviando ? null : () => _marcarLido(msg),
                child: Text(s.alunoCoachEntendi),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
