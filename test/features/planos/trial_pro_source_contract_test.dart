import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final fontes = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('l10n${Platform.pathSeparator}app_localizations'))
      .map((f) => (f.path.replaceAll('\\', '/'), f.readAsStringSync()))
      .toList();

  test('trial de 30 dias é do PRO: nada de trial Enterprise no app', () {
    for (final (path, src) in fontes) {
      for (final proibido in [
        'kPaywallMaxPlanTrialDays',
        'paywallShowsMaxPlanTrial',
        'EnterprisePromo',
        'enterprisePromo',
        'Trial Enterprise',
      ]) {
        expect(src, isNot(contains(proibido)), reason: '$path contém $proibido');
      }
    }
  });

  test('/promo-enterprise só sobrevive como redirect', () {
    final comRota =
        fontes.where((f) => f.$2.contains("'/promo-enterprise'")).map((f) => f.$1).toList();
    expect(comRota.toSet(), {
      'lib/core/router/app_router_chrome_routes.dart',
      'lib/core/design_system/focux_surfaces_catalog.dart',
    });
    final catalogo = File('lib/core/design_system/focux_surfaces_catalog.dart').readAsStringSync();
    expect(
      RegExp(r"'/promo-enterprise': FocuxSurfaceSpec\([^)]*redirectTo: '/promo-pro'").hasMatch(catalogo),
      isTrue,
    );
    final rotas = File('lib/core/router/app_router_chrome_routes.dart').readAsStringSync();
    expect(
      RegExp(r"path: '/promo-enterprise',\s+redirect: \(context, state\) => '/promo-pro',")
          .hasMatch(rotas),
      isTrue,
    );
  });

  test('banner do teste usa o plano atual, não texto fixo', () {
    final banner =
        File('lib/features/subscription/widgets/trial_countdown_banner.dart').readAsStringSync();
    expect(banner, contains('PaywallCatalog.displayPlanName(trial.planoAtual)'));
    expect(banner, contains("'Teste \$plano"));
  });
}
