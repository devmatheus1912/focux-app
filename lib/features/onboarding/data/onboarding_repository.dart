import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'onboarding_status_data.dart';

class OnboardingRepository {
  final Dio _dio;

  OnboardingRepository(ApiClient client) : _dio = client.dio;

  Future<OnboardingStatusData> getStatus() async {
    final response = await _dio.get('/api/onboarding/status');
    return OnboardingStatusData.fromJson(response.data as Map<String, dynamic>);
  }
}
