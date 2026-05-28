/// Fotos padrão de academia — mesma lógica do backend, servidas pelo backend.
library;

import '../../../core/config/env.dart';

const _heroCount = 6;
const _bioCount = 6;

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
    '/landing/defaults/hero-${_pickIndex(slug, 'hero', _heroCount)}.jpg';

String _defaultBioPath(String? slug) =>
    '/landing/defaults/bio-${_pickIndex(slug, 'bio', _bioCount)}.jpg';

int _pickIndex(String? slug, String salt, int poolSize) {
  final key = (slug != null && slug.trim().isNotEmpty)
      ? slug.trim().toLowerCase()
      : 'focux';
  return ('$key:$salt').hashCode.abs() % poolSize;
}
