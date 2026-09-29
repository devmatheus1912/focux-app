import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../api/api_transport_circuit.dart';
import '../api/offline_drain_scheduler.dart';
import '../api/offline_sync_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/session_refresh_coordinator.dart';
import '../theme/design_tokens.dart';
import '../utils/connectivity_banner_state.dart';
import 'feedback_helper.dart';

/// Mostra conexão e fila offline, e drena a fila: ao voltar a rede, ao voltar
/// ao primeiro plano e em intervalo enquanto houver pendência.
class FxConnectivityBanner extends ConsumerStatefulWidget {
  const FxConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FxConnectivityBanner> createState() =>
      _FxConnectivityBannerState();
}

class _FxConnectivityBannerState extends ConsumerState<FxConnectivityBanner>
    with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  StreamSubscription<void>? _queueChanges;
  late final OfflineDrainScheduler _scheduler;
  bool _offline = false;
  bool _circuitOpen = false;
  int _pending = 0;
  int _dropped = 0;
  var _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduler = OfflineDrainScheduler(
      pendingCount: OfflineSyncService.getPendingCount,
      drain: _drain,
      foreground: isForegroundLifecycle(
        WidgetsBinding.instance.lifecycleState,
      ),
    );
    OfflineSyncService.onMutationsDropped = _onMutationsDropped;
    _queueChanges = OfflineSyncService.changes.listen((_) {
      _reloadCounts();
      _scheduler.onQueueChanged();
    });
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _onConnectivityChanged();
    });
    _onConnectivityChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _scheduler.onResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _scheduler.onBackground();
      case AppLifecycleState.inactive:
        break;
    }
  }

  // Chamado de listeners sem await: falha do plugin, do refresh ou da
  // drenagem não pode virar erro não tratado. O banner fica no último estado
  // conhecido e a contagem ainda é recarregada.
  Future<void> _onConnectivityChanged() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (!mounted) return;
      setState(() => _offline = offline);

      final cameBack = _wasOffline && !offline;
      _wasOffline = offline;
      // Volta online: warm JWT (se perto do exp) antes de drenar.
      if (cameBack && ref.read(authProvider) == AuthStatus.authenticated) {
        await SessionRefreshCoordinator.ensureFreshAccess(force: false);
      }

      await _drain();
    } catch (_) {}
    await _reloadCounts();
    await _scheduler.onQueueChanged();
  }

  /// Drenar sem rede só gastaria tentativas do backoff da fila.
  Future<void> _drain() async {
    if (!mounted || _offline) return;
    if (await OfflineSyncService.getPendingCount() == 0 || !mounted) return;
    await OfflineSyncService.syncPendingRequests(
      ref.read(apiClientProvider).dio,
    );
  }

  Future<void> _reloadCounts() async {
    final int pending;
    final int dropped;
    try {
      pending = await OfflineSyncService.getPendingCount();
      // O que a fila desistiu de reenviar precisa aparecer, porque a tela já
      // disse ao usuário que a ação ficou para depois.
      dropped = (await OfflineSyncService.pendingDropped()).length;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _dropped = dropped;
      _circuitOpen = ApiTransportCircuit.isOpen;
    });
  }

  /// Chamado uma vez por rodada da fila: vários descartes, um aviso.
  void _onMutationsDropped(List<DroppedMutation> _) {
    if (!mounted) return;
    FeedbackHelper.showError(context, S.of(context).conexaoAlteracaoDescartada);
  }

  Future<void> _dismissDropped() => OfflineSyncService.clearDropped();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (OfflineSyncService.onMutationsDropped == _onMutationsDropped) {
      OfflineSyncService.onMutationsDropped = null;
    }
    _scheduler.dispose();
    _queueChanges?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = resolveConnectivityBanner(
      offline: _offline,
      circuitOpen: _circuitOpen,
      pending: _pending,
      dropped: _dropped,
    );
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child:
              kind != ConnectivityBannerKind.hidden
                  ? Material(
                    color: _bannerColor(context, kind),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _bannerIcon(kind),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              // Leitor de tela anuncia a troca de estado
                              // (offline, pendente, descarte) sem foco.
                              child: Semantics(
                                liveRegion: true,
                                container: true,
                                child: Text(
                                  _bannerMessage(S.of(context), kind),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            // Descarte é o único estado que exige ciência do
                            // usuário: conexão e sincronia se resolvem sozinhas.
                            if (kind == ConnectivityBannerKind.dropped)
                              TextButton(
                                onPressed: _dismissDropped,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(44, 44),
                                ),
                                child: Text(S.of(context).conexaoOk),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Color _bannerColor(BuildContext context, ConnectivityBannerKind kind) {
    return switch (kind) {
      ConnectivityBannerKind.offline ||
      ConnectivityBannerKind.offlinePending =>
        EagleTokens.bad.withValues(alpha: 0.92),
      ConnectivityBannerKind.dropped => EagleTokens.warn.withValues(
        alpha: 0.94,
      ),
      ConnectivityBannerKind.unstable => EagleTokens.warn.withValues(
        alpha: 0.92,
      ),
      _ => Theme.of(context).colorScheme.primary.withValues(alpha: 0.92),
    };
  }

  IconData _bannerIcon(ConnectivityBannerKind kind) {
    return switch (kind) {
      ConnectivityBannerKind.offline ||
      ConnectivityBannerKind.offlinePending => Icons.wifi_off_rounded,
      ConnectivityBannerKind.dropped => Icons.error_outline_rounded,
      ConnectivityBannerKind.unstable => Icons.cloud_off_rounded,
      _ => Icons.sync,
    };
  }

  String _bannerMessage(S s, ConnectivityBannerKind kind) {
    return switch (kind) {
      ConnectivityBannerKind.offline => s.conexaoOffline,
      ConnectivityBannerKind.offlinePending => s.conexaoPendentesOffline(
        _pending,
      ),
      ConnectivityBannerKind.dropped => s.conexaoDescartadas(_dropped),
      ConnectivityBannerKind.unstable => s.conexaoInstavel,
      _ => s.conexaoSincronizando(_pending),
    };
  }
}
