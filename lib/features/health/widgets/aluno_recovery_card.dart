import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../health/data/health_repository.dart';
import '../../../core/health/health_service.dart';
import '../../../core/health/home_widget_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_rive_player.dart';
import '../utils/health_dashboard_display.dart';
import 'recovery_score_ring.dart';

/// Resultado do provider local (não-BFF): snapshot + soft error sem engolir falha.
class AlunoRecoveryView {
  const AlunoRecoveryView({this.snapshot, this.softError});

  final RecoverySnapshot? snapshot;
  final String? softError;
}

final alunoRecoveryProvider = FutureProvider<AlunoRecoveryView>((ref) async {
  if (!await HealthService.isAuthorized()) {
    return const AlunoRecoveryView();
  }
  final repo = HealthRepository.fromClient(ref.read(apiClientProvider));
  try {
    final summary = await HealthService.getTodaySummary();
    try {
      final synced = await repo.syncToday(summary);
      await HomeWidgetService.updateRecovery(
        recoveryScore: synced.recoveryScore,
        recoveryLabel: synced.recoveryLabel,
        recoveryHint: synced.recoveryHint,
        steps: synced.steps,
      );
      return AlunoRecoveryView(snapshot: synced);
    } catch (e) {
      try {
        final latest = await repo.fetchLatestRecovery();
        return AlunoRecoveryView(
          snapshot: latest,
          softError: saudeSyncSoftError(friendlyError(e)),
        );
      } catch (_) {
        return AlunoRecoveryView(
          snapshot: RecoverySnapshot.fromSummary(summary),
          softError: saudeSyncSoftError(friendlyError(e)),
        );
      }
    }
  } catch (e) {
    try {
      final latest = await repo.fetchLatestRecovery();
      return AlunoRecoveryView(
        snapshot: latest,
        softError: saudeSyncSoftError(friendlyError(e)),
      );
    } catch (_) {
      rethrow;
    }
  }
});

class AlunoRecoveryCard extends ConsumerWidget {
  const AlunoRecoveryCard({
    super.key,
    required this.isDark,
    this.snapshot = _unset,
    this.hasWearableHistory,
  });

  static const Object _unset = Object();

  final bool isDark;

  /// Pass a [RecoverySnapshot] or explicit `null` from the Home BFF.
  /// Omit the argument to watch [alunoRecoveryProvider] (ex.: /saude).
  final Object? snapshot;

  /// Home BFF: sem histórico wearable → esconde o card (não confundir com scoreProntidao).
  final bool? hasWearableHistory;

  bool get _fromBundle => !identical(snapshot, _unset);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_fromBundle) {
      final snap = snapshot as RecoverySnapshot?;
      final hist = hasWearableHistory ?? (snap != null);
      if (!hist || snap == null) return const SizedBox.shrink();
      return _buildFromSnapshot(context, snap);
    }
    final async = ref.watch(alunoRecoveryProvider);
    return async.when(
      loading: () {
        final primary = Theme.of(context).colorScheme.primary;
        return _shell(context, primary, isDark, child: const FxLoading());
      },
      error: (err, _) => _RecoverySoftError(
        isDark: isDark,
        message: friendlyError(
          err,
          fallback: 'Não foi possível carregar a prontidão.',
        ),
        onRetry: () => ref.invalidate(alunoRecoveryProvider),
        onOpen: () => context.push('/saude'),
      ),
      data: (view) {
        if (view.softError != null && view.snapshot != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RecoverySoftError(
                isDark: isDark,
                title: 'Sync parcial',
                message: view.softError!,
                onRetry: () => ref.invalidate(alunoRecoveryProvider),
                onOpen: () => context.push('/saude'),
              ),
              const SizedBox(height: 8),
              _buildFromSnapshot(context, view.snapshot),
            ],
          );
        }
        return _buildFromSnapshot(context, view.snapshot);
      },
    );
  }

  Widget _buildFromSnapshot(BuildContext context, RecoverySnapshot? snapshot) {
    if (snapshot == null) {
      return _ConnectCard(isDark: isDark, onTap: () => context.push('/saude'));
    }
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      RecoveryScoreRing(
                        score: snapshot.recoveryScore,
                        color: primary,
                        size: 54,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: FxRiveHeartPulse(size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prontidão do dia',
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
                          style: TextStyle(
                            color: mute,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: mute),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.04, curve: Curves.easeOutCubic);
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
                  'Conecte Apple Health ou Google Fit para ver sua prontidão diária.',
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

class _RecoverySoftError extends StatelessWidget {
  const _RecoverySoftError({
    required this.isDark,
    required this.message,
    required this.onRetry,
    required this.onOpen,
    this.title = 'Prontidão indisponível',
  });

  final bool isDark;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Tentar de novo'),
                ),
                TextButton(
                  onPressed: onOpen,
                  child: const Text('Abrir Saúde'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
