import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ReferralInfo {
  final String codigo;
  final int usosTotais;
  final String linkCompartilhamento;

  ReferralInfo({
    required this.codigo,
    required this.usosTotais,
    required this.linkCompartilhamento,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> j) => ReferralInfo(
    codigo: j['codigo'] as String? ?? '',
    usosTotais: (j['usosTotais'] as num?)?.toInt() ?? 0,
    linkCompartilhamento: j['linkCompartilhamento'] as String? ?? '',
  );
}

class ReferralRepository {
  final Dio _dio;
  ReferralRepository(ApiClient c) : _dio = c.dio;

  Future<ReferralInfo> getInfo() async {
    final r = await _dio.get('/api/referral');
    return ReferralInfo.fromJson(r.data as Map<String, dynamic>);
  }
}
