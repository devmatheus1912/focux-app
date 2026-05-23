import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/health/health_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../health/data/health_repository.dart';
import 'recovery_score_ring.dart';

final alunoRecoveryProvider = FutureProvider<RecoverySnapshot?>((ref) async {
  if (!await HealthService.isAuthorized()) return null;
  final repo = HealthRepository.fromClient(ref.read(apiClientProvider));
  try {
    return await repo.fetchLatestRecovery();
  } catch (_) {
    final summary = await HealthService.getTodaySummary();
    return RecoverySnapshot.fromSummary(summary);
  }
});

class AlunoRecoveryCard extends ConsumerWidget {
  const AlunoRecoveryCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final async = ref.watch(alunoRecoveryProvider);

    return async.when(
      loading: () => _shell(context, primary, isDark, child: const FxLoading()),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshot) {
        if (snapshot == null) {
          return _ConnectCard(isDark: isDark, onTap: () => context.push('/saude'));
        }
        return _shell(
          context,
          primary,
          isDark,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/saude');
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  RecoveryScoreRing(
                    score: snapshot.recoveryScore,
                    color: primary,
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prontidao do dia',
                          style: TextStyle(
                            color: mute,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.recoveryLabel,
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.recoveryHint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: mute, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: mute),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _shell(
    BuildContext context,
    Color primary,
    bool isDark, {
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: isDark ? 0.18 : 0.10),
            primary.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.watch_outlined, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Conecte Apple Health ou Google Fit para ver sua prontidao diaria.',
                  style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
                ),
              ),
              Icon(Icons.north_east, size: 16, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
