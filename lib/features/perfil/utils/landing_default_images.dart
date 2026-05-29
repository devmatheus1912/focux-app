/// Fotos padrão de academia — mesma lógica do backend, servidas pelo backend.
library;

import '../../../core/config/env.dart';

const _heroCount = 6;
const _bioCount = 6;
const _heroPool = [1, 4, 2, 0, 3, 5];

String landingDefaultHeroImageUrl(String? slug) =>
    '${Env.apiUrl}${_defaultHeroPath(slug)}';

String landingDefaultBioImageUrl(String? slug) =>
    '${Env.apiUrl}${_defaultBioPath(slug)}';

String landingDefaultHeroWebpUrl(String? slug) =>
    landingDefaultHeroImageUrl(slug).replaceAll(RegExp(r'\.jpe?g$'), '.webp');

String landingDefaultBioWebpUrl(String? slug) =>
    landingDefaultBioImageUrl(slug).replaceAll(RegExp(r'\.jpe?g$'), '.webp');

String landingResolvedHeroImageUrl(String? slug, String? manualUrl) {
  if (manualUrl != null && manualUrl.trim().isNotEmpty) {
    return manualUrl.trim();
  }
  return landingDefaultHeroImageUrl(slug);
}

String landingResolvedBioImageUrl(String? slug, String? manualUrl) {
  if (manualUrl != null && manualUrl.trim().isNotEmpty) {
    return manualUrl.trim();
  }
  return landingDefaultBioImageUrl(slug);
}

bool landingUsesDefaultHeroImage(String? manualUrl) =>
    manualUrl == null || manualUrl.isEmpty;

bool landingUsesDefaultBioImage(String? manualUrl) =>
    manualUrl == null || manualUrl.isEmpty;

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
