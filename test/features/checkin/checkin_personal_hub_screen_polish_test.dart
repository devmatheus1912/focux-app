import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('hub de check-in do personal cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/checkin_personal_hub_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('checkinFocusAction'));
    expect(screen, contains('showCheckinPersonalCatalogSheet'));
    expect(
      File(
        'lib/features/checkin/widgets/checkin_personal_help_sheet.dart',
      ).readAsStringSync(),
      contains('Como calculamos'),
    );
    expect(
      File(
        'lib/features/checkin/widgets/checkin_personal_catalog_sheet.dart',
      ).readAsStringSync(),
      allOf(contains('Carregar mais'), contains('onTapOutside')),
    );
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('take(3)'));
    expect(screen, contains('Ver todos'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('FxSettingsGroupedList')));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('checkinHubViewed'));
    expect(screen, contains('Cobrar treino'));
    expect(screen, contains('pendentes'));
    expect(screen, isNot(contains('/checkin/executar')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
