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

  /// Retorna estado completo quando o BE envelopa; senão só o [LandingGerado].
  Future<LandingStudioState> gerar() async {
    final r = await _dio.post('/api/personal/landing/gerar');
    final data = r.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('entrevista') ||
          data.containsKey('publicado') ||
          data.containsKey('publicUrl') ||
          data.containsKey('podePublicar')) {
        return LandingStudioState.fromJson(data);
      }
      final geradoMap = data['gerado'];
      if (geradoMap is Map) {
        final gerado = LandingGerado.fromJson(
          Map<String, dynamic>.from(geradoMap),
        );
        return LandingStudioState(
          gerado: gerado,
          needsProof: data['needsProof'] as bool? ?? gerado.needsProof,
          podePublicar:
              data['podePublicar'] as bool? ?? gerado.hasPublishableCopy,
        );
      }
      if (data.containsKey('heroTitle')) {
        final gerado = LandingGerado.fromJson(data);
        return LandingStudioState(
          gerado: gerado,
          needsProof: gerado.needsProof,
          podePublicar: gerado.hasPublishableCopy,
        );
      }
    }
    return const LandingStudioState();
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

  Future<String> previewHtml() async {
    final r = await _dio.get('/api/personal/landing/preview');
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
