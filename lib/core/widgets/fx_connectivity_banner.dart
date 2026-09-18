import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../api/offline_sync_service.dart';
import '../theme/design_tokens.dart';

/// Shows offline/sync status and flushes the offline queue when back online.
class FxConnectivityBanner extends ConsumerStatefulWidget {
  const FxConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FxConnectivityBanner> createState() =>
      _FxConnectivityBannerState();
}

class _FxConnectivityBannerState extends ConsumerState<FxConnectivityBanner> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;
  int _pending = 0;
  int _dropped = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final results = await _connectivity.checkConnectivity();
    final offline = results.every((r) => r == ConnectivityResult.none);
    final pending = await OfflineSyncService.getPendingCount();
    if (!mounted) return;
    setState(() {
      _offline = offline;
      _pending = pending;
    });
    if (!offline && pending > 0) {
      await OfflineSyncService.syncPendingRequests(
        ref.read(apiClientProvider).dio,
      );
      final after = await OfflineSyncService.getPendingCount();
      if (mounted) setState(() => _pending = after);
    }
    // Depois de drenar: o que a fila desistiu de reenviar precisa aparecer,
    // porque a tela já disse ao usuário que a ação tinha sido registrada.
    final dropped = (await OfflineSyncService.pendingDropped()).length;
    if (mounted && dropped != _dropped) setState(() => _dropped = dropped);
  }

  Future<void> _dismissDropped() async {
    await OfflineSyncService.clearDropped();
    if (mounted) setState(() => _dropped = 0);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _offline || _dropped > 0 || _pending > 0;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child:
              showBanner
                  ? Material(
                    color: _bannerColor(context),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(_bannerIcon(), color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _bannerMessage(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            // Descarte é o único estado que exige ciência do
                            // usuário: conexão e sincronia se resolvem sozinhas.
                            if (!_offline && _dropped > 0)
                              TextButton(
                                onPressed: _dismissDropped,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(44, 44),
                                ),
                                child: const Text('OK'),
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

  Color _bannerColor(BuildContext context) {
    if (_offline) return EagleTokens.bad.withValues(alpha: 0.92);
    if (_dropped > 0) return EagleTokens.warn.withValues(alpha: 0.94);
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.92);
  }

  IconData _bannerIcon() {
    if (_offline) return Icons.wifi_off_rounded;
    if (_dropped > 0) return Icons.error_outline_rounded;
    return Icons.sync;
  }

  String _bannerMessage() {
    if (_offline) {
      return 'Sem conexao — alteracoes serao sincronizadas depois.';
    }
    if (_dropped > 0) {
      return _dropped == 1
          ? 'Uma alteracao nao pode ser salva. Refaca a acao.'
          : '$_dropped alteracoes nao puderam ser salvas. Refaca as acoes.';
    }
    return 'Sincronizando $_pending acao(oes) pendente(s)...';
  }
}
