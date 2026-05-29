import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/landing_default_images.dart';

void main() {
  test('matheus slug resolves ambient hero-5', () {
    expect(
      landingDefaultHeroImageUrl('matheus-focux'),
      contains('/landing/defaults/hero-5.jpg'),
    );
  });

  test('default hero uses backend static paths', () {
    final hero = landingDefaultHeroImageUrl('matheus-focux');
    expect(hero, contains('/landing/defaults/hero-'));
    expect(hero, startsWith('https://'));
  });

  test('resolve prefers manual url when present', () {
    const manual = 'https://cdn.example.com/foto.jpg';
    const profile = 'https://cdn.example.com/perfil.jpg';
    expect(landingResolvedHeroImageUrl('slug', manual), manual);
    expect(
      landingResolvedBioImageUrl('slug', manual, profile),
      manual,
    );
  });

  test('bio without manual uses profile photo', () {
    const profile = 'https://cdn.example.com/perfil.jpg';
    expect(
      landingResolvedBioImageUrl('outro-slug', null, profile),
      profile,
    );
    expect(
      landingBioEditorPreviewUrl(profile, 'outro-slug'),
      profile,
    );
  });

  test('bio without manual or profile uses stock fallback', () {
    expect(
      landingResolvedBioImageUrl('outro-slug', null, null),
      landingFallbackBioImageUrl('outro-slug'),
    );
    expect(
      landingBioEditorPreviewUrl(null, 'outro-slug'),
      landingFallbackBioImageUrl('outro-slug'),
    );
  });

  test('hero never uses bio or profile urls', () {
    const manualBio = 'https://cdn.example.com/eu.jpg';
    const profile = 'https://cdn.example.com/perfil.jpg';
    expect(
      landingResolvedHeroImageUrl('slug', ''),
      landingDefaultHeroImageUrl('slug'),
    );
    expect(
      landingResolvedBioImageUrl('slug', manualBio, profile),
      manualBio,
    );
  });

  test('webp urls mirror jpg defaults', () {
    expect(landingDefaultHeroWebpUrl('matheus-focux'), endsWith('.webp'));
    expect(
      landingFallbackBioWebpUrl('matheus-focux'),
      contains('/landing/defaults/bio-'),
    );
  });
}
