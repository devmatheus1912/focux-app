import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/payment_api_client.dart';
import '../services/iap_service.dart';

/// Estado da loja nativa + backend IAP (health check periódico v5.1).
class IapStoreHealth {
  final bool storeAvailable;
  final bool? backendReachable;
  final DateTime checkedAt;
  final String? detail;

  const IapStoreHealth({
    required this.storeAvailable,
    this.backendReachable,
    required this.checkedAt,
    this.detail,
  });

  bool get isHealthy =>
      storeAvailable && (backendReachable ?? true);
}

final iapStoreHealthProvider =
    StateNotifierProvider<IapStoreHealthNotifier, IapStoreHealth>((ref) {
  final notifier = IapStoreHealthNotifier(
    ref.read(iapServiceProvider),
    ref.read(paymentApiClientProvider),
  );
  notifier.start();
  ref.onDispose(notifier.dispose);
  return notifier;
});

class IapStoreHealthNotifier extends StateNotifier<IapStoreHealth> {
  IapStoreHealthNotifier(this._iap, this._payment)
      : super(
          IapStoreHealth(
            storeAvailable: false,
            checkedAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );

  final IapService _iap;
  final PaymentApiClient _payment;
  Timer? _timer;
  bool _running = false;

  static const _interval = Duration(minutes: 15);

  void start() {
    _timer ??= Timer.periodic(_interval, (_) => unawaited(runCheck()));
    unawaited(runCheck());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> runCheck() async {
    if (_running) return;
    _running = true;
    try {
      final storeOk = await _iap.isAvailable();
      bool? backendOk;
      String? detail;
      if (storeOk) {
        try {
          final r = await _payment.dio.get(
            '/api/iap/health',
            options: Options(
              receiveTimeout: const Duration(seconds: 8),
              extra: {'fxNoRetry': true},
            ),
          );
          final data = r.data;
          if (data is Map<String, dynamic>) {
            backendOk = data['ok'] == true;
            detail = data['detail'] as String?;
          } else {
            backendOk = r.statusCode == 200;
          }
        } catch (e) {
          backendOk = false;
          detail = e.toString();
          if (kDebugMode) debugPrint('[IapHealth] backend check failed: $e');
        }
      }
      state = IapStoreHealth(
        storeAvailable: storeOk,
        backendReachable: backendOk,
        checkedAt: DateTime.now(),
        detail: detail,
      );
    } finally {
      _running = false;
    }
  }
}
