import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'referral_info.dart';

export 'referral_info.dart';

class ReferralRepository {
  final Dio _dio;
  ReferralRepository(ApiClient c) : _dio = c.dio;

  Future<ReferralInfo> getInfo() async {
    final r = await _dio.get('/api/referral');
    return ReferralInfo.fromJson(r.data as Map<String, dynamic>);
  }

  /// % de desconto de indicado ainda não usado; null se não tiver.
  Future<int?> descontoPendentePct() async {
    final r = await _dio.get('/api/referral/desconto');
    return ((r.data as Map<String, dynamic>)['pct'] as num?)?.toInt();
  }

  /// Código de oferta Apple de uso único; campos nulos quando não há código.
  Future<({String? codigo, String? urlResgate})> codigoApple(
    String produtoId,
  ) async {
    final r = await _dio.post(
      '/api/referral/desconto/codigo-apple',
      data: {'produtoId': produtoId},
    );
    final j = r.data as Map<String, dynamic>;
    return (
      codigo: j['codigo'] as String?,
      urlResgate: j['urlResgate'] as String?,
    );
  }
}
