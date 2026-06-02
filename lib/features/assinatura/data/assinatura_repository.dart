import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/offline_sync_service.dart';
import '../../../core/api/payment_api_client.dart';
import '../../../core/planos/plano_cache_policy.dart';
import '../../planos/paywall/paywall_vitrine.dart';

import 'plano.dart';

class AssinaturaRepository {
  final Dio _dio;
  final Dio _paymentDio;
  static const _vitrineCacheKey = 'focux_paywall_vitrine_cache_v1';

  AssinaturaRepository(ApiClient client, PaymentApiClient payment)
    : _dio = client.dio,
      _paymentDio = payment.dio;

  Future<List<Plano>> listarPlanos() async {
    final response = await _dio.get('/api/planos');
    final list = response.data as List<dynamic>;
    return list.map((e) => Plano.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaywallVitrineSnapshot> fetchVitrine({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _loadVitrineCache();
      if (cached != null) return cached;
    }
    final response = await _dio.get('/api/planos/vitrine');
    final raw = response.data as Map<String, dynamic>;
    await _saveVitrineCache(raw);
    return PaywallVitrineSnapshot.fromApi(raw);
  }

  Future<void> clearVitrineCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vitrineCacheKey);
    await LocalCache.invalidate('/api/planos/vitrine');
  }

  Future<PaywallVitrineSnapshot?> _loadVitrineCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vitrineCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(decoded['savedAt'] as String);
      if (DateTime.now().difference(savedAt) > PlanoCachePolicy.vitrineMaxAge) {
        await prefs.remove(_vitrineCacheKey);
        return null;
      }
      return PaywallVitrineSnapshot.fromApi(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    } catch (_) {
      await prefs.remove(_vitrineCacheKey);
      return null;
    }
  }

  Future<void> _saveVitrineCache(Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _vitrineCacheKey,
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'data': raw,
      }),
    );
  }

  Future<String> criarPreferencia(int planoId) async {
    final response = await _paymentDio.post(
      '/api/pagamentos/preferencia/$planoId',
    );
    return response.data['checkoutUrl'] as String;
  }
}
