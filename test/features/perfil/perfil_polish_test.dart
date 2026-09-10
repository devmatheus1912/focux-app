import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('perfil usa polish: a11y, acentos e contraste', () {
    final screen = readScreenSourceBundle(
      'lib/features/perfil/screens/perfil_screen.dart',
    );
    final conta = File(
      'lib/features/perfil/widgets/perfil_conta_seguranca_section.dart',
    ).readAsStringSync();

    expect(screen, contains('Semantics('));
    expect(screen, contains('semanticsLabel:'));
    expect(screen, contains('_PerfilVitrineTiles'));
    expect(screen, contains("label: 'Link público'"));
    expect(screen, isNot(contains("child: const Text('Copiar link')")));
    expect(screen, isNot(contains("label: 'Copiar link'")));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('PerfilMarcaVitrineSection'));
    expect(screen, isNot(contains('_HeroMarcaChip')));
    expect(screen, isNot(contains('_PlanPill')));
    expect(screen, isNot(contains('_BrandPreview')));
    expect(screen, isNot(contains('PerfilProfessionalSummary')));
    expect(screen, isNot(contains('ref.watch(dashboardProvider)')));
    expect(screen, contains('FxSettingsLayout.profileName'));
    expect(screen, contains('FxSettingsLayout.rowMetric'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('PerfilAppearanceSection'));
    expect(screen, contains('PerfilOperacaoSection'));
    expect(screen, contains('PerfilContaSegurancaSection'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(
      File('lib/core/widgets/fx_settings_tile.dart').readAsStringSync(),
      contains('BrandPalette.softened'),
    );
    expect(screen, contains('if (!profileComplete)'));
    expect(screen, isNot(contains('_PerfilGrowthSection')));
    expect(conta, contains('Conta e segurança'));
    expect(screen, isNot(contains('PerfilQuietCollapsible')));
    expect(screen, isNot(contains('PerfilCardSection')));
    expect(
      File('lib/features/perfil/widgets/perfil_quiet_collapsible.dart')
          .existsSync(),
      isFalse,
    );
    expect(
      File('lib/features/perfil/widgets/perfil_card_section.dart').existsSync(),
      isFalse,
    );
    expect(screen, isNot(contains('ShellThemeToggle')));
    expect(screen, isNot(contains('_PerfilBottomActions')));
    expect(screen, isNot(contains('Conta e plano')));
    expect(screen, isNot(contains('Nao informado')));
    expect(
      File('lib/features/perfil/utils/perfil_plan_labels.dart')
          .readAsStringSync(),
      isNot(contains('perfilPlanSectionLabel')),
    );
  });
}
