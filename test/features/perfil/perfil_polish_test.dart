
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('perfil usa polish: a11y, acentos e contraste', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/perfil_screen.dart',
    );

    expect(screen, contains('BrandPalette.deep(primaryColor)'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('semanticsLabel:'));
    expect(screen, contains('Não informado'));
    expect(screen, contains('Política de privacidade'));
    expect(screen, contains('Migração Focux'));
    expect(screen, contains('_PerfilPublicLinkCard'));
    expect(screen, contains('Marca e vitrine'));
    expect(screen, contains('Sua vitrine online'));
    expect(screen, contains('_HeroMarcaChip'));
    expect(screen, contains('PerfilProfessionalSummary'));
    expect(screen, contains('_PerfilDebugTools'));
    expect(screen, contains('Mais ferramentas'));
    expect(screen, contains('Operação'));
    expect(screen, contains('GatedProfileShortcuts'));
    expect(screen, contains('FxLiquidSecondaryButton'));
    expect(screen, contains('if (!profileComplete)'));
    expect(screen, isNot(contains('_PerfilGrowthSection')));
    expect(screen, contains('Conta e segurança'));
    expect(screen, isNot(contains('_PerfilBottomActions')));
    expect(screen, isNot(contains('Conta e plano')));
    expect(screen, isNot(contains('Nao informado')));
    expect(screen, isNot(contains('Politica de privacidade')));
  });
}
