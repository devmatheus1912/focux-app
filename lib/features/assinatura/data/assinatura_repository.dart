import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/offline_sync_service.dart';
import '../../../core/api/payment_api_client.dart';
import '../../planos/paywall/paywall_vitrine.dart';

import 'plano.dart';

class PaywallHomeBundle {
  final List<Plano> planos;
  final PaywallVitrineSnapshot vitrine;

  const PaywallHomeBundle({required this.planos, required this.vitrine});
}

class AssinaturaRepository {
  final Dio _dio;
  final Dio _paymentDio;
  static const _legacyVitrineCacheKey = 'focux_paywall_vitrine_cache_v1';

  AssinaturaRepository(ApiClient client, PaymentApiClient payment)
    : _dio = client.dio,
      _paymentDio = payment.dio;

  /// BFF first paint — planos + vitrine em um round-trip.
  Future<PaywallHomeBundle> getPaywallHome() async {
    final response = await _dio.get('/api/planos/paywall/home');
    final raw = response.data as Map<String, dynamic>;
    final planosRaw = (raw['planos'] as List<dynamic>? ?? const []);
    final planos =
        planosRaw
            .map((e) => Plano.fromJson(e as Map<String, dynamic>))
            .toList();
    final vitrineRaw =
        (raw['vitrine'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    PaywallVitrineSnapshot vitrine;
    try {
      vitrine = PaywallVitrineSnapshot.fromApi(vitrineRaw);
    } catch (_) {
      vitrine = PaywallVitrineSnapshot.fromCatalog();
    }
    return PaywallHomeBundle(planos: planos, vitrine: vitrine);
  }

  Future<void> clearVitrineCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyVitrineCacheKey);
    await LocalCache.invalidate('/api/planos/paywall/home');
  }

  Future<String> criarPreferencia(int planoId) async {
    final response = await _paymentDio.post(
      '/api/pagamentos/preferencia/$planoId',
    );
    return response.data['checkoutUrl'] as String;
  }
}
