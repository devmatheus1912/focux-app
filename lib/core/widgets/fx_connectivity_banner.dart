import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/offline_sync_service.dart';
import '../theme/design_tokens.dart';

/// Shows offline/sync status and flushes the offline queue when back online.
class FxConnectivityBanner extends StatefulWidget {
  const FxConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<FxConnectivityBanner> createState() => _FxConnectivityBannerState();
}

class _FxConnectivityBannerState extends State<FxConnectivityBanner> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;
  int _pending = 0;

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
      await OfflineSyncService.syncPendingRequests(ApiClient().dio);
      final after = await OfflineSyncService.getPendingCount();
      if (mounted) setState(() => _pending = after);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _offline || _pending > 0;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child:
              showBanner
                  ? Material(
                    color:
                        _offline
                            ? EagleTokens.bad.withValues(alpha: 0.92)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.92),
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
                              _offline ? Icons.wifi_off_rounded : Icons.sync,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _offline
                                    ? 'Sem conexao — alteracoes serao sincronizadas depois.'
                                    : 'Sincronizando $_pending acao(oes) pendente(s)...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
}
