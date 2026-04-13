import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Convite {
  final String token;
  final String link;

  Convite({required this.token, required this.link});

  factory Convite.fromJson(Map<String, dynamic> json) => Convite(
        token: json['token'] as String,
        link: json['link'] as String,
      );
}

class ConviteRepository {
  final Dio _dio;

  ConviteRepository(ApiClient client) : _dio = client.dio;

  Future<Convite> gerar() async {
    final response = await _dio.post('/api/convites/gerar');
    return Convite.fromJson(response.data as Map<String, dynamic>);
  }
}
