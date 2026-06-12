/// Catálogo de branding — identidade white-label, paleta e personalidade.
abstract final class FocuxBranding {
  FocuxBranding._();

  static const String version = '1.0.0';

  /// Tom de produto para personal trainer.
  static const String personalityPersonal = 'personal';

  /// Tom de produto para aluno.
  static const String personalityAluno = 'aluno';

  static const List<String> coreSources = [
    'lib/core/brand/focux_branding.dart',
    'lib/core/brand/focux_brand_copy.dart',
    'lib/core/theme/brand_palette.dart',
    'lib/core/theme/curated_brand_palettes.dart',
    'lib/core/widgets/focux_brand_tagline.dart',
    'lib/core/theme/theme_provider.dart',
    'lib/core/providers/personal_brand_provider.dart',
    'lib/main.dart',
  ];

  static const List<String> hubBrandingPatterns = [
    'BrandPalette',
    'ShellChrome',
    'colorScheme.primary',
    'FxShellScaffold',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/branding_personality_pillar_contract_test.dart',
    'test/core/design_system/colors_contrast_pillar_contract_test.dart',
    'test/core/design_system/microcopy_pillar_contract_test.dart',
    'test/core/brand/focux_brand_copy_test.dart',
    'test/core/theme/curated_brand_palettes_test.dart',
  ];

  static bool isWhiteLabelActive({
    required bool hideFocuxBranding,
    required bool whiteLabelActive,
  }) =>
      hideFocuxBranding || whiteLabelActive;
}
