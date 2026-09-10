import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../../core/legal/focux_legal.dart';

class LgpdConsent {
  const LgpdConsent({
    required this.tipo,
    required this.versao,
    required this.aceitoEm,
  });

  final String tipo;
  final String versao;
  final String aceitoEm;

  factory LgpdConsent.fromJson(Map<String, dynamic> json) {
    return LgpdConsent(
      tipo: (json['tipo'] as String? ?? '').toUpperCase(),
      versao: json['versao'] as String? ?? '',
      aceitoEm: json['aceitoEm'] as String? ?? '',
    );
  }
}

class LgpdConsentRepository {
  LgpdConsentRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  /// Último consentimento do titular, ou `null` se ainda não houver.
  Future<LgpdConsent?> ultimo() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/lgpd/me/consent',
      );
      final data = response.data;
      if (data == null) return null;
      return LgpdConsent.fromJson(data);
    } catch (error) {
      final api = ApiError.from(error);
      if (api?.status == 404) return null;
      rethrow;
    }
  }

  Future<LgpdConsent> registrar({
    required String tipo,
    String versao = FocuxLegal.consentDocumentVersion,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/lgpd/me/consent',
      data: {'tipo': tipo.toUpperCase(), 'versao': versao},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('POST /api/lgpd/me/consent sem corpo');
    }
    return LgpdConsent.fromJson(data);
  }
}
