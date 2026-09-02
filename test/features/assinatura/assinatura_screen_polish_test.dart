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
    expect(screen, contains('seedFromHome'));
    expect(screen, contains('home.me'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, isNot(contains('ref.watch(planosProvider)')));
    expect(screen, isNot(contains('ref.watch(paywallVitrineProvider)')));

    final repo = File(
      'lib/features/assinatura/data/assinatura_repository.dart',
    ).readAsStringSync();
    expect(repo, contains('/api/planos/paywall/home'));
    expect(repo, contains('getPaywallHome'));
    expect(repo, contains("raw['me']"));
    expect(repo, contains('PlanoFeatures.fromJson'));
    expect(repo, isNot(contains('/api/planos/vitrine')));
    expect(repo, isNot(contains('listarPlanos')));
    expect(repo, isNot(contains('fetchVitrine')));
  });

  test('FREE sem deep link inicia no plano atual (não Premium)', () {
    final screen = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('return currentPlan.apiName;'));
    expect(
      screen,
      isNot(contains('SubscriptionPlan.PRO.apiName')),
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

  test('planos usa compare stage (uma aba, um card)', () {
    final body = File(
      'lib/features/assinatura/screens/assinatura_screen_build_body.part.dart',
    ).readAsStringSync();
    expect(body, contains('FxConversionLockup'));
    expect(body, contains('PaywallCompareStage'));
    expect(body, isNot(contains('PaywallPlanStudio')));
    expect(body, isNot(contains('PaywallRichPlanCard')));

    final components = File(
      'lib/features/planos/paywall/paywall_components.dart',
    ).readAsStringSync();
    expect(components, isNot(contains('paywall_plan_studio')));
    expect(components, isNot(contains('paywall_plan_cards')));
    expect(
      File('lib/features/planos/paywall/paywall_catalog.dart').readAsStringSync(),
      isNot(contains('paywall_plan_sections')),
    );
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
    expect(body, contains('SliverFillRemaining'));
    expect(body, contains('fillViewport: true'));
    expect(body, isNot(contains('TokensStrip.s8 * 3')));

    final stage = File(
      'lib/features/planos/paywall/paywall_compare_stage.dart',
    ).readAsStringSync();
    expect(stage, contains('_PlanTabs'));
    expect(stage, contains('_CompareCard'));
    expect(stage, contains('fillViewport'));
    expect(stage, contains('FocuxHubTypography.sectionTitle'));
    expect(stage, contains('paywallNumberStyle'));
    expect(stage, contains('FocuxHubTypography.kpi'));
    expect(stage, contains('fontWeight: FontWeight.w700'));
    expect(stage, contains('Table('));
    expect(stage, contains('prefersReducedMotion'));
    expect(stage, contains('textAlign: TextAlign.center'));
    expect(stage, isNot(contains('priceLabel')));
    expect(stage, isNot(contains('descriptionForPlan')));

    final price = File(
      'lib/features/planos/paywall/paywall_price.dart',
    ).readAsStringSync();
    expect(price, contains('paywallStickyCtaLabel'));
    expect(price, contains('Fazer upgrade por'));

    final screen = File(
      'lib/features/assinatura/screens/assinatura_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('_enterprisePreviewFootnote'));
    expect(build, contains('paywallStickyCtaLabel'));
    expect(build, contains('Começar \$trialDays dias grátis'));
    expect(build, contains('Confirmar upgrade'));
    expect(build, isNot(contains('— \$selectedLabel')));
    expect(body, isNot(contains('_EnterprisePreviewCard')));
    expect(body, isNot(contains('priceLabel:')));
  });
}
