/// Fotos padrão de academia — mesma lógica do backend, estáveis por slug.
library;

const _heroGymUrls = [
  'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1200&h=800&q=80',
  'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?auto=format&fit=crop&w=1200&h=800&q=80',
  'https://images.unsplash.com/photo-1517836357463-d06dfbcf1320?auto=format&fit=crop&w=1200&h=800&q=80',
  'https://images.unsplash.com/photo-1540497077202-7be8ccc4f1ee?auto=format&fit=crop&w=1200&h=800&q=80',
  'https://images.unsplash.com/photo-1583454110551-21f2f2b7bd1c?auto=format&fit=crop&w=1200&h=800&q=80',
  'https://images.unsplash.com/photo-1599058945522-28d584b6f35f?auto=format&fit=crop&w=1200&h=800&q=80',
];

const _bioGymUrls = [
  'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&h=720&q=80',
  'https://images.unsplash.com/photo-1594381898411-8e15a7c96fde?auto=format&fit=crop&w=600&h=720&q=80',
  'https://images.unsplash.com/photo-1581009146145-b5ef050c1499?auto=format&fit=crop&w=600&h=720&q=80',
  'https://images.unsplash.com/photo-1549060275-4a3c0a3a7a7b?auto=format&fit=crop&w=600&h=720&q=80',
  'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&h=720&q=80',
  'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=600&h=720&q=80',
];

String landingDefaultHeroImageUrl(String? slug) =>
    _pick(_heroGymUrls, slug, 'hero');

String landingDefaultBioImageUrl(String? slug) =>
    _pick(_bioGymUrls, slug, 'bio');

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

String _pick(List<String> pool, String? slug, String salt) {
  if (pool.isEmpty) return '';
  final key = (slug != null && slug.trim().isNotEmpty)
      ? slug.trim().toLowerCase()
      : 'focux';
  final index = ('$key:$salt').hashCode.abs() % pool.length;
  return pool[index];
}
