import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

class WhiteLabelConfig {
  final String? slug;
  final String? appDisplayName;
  final bool ocultarMarcaFocux;
  final String? dominioCustomizado;
  final bool dominioVerificado;
  final String? dominioVerificacaoToken;
  final String dnsInstrucoes;
  final String landingModo;
  final String publicLandingUrl;
  final String publicCapturaUrl;
  final List<WhiteLabelChecklistItem> checklist;
  final int checklistScore;

  WhiteLabelConfig({
    this.slug,
    this.appDisplayName,
    this.ocultarMarcaFocux = false,
    this.dominioCustomizado,
    this.dominioVerificado = false,
    this.dominioVerificacaoToken,
    this.dnsInstrucoes = '',
    this.landingModo = 'CAPTURA',
    this.publicLandingUrl = '',
    this.publicCapturaUrl = '',
    this.checklist = const [],
    this.checklistScore = 0,
  });

  factory WhiteLabelConfig.fromJson(Map<String, dynamic> j) => WhiteLabelConfig(
    slug: j['slug'] as String?,
    appDisplayName: j['appDisplayName'] as String?,
    ocultarMarcaFocux: j['ocultarMarcaFocux'] as bool? ?? false,
    dominioCustomizado: j['dominioCustomizado'] as String?,
    dominioVerificado: j['dominioVerificado'] as bool? ?? false,
    dominioVerificacaoToken: j['dominioVerificacaoToken'] as String?,
    dnsInstrucoes: j['dnsInstrucoes'] as String? ?? '',
    landingModo: j['landingModo'] as String? ?? 'CAPTURA',
    publicLandingUrl: j['publicLandingUrl'] as String? ?? '',
    publicCapturaUrl: j['publicCapturaUrl'] as String? ?? '',
    checklist: (j['checklist'] as List<dynamic>? ?? [])
        .map((e) => WhiteLabelChecklistItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    checklistScore: j['checklistScore'] as int? ?? 0,
  );
}

class WhiteLabelChecklistItem {
  final String id;
  final String label;
  final bool done;

  WhiteLabelChecklistItem({
    required this.id,
    required this.label,
    required this.done,
  });

  factory WhiteLabelChecklistItem.fromJson(Map<String, dynamic> j) =>
      WhiteLabelChecklistItem(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}

class WhiteLabelRepository {
  WhiteLabelRepository(this._dio);

  final dynamic _dio;

  Future<WhiteLabelConfig> fetch() async {
    final r = await _dio.get('/api/personal/white-label');
    return WhiteLabelConfig.fromJson(r.data as Map<String, dynamic>);
  }

  Future<WhiteLabelConfig> save({
    String? appDisplayName,
    bool? ocultarMarcaFocux,
    String? dominioCustomizado,
    String? landingModo,
  }) async {
    final body = <String, dynamic>{};
    if (appDisplayName != null) body['appDisplayName'] = appDisplayName;
    if (ocultarMarcaFocux != null) body['ocultarMarcaFocux'] = ocultarMarcaFocux;
    if (dominioCustomizado != null) body['dominioCustomizado'] = dominioCustomizado;
    if (landingModo != null) body['landingModo'] = landingModo;
    final r = await _dio.put('/api/personal/white-label', data: body);
    return WhiteLabelConfig.fromJson(r.data as Map<String, dynamic>);
  }

  Future<WhiteLabelConfig> verifyDomain() async {
    final r = await _dio.post('/api/personal/white-label/verificar-dominio');
    return WhiteLabelConfig.fromJson(r.data as Map<String, dynamic>);
  }
}

final whiteLabelRepositoryProvider = Provider<WhiteLabelRepository>((ref) {
  return WhiteLabelRepository(ApiClient().dio);
});

final whiteLabelConfigProvider = FutureProvider.autoDispose<WhiteLabelConfig>((
  ref,
) async {
  return ref.read(whiteLabelRepositoryProvider).fetch();
});
