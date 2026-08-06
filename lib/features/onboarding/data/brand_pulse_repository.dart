import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/brand/brand_pulse.dart';

/// Fetch enxuto do pulse de marca (pré-login, timeout curto).
class BrandPulseRepository {
  BrandPulseRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<BrandSocialProofItem>> fetchSocialProof({
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/public/brand/pulse',
      options: Options(receiveTimeout: timeout, sendTimeout: timeout),
    );
    final raw = response.data?['socialProof'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => BrandSocialProofItem.fromJson(Map<String, dynamic>.from(e)))
        .where((i) => i.isValid)
        .toList(growable: false);
  }
}
