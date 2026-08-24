import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('assinatura cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/assinatura/screens/assinatura_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });

  test('assinatura first paint usa paywall/home (não dual GET)', () {
    final screen = readScreenSourceBundle(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    );
    expect(screen, contains('paywallHomeProvider'));
    expect(screen, contains('ref.watch(paywallHomeProvider)'));
    expect(screen, isNot(contains('ref.watch(planosProvider)')));
    expect(screen, isNot(contains('ref.watch(paywallVitrineProvider)')));

    final repo = File(
      'lib/features/assinatura/data/assinatura_repository.dart',
    ).readAsStringSync();
    expect(repo, contains('/api/planos/paywall/home'));
    expect(repo, contains('getPaywallHome'));
  });

  test('FREE sem deep link inicia no plano atual (não Premium)', () {
    final screen = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('return currentPlan.apiName;'));
    expect(
      screen,
      isNot(contains('SubscriptionPlan.PREMIUM.apiName')),
    );
  });

  test('fx shell expande body quando sticky footer presente', () {
    final shell = File('lib/core/widgets/fx_shell_scaffold.dart').readAsStringSync();
    expect(shell, contains('SizedBox.expand'));
    expect(shell, isNot(contains('FxPremiumEntrance(child: inner)')));
  });

  test('content width limiter preenche altura bounded do scaffold', () {
    final limiter = File(
      'lib/core/widgets/fx_content_width_limiter.dart',
    ).readAsStringSync();
    expect(limiter, contains('fillHeight'));
    expect(limiter, contains('constraints.maxHeight'));
    expect(limiter, contains('LayoutBuilder'));
    expect(limiter, contains('mainAxisAlignment: MainAxisAlignment.center'));
    expect(limiter, isNot(contains('Alignment.topCenter')));
  });

  test('plan studio cai para aquisicao quando upgradePlans vazio', () {
    final body = File(
      'lib/features/assinatura/screens/assinatura_screen_build_body.part.dart',
    ).readAsStringSync();
    expect(body, contains('upgradePlansForStudio.isNotEmpty'));
  });

  test('assinatura sticky e scroll respeitam reduced motion e refresh', () {
    final build = File(
      'lib/features/assinatura/screens/assinatura_screen_build.part.dart',
    ).readAsStringSync();
    expect(build, contains('FxContentWidthLimiter'));
    expect(build, contains('expandHeight: false'));
    expect(build, contains('AnimatedSwitcher'));
    expect(build, contains('Continuar no FREE'));
    expect(build, contains('Compras bloqueadas no aparelho'));

    final body = File(
      'lib/features/assinatura/screens/assinatura_screen_build_body.part.dart',
    ).readAsStringSync();
    expect(body, contains('RefreshIndicator'));
    expect(body, contains('AlwaysScrollableScrollPhysics'));
    expect(body, contains('228.0'));

    final priceBox = File(
      'lib/features/planos/paywall/paywall_plan_cards_enterprise.part.dart',
    ).readAsStringSync();
    expect(priceBox, contains('FittedBox'));
    expect(priceBox, contains('maxLines: 1'));
    expect(priceBox, contains('FocuxHubTypography.metricEm'));

    final cards = File(
      'lib/features/planos/paywall/paywall_plan_cards.part.dart',
    ).readAsStringSync();
    expect(cards, contains('headerPill'));
    expect(cards, isNot(contains('Positioned(')));
  });
}
