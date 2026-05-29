import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/landing_default_images.dart';

void main() {
  test('matheus slug resolves ambient hero-5', () {
    expect(
      landingDefaultHeroImageUrl('matheus-focux'),
      contains('/landing/defaults/hero-5.jpg'),
    );
  });

  test('default images use backend static paths', () {
    final hero = landingDefaultHeroImageUrl('matheus-focux');
    expect(hero, contains('/landing/defaults/hero-'));
    expect(hero, startsWith('https://'));
  });

  test('resolve prefers manual url when present', () {
    const manual = 'https://cdn.example.com/foto.jpg';
    expect(
      landingResolvedHeroImageUrl('slug', manual),
      manual,
    );
    expect(
      landingResolvedBioImageUrl('slug', manual),
      manual,
    );
  });

  test('resolve falls back to default when manual empty', () {
    expect(
      landingResolvedHeroImageUrl('outro-slug', ''),
      landingDefaultHeroImageUrl('outro-slug'),
    );
    expect(
      landingResolvedBioImageUrl('outro-slug', null),
      landingDefaultBioImageUrl('outro-slug'),
    );
  });

  test('resolve hero ignores bio when cover empty', () {
    const manualBio = 'https://cdn.example.com/eu.jpg';
    expect(
      landingResolvedHeroImageUrl('slug', ''),
      landingDefaultHeroImageUrl('slug'),
    );
    expect(
      landingResolvedBioImageUrl('slug', manualBio),
      manualBio,
    );
  });

  test('webp urls mirror jpg defaults', () {
    expect(
      landingDefaultHeroWebpUrl('matheus-focux'),
      endsWith('.webp'),
    );
    expect(
      landingDefaultBioWebpUrl('matheus-focux'),
      contains('/landing/defaults/bio-'),
    );
  });
}
