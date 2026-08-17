import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/coach_proativo_repository.dart';

final coachMensagensProvider = FutureProvider<List<CoachMensagem>>((ref) async {
  return CoachProativoRepository(ref.read(apiClientProvider)).mensagens();
});

class CoachProativoCard extends ConsumerStatefulWidget {
  const CoachProativoCard({super.key, required this.isDark, this.mensagens});
  final bool isDark;
  final List<CoachMensagem>? mensagens;

  @override
  ConsumerState<CoachProativoCard> createState() => _CoachProativoCardState();
}

class _CoachProativoCardState extends ConsumerState<CoachProativoCard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final provided = widget.mensagens;
    if (provided != null) {
      return _card(provided);
    }
    final async = ref.watch(coachMensagensProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: _card,
    );
  }

  Widget _card(List<CoachMensagem> msgs) {
    if (msgs.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final clamped = _index.clamp(0, msgs.length - 1);
    final msg = msgs[clamped];
    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: widget.isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Coach proativo',
                style: TextStyle(fontWeight: FontWeight.w600, color: ink),
              ),
              const Spacer(),
              if (msgs.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${clamped + 1}/${msgs.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(msg.mensagem, style: TextStyle(color: ink, height: 1.35)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (msgs.length > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed:
                          clamped == 0
                              ? null
                              : () => setState(() => _index = clamped - 1),
                      tooltip: 'Anterior',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed:
                          clamped >= msgs.length - 1
                              ? null
                              : () => setState(() => _index = clamped + 1),
                      tooltip: 'Próxima',
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              TextButton(
                onPressed: () async {
                  await CoachProativoRepository(
                    ref.read(apiClientProvider),
                  ).marcarLido(msg.id);
                  if (clamped >= msgs.length - 1 && clamped > 0) {
                    setState(() => _index = clamped - 1);
                  }
                  ref.invalidate(coachMensagensProvider);
                  ref.invalidate(alunoDashboardHomeProvider);
                },
                child: const Text('Entendi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
