import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import 'perfil_repository.dart';

class LandingNichePreset {
  final String id;
  final String label;
  final String heroTitle;
  final String heroSubtitle;
  final String bioText;
  final String primaryCta;
  final String offerCta;
  final String finalCta;
  final String contactCta;
  final List<LandingServiceItem> servicos;
  final List<LandingFaqItem> faq;
  final List<String> sectionOrder;

  LandingNichePreset({
    required this.id,
    required this.label,
    required this.heroTitle,
    required this.heroSubtitle,
    this.bioText = '',
    required this.primaryCta,
    this.offerCta = '',
    this.finalCta = '',
    this.contactCta = '',
    this.servicos = const [],
    this.faq = const [],
    this.sectionOrder = const [],
  });

  factory LandingNichePreset.fromJson(
    Map<String, dynamic> j,
  ) => LandingNichePreset(
    id: j['id'] as String? ?? '',
    label: j['label'] as String? ?? '',
    heroTitle: j['heroTitle'] as String? ?? '',
    heroSubtitle: j['heroSubtitle'] as String? ?? '',
    bioText: j['bioText'] as String? ?? '',
    primaryCta: j['primaryCta'] as String? ?? '',
    offerCta: j['offerCta'] as String? ?? '',
    finalCta: j['finalCta'] as String? ?? '',
    contactCta: j['contactCta'] as String? ?? '',
    servicos:
        (j['servicos'] as List<dynamic>? ?? [])
            .map((e) => LandingServiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
    faq:
        (j['faq'] as List<dynamic>? ?? [])
            .map((e) => LandingFaqItem.fromJson(e as Map<String, dynamic>))
            .toList(),
    sectionOrder: (j['sectionOrder'] as List<dynamic>? ?? []).cast<String>(),
  );
}

class LandingHeroCopy {
  final String heroTitle;
  final String heroSubtitle;
  final String primaryCta;

  LandingHeroCopy({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.primaryCta,
  });

  factory LandingHeroCopy.fromJson(Map<String, dynamic> j) => LandingHeroCopy(
    heroTitle: j['heroTitle'] as String? ?? '',
    heroSubtitle: j['heroSubtitle'] as String? ?? '',
    primaryCta: j['primaryCta'] as String? ?? '',
  );
}

class LandingChecklistItem {
  final String id;
  final String label;
  final bool done;

  LandingChecklistItem({
    required this.id,
    required this.label,
    required this.done,
  });

  factory LandingChecklistItem.fromJson(Map<String, dynamic> j) =>
      LandingChecklistItem(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}

class LandingGrowthRepository {
  LandingGrowthRepository(this._dio);

  final dynamic _dio;

  Future<List<LandingNichePreset>> presets() async {
    final r = await _dio.get('/api/personal/landing/presets');
    return (r.data as List<dynamic>)
        .map((e) => LandingNichePreset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> applyPreset(String presetId) async {
    await _dio.post(
      '/api/personal/landing/aplicar-preset',
      data: {'presetId': presetId},
    );
  }

  Future<LandingHeroCopy> generateHero() async {
    final r = await _dio.post('/api/personal/landing/gerar-hero');
    return LandingHeroCopy.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<LandingChecklistItem>> checklist() async {
    final r = await _dio.get('/api/personal/landing/checklist');
    final data = r.data as Map<String, dynamic>;
    return (data['checklist'] as List<dynamic>? ?? [])
        .map((e) => LandingChecklistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final landingGrowthRepositoryProvider = Provider<LandingGrowthRepository>((
  ref,
) {
  return LandingGrowthRepository(ref.read(apiClientProvider).dio);
});
