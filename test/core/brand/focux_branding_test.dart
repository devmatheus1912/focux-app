import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_branding.dart';

void main() {
  test('FocuxBranding catalog lists personality modes', () {
    expect(FocuxBranding.personalityPersonal, 'personal');
    expect(FocuxBranding.personalityAluno, 'aluno');
    expect(FocuxBranding.version, isNotEmpty);
  });

  test('white-label detection combines hide flag and plan gate', () {
    expect(
      FocuxBranding.isWhiteLabelActive(
        hideFocuxBranding: true,
        whiteLabelActive: false,
      ),
      isTrue,
    );
    expect(
      FocuxBranding.isWhiteLabelActive(
        hideFocuxBranding: false,
        whiteLabelActive: true,
      ),
      isTrue,
    );
    expect(
      FocuxBranding.isWhiteLabelActive(
        hideFocuxBranding: false,
        whiteLabelActive: false,
      ),
      isFalse,
    );
  });

  test('branding sources and tagline widget exist', () {
    for (final path in FocuxBranding.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }

    final tagline =
        File('lib/core/widgets/focux_brand_tagline.dart').readAsStringSync();
    expect(tagline, contains('FocuxBrandCopy'));

    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('primaryColorProvider'));
    expect(main, contains('hideFocuxBrandingProvider'));
  });

  test('curated palettes validate readable primaries', () {
    final curated =
        File('lib/core/theme/curated_brand_palettes.dart').readAsStringSync();
    expect(curated, contains('isReadablePrimary'));
  });
}
