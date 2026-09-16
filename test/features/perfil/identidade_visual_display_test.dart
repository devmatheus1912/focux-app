import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/features/perfil/utils/identidade_visual_display.dart';

void main() {
  test('gate de marca branca usa a feature e cai no plano', () {
    expect(
      identidadeHasWhiteLabel(featureWhiteLabel: true, plano: 'PRO'),
      isTrue,
    );
    expect(
      identidadeHasWhiteLabel(featureWhiteLabel: false, plano: 'ENTERPRISE'),
      isFalse,
    );
    expect(
      identidadeHasWhiteLabel(featureWhiteLabel: null, plano: 'enterprise_pro'),
      isTrue,
    );
    expect(
      identidadeHasWhiteLabel(featureWhiteLabel: null, plano: 'PRO'),
      isFalse,
    );
  });

  test('copy da identidade confirma save, restore e logo', () {
    expect(identidadeSalvarLabel(isSetup: true), 'Finalizar configuração');
    expect(identidadeSalvarLabel(isSetup: false), 'Salvar marca');
    expect(
      identidadeSalvarConfirmMessage(),
      contains('app do personal e do aluno'),
    );
    expect(identidadeRestaurarConfirmTitle(), contains('cores padrão'));
    expect(identidadeLogoConfirmMessage(), contains('rascunho'));
    expect(identidadeHelpSubtitle(), contains('Editar perfil'));
    expect(identidadeLogoSloganSubtitle(), contains('home do aluno'));
    expect(identidadePaletteSubtitle(), contains('login é sempre escuro'));
    expect(identidadeLightPreviewLabel(), 'Modo claro');
    expect(identidadeDarkPreviewLabel(), contains('Modo escuro'));
    expect(identidadeAlunoVisibilityLabel(), contains('aluno'));
    expect(identidadeDiscardTitle(), 'Sair sem salvar?');
  });

  test('dirty e freshness da identidade', () {
    expect(
      identidadeIsDirty(
        perfilLoaded: false,
        slogan: 'a',
        baselineSlogan: 'b',
        logoUrl: null,
        baselineLogo: null,
        palette: CuratedBrandPalette.focuxDefault,
        baselinePalette: CuratedBrandPalette.focuxDefault,
      ),
      isFalse,
    );
    expect(
      identidadeIsDirty(
        perfilLoaded: true,
        slogan: 'novo',
        baselineSlogan: 'velho',
        logoUrl: null,
        baselineLogo: null,
        palette: CuratedBrandPalette.focuxDefault,
        baselinePalette: CuratedBrandPalette.focuxDefault,
      ),
      isTrue,
    );
    expect(identidadeHeroAnimDuration(reduceMotion: true), Duration.zero);
    expect(
      identidadeHeroAnimDuration(reduceMotion: false).inMilliseconds,
      greaterThan(0),
    );
    final now = DateTime(2026, 9, 14, 12);
    expect(
      identidadeAppBarSubtitle(
        hasWhiteLabel: true,
        fetchedAt: now.subtract(const Duration(seconds: 5)),
        now: now,
      ),
      'Sua marca no app · Atualizado agora',
    );
  });
}
