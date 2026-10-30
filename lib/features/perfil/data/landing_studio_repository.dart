import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import 'landing_studio_models.dart';

export 'landing_studio_models.dart';

/// Contrato studio v2 — entrevista → gerar → mídia → publicar.
class LandingStudioRepository {
  LandingStudioRepository(this._dio);

  final dynamic _dio;

  Future<LandingStudioState> getState() async {
    final r = await _dio.get('/api/personal/landing');
    return LandingStudioState.fromJson(r.data as Map<String, dynamic>);
  }

  Future<LandingStudioState> saveEntrevista(LandingEntrevista entrevista) async {
    final r = await _dio.put(
      '/api/personal/landing/entrevista',
      data: entrevista.toJson(),
    );
    final data = r.data;
    if (data is Map<String, dynamic>) {
      return LandingStudioState.fromJson(data);
    }
    return getState();
  }

  /// Textos novos sem gravar: a página no ar não muda.
  Future<LandingGerado> sugerir(LandingEntrevista entrevista) async {
    final r = await _dio.post(
      '/api/personal/landing/sugerir',
      data: entrevista.toJson(),
    );
    return LandingGerado.fromJson(r.data as Map<String, dynamic>);
  }

  Future<LandingMidia> saveMidia({
    String? heroImageUrl,
    String? bioImageUrl,
    String? accentColor,
  }) async {
    final r = await _dio.post(
      '/api/personal/landing/midia',
      data: {
        if (heroImageUrl != null) 'heroImageUrl': heroImageUrl,
        if (bioImageUrl != null) 'bioImageUrl': bioImageUrl,
        if (accentColor != null) 'accentColor': accentColor,
      },
    );
    final data = r.data;
    if (data is Map<String, dynamic>) {
      final midia = data['midia'];
      if (midia is Map) {
        return LandingMidia.fromJson(Map<String, dynamic>.from(midia));
      }
      return LandingMidia.fromJson(data);
    }
    return LandingMidia(
      heroImageUrl: heroImageUrl,
      bioImageUrl: bioImageUrl,
      accentColor: accentColor,
    );
  }

  Future<LandingStudioState> publicar({LandingGerado? gerado}) async {
    final r = await _dio.post(
      '/api/personal/landing/publicar',
      data: gerado == null ? null : {'gerado': gerado.toJson()},
    );
    final data = r.data;
    if (data is Map<String, dynamic>) {
      return LandingStudioState.fromJson(data);
    }
    return getState();
  }

  /// Prévia do que está no editor, sem gravar.
  Future<String> previewHtml({
    required LandingEntrevista entrevista,
    required LandingGerado gerado,
    String? heroImageUrl,
    String? bioImageUrl,
  }) async {
    final r = await _dio.post(
      '/api/personal/landing/preview',
      data: {
        'entrevista': entrevista.toJson(),
        'gerado': gerado.toJson(),
        'heroImageUrl': heroImageUrl,
        'bioImageUrl': bioImageUrl,
      },
    );
    final data = r.data;
    if (data is String) return data;
    if (data is Map && data['html'] is String) return data['html'] as String;
    return data?.toString() ?? '';
  }
}

final landingStudioRepositoryProvider = Provider<LandingStudioRepository>((
  ref,
) {
  return LandingStudioRepository(ref.read(apiClientProvider).dio);
});
