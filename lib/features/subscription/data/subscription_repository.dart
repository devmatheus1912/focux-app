import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class SubscriptionRepository {
  final Dio _dio;
  SubscriptionRepository(ApiClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> iapHealth() async {
    final r = await _dio.get('/api/iap/health');
    return r.data as Map<String, dynamic>;
  }
}
