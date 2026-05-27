import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/coach_proativo_repository.dart';

final coachMensagensProvider = FutureProvider<List<CoachMensagem>>((ref) async {
  return CoachProativoRepository(ref.read(apiClientProvider)).mensagens();
});

class CoachProativoCard extends ConsumerWidget {
  const CoachProativoCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coachMensagensProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (msgs) {
        if (msgs.isEmpty) return const SizedBox.shrink();
        final msg = msgs.first;
        return Container(
          margin: const EdgeInsets.only(bottom: TokensStrip.s3),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
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
                  Text('Coach proativo', style: TextStyle(fontWeight: FontWeight.w600, color: ink)),
                ],
              ),
              const SizedBox(height: 8),
              Text(msg.mensagem, style: TextStyle(color: ink, height: 1.35)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await CoachProativoRepository(ref.read(apiClientProvider)).marcarLido(msg.id);
                    ref.invalidate(coachMensagensProvider);
                  },
                  child: const Text('Entendi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
