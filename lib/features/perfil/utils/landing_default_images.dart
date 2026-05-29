/// Contrato de imagens da landing — espelha o backend Java.
library;

import '../../../core/config/env.dart';

const _heroCount = 6;
const _bioCount = 6;
const _heroPool = [1, 4, 2, 0, 3, 5];

/// Capa hero stock premium (academia) — nunca foto de perfil/bio.
String landingDefaultHeroImageUrl(String? slug) =>
    '${Env.apiUrl}${_defaultHeroPath(slug)}';

/// Silhueta stock — só quando não há foto de perfil.
String landingFallbackBioImageUrl(String? slug) =>
    '${Env.apiUrl}${_defaultBioPath(slug)}';

String landingDefaultHeroWebpUrl(String? slug) =>
    landingDefaultHeroImageUrl(slug).replaceAll(RegExp(r'\.jpe?g$'), '.webp');

String landingFallbackBioWebpUrl(String? slug) =>
    landingFallbackBioImageUrl(slug).replaceAll(RegExp(r'\.jpe?g$'), '.webp');

String landingResolvedHeroImageUrl(String? slug, String? manualUrl) {
  if (manualUrl != null && manualUrl.trim().isNotEmpty) {
    return manualUrl.trim();
  }
  return landingDefaultHeroImageUrl(slug);
}

/// Bio: override landing → foto de perfil → stock fallback.
String landingResolvedBioImageUrl(
  String? slug,
  String? manualBioUrl,
  String? profilePhotoUrl,
) {
  if (manualBioUrl != null && manualBioUrl.trim().isNotEmpty) {
    return manualBioUrl.trim();
  }
  if (profilePhotoUrl != null && profilePhotoUrl.trim().isNotEmpty) {
    return profilePhotoUrl.trim();
  }
  return landingFallbackBioImageUrl(slug);
}

/// Preview no editor quando bio landing não foi customizada.
String landingBioEditorPreviewUrl(String? profilePhotoUrl, String? slug) {
  if (profilePhotoUrl != null && profilePhotoUrl.trim().isNotEmpty) {
    return profilePhotoUrl.trim();
  }
  return landingFallbackBioImageUrl(slug);
}

bool landingUsesDefaultHeroImage(String? manualUrl) =>
    manualUrl == null || manualUrl.isEmpty;

/// `true` quando não há override — exibe foto de perfil ou fallback stock.
bool landingUsesDefaultBioImage(String? manualBioUrl) =>
    manualBioUrl == null || manualBioUrl.isEmpty;

String _defaultHeroPath(String? slug) =>
    '/landing/defaults/hero-${_heroPool[_pickIndex(slug, 'hero', _heroCount)]}.jpg';

String _defaultBioPath(String? slug) =>
    '/landing/defaults/bio-${_pickIndex(slug, 'bio', _bioCount)}.jpg';

int _pickIndex(String? slug, String salt, int poolSize) {
  final key = (slug != null && slug.trim().isNotEmpty)
      ? slug.trim().toLowerCase()
      : 'focux';
  return _floorMod(_javaHashCode('$key:$salt'), poolSize);
}

/// Espelha `String.hashCode()` + `Math.floorMod` do backend Java.
int _javaHashCode(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) | 0;
  }
  return hash;
}

int _floorMod(int value, int size) {
  final mod = value % size;
  return mod < 0 ? mod + size : mod;
}
