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
}
