import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/payment_api_client.dart';
import '../../planos/paywall/paywall_vitrine.dart';

import 'plano.dart';

class AssinaturaRepository {
  final Dio _dio;
  final Dio _paymentDio;

  AssinaturaRepository(ApiClient client, PaymentApiClient payment)
    : _dio = client.dio,
      _paymentDio = payment.dio;

  Future<List<Plano>> listarPlanos() async {
    final response = await _dio.get('/api/planos');
    final list = response.data as List<dynamic>;
    return list.map((e) => Plano.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaywallVitrineSnapshot> fetchVitrine() async {
    final response = await _dio.get('/api/planos/vitrine');
    return PaywallVitrineSnapshot.fromApi(
      response.data as Map<String, dynamic>,
    );
  }

  Future<String> criarPreferencia(int planoId) async {
    final response = await _paymentDio.post(
      '/api/pagamentos/preferencia/$planoId',
    );
    return response.data['checkoutUrl'] as String;
  }
}
