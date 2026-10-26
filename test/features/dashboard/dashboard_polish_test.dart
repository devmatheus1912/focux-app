import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard feature não usa fontSize 18/19/20/22 soltos', () {
    final root = Directory('lib/features/dashboard');
    final forbidden = RegExp(r'fontSize:\s*(18|19|20|22)\b');
    final offenders = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}:${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use FocuxHubTypography (pageTitle/sectionTitle/metricEm/metricLg). '
          'Offenders:\n${offenders.join('\n')}',
    );
  });

  test('dashboard feature não usa AppTypography.inter ad-hoc', () {
    final root = Directory('lib/features/dashboard');
    final offenders = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains('AppTypography.inter')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('dashboard hoje usa microcopy, contraste e a11y', () {
    const paths = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/dashboard/screens/personal_dashboard_screen_build.part.dart',
      'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
      'lib/features/dashboard/widgets/hoje_agora_secao.dart',
      'lib/features/dashboard/widgets/hoje_base_secao.dart',
      'lib/features/dashboard/utils/hoje_agora.dart',
      'lib/features/dashboard/widgets/dashboard_agenda_hoje_strip.dart',
      'lib/features/dashboard/widgets/dashboard_finance_empty.dart',
      'lib/features/dashboard/widgets/dashboard_home_primary_slivers.dart',
      'lib/features/dashboard/widgets/dashboard_shimmer_loading.dart',
      'lib/features/dashboard/utils/dashboard_microcopy.dart',
      'lib/features/dashboard/utils/dashboard_command_copy.dart',
      'lib/features/dashboard/utils/dashboard_next_actions.dart',
      'lib/features/dashboard/widgets/dashboard_home_header.dart',
      'lib/features/dashboard/widgets/dashboard_section_header.dart',
      'lib/features/dashboard/utils/dashboard_a11y.dart',
      'lib/features/dashboard/utils/dashboard_home_snapshot.dart',
      'lib/features/dashboard/utils/dashboard_readability.dart',
    ];
    final screen = paths.map((p) => File(p).readAsStringSync()).join('\n');

    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, contains('HojeAgoraSecao'));
    expect(screen, contains('hojeAgora('));
    expect(screen, contains('FxActionRow'));
    expect(screen, contains('FxMetricStrip'));
    expect(screen, contains('/alunos?filtro=risco'));
    expect(screen, contains('BrandPalette.sectionLink'));
    expect(screen, contains('dashboardReadableMuted'));
    expect(screen, contains('RISK_STUDENTS'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxHelpChrome.iconSize'));
    expect(screen, contains('alunoFromAlertaResumo'));
    expect(screen, contains('onboardingFromHome'));
    expect(screen, contains('statusFromHome: onboardingFromHome'));
    expect(screen, isNot(contains('onboardingStatusProvider')));
    expect(screen, isNot(contains('DraggableScrollableSheet(')));
    expect(screen, isNot(contains('showHojePersonalPainel')));
    expect(screen, isNot(contains('showDashboardToolsCatalogSheet')));
    expect(screen, isNot(contains('ShellThemeToggle')));
    expect(screen, isNot(contains('retornoRapido')));
    expect(screen, isNot(contains('DashboardRoiQuickLinksRow')));
    final shortcutsFile =
        File(
          'lib/features/dashboard/data/dashboard_tool_shortcuts.dart',
        ).readAsStringSync();
    expect(shortcutsFile, isNot(contains('roiQuickLinks')));
    expect(shortcutsFile, isNot(contains("label: 'Preços'")));
    expect(shortcutsFile, isNot(contains('static const List')));
    expect(shortcutsFile, contains('fromEntrada'));
    expect(shortcutsFile, contains('atalhosHomeFromCatalogo'));

    final semanticsCount = 'Semantics('.allMatches(screen).length;
    expect(semanticsCount, greaterThanOrEqualTo(4));
  });

  test('Ferramentas é lista inset agrupada por tarefa', () {
    final tela = File(
      'lib/features/ferramentas/screens/ferramentas_screen.dart',
    ).readAsStringSync();
    final group = File(
      'lib/features/dashboard/widgets/dashboard_tool_shortcut_group.dart',
    ).readAsStringSync();
    expect(tela, contains('DashboardToolShortcutGroup'));
    expect(tela, contains('ListView.separated'));
    expect(tela, contains('groupCatalogoHubs'));
    expect(tela, contains('agruparFerramentas'));
    expect(tela, contains('ferramentasCatalogoProvider'));
    expect(tela, contains('fxScreenA11yScope'));
    expect(tela, isNot(contains('ExpansionTile')));
    expect(tela, isNot(contains('DashboardExpandableToolGroups')));
    expect(tela, isNot(contains('FxHomeSheetHandle')));
    expect(tela, isNot(contains('nome antigo')));
    expect(group, contains('FxSettingsTile'));
    expect(group, contains('FxSettingsGroup'));
    expect(group, contains('dashboardShortcutSemanticsLabel'));
  });

  test('alerta de ativação da Home é faixa inset abaixo do Olá', () {
    final setup = File(
      'lib/features/onboarding/screens/setup_onboarding_widget.dart',
    ).readAsStringSync();
    final cta = File(
      'lib/features/subscription/widgets/dashboard_activation_cta.dart',
    ).readAsStringSync();
    final strip = File(
      'lib/features/dashboard/widgets/dashboard_home_activation_strip.dart',
    ).readAsStringSync();
    final slivers = File(
      'lib/features/dashboard/widgets/dashboard_home_primary_slivers.dart',
    ).readAsStringSync();
    expect(setup, contains('Sua ativação'));
    expect(setup, contains('DashboardHomeActivationStrip'));
    expect(setup, isNot(contains('dashboardSetupPreview')));
    expect(setup, isNot(contains('Ver tudo')));
    expect(setup, isNot(contains('SetupStepCard')));
    expect(setup, isNot(contains('SetupProgressHeader')));
    expect(cta, contains('DashboardHomeActivationStrip'));
    expect(cta, contains('DashboardLayout.foldCard'));
    expect(cta, isNot(contains('TokensStrip.s5')));
    expect(strip, contains('FxSettingsLayout.rowMinHeight'));
    expect(strip, contains('minHeight: 3'));
    expect(strip, contains('fxStripCardDecoration'));
    expect(
      slivers.indexOf('DashboardHomeHeader'),
      lessThan(slivers.indexOf('SetupOnboardingWidget')),
    );
    final primeiraTela = slivers.split('return [').last;
    expect(primeiraTela, contains('HojeAgoraSecao'));
    expect(primeiraTela, contains('TrialCountdownBanner'));
    expect(
      primeiraTela.indexOf('TrialCountdownBanner'),
      lessThan(primeiraTela.indexOf('HojeAgoraSecao')),
    );
    expect(primeiraTela, contains('SetupOnboardingWidget'));
  });

  test('Home opera o dia em métrica e satellite', () {
    final finance = File(
      'lib/features/dashboard/widgets/dashboard_finance_empty.dart',
    ).readAsStringSync();
    expect(finance, contains('OperationalMetricTile'));
    expect(finance, isNot(contains('FxActionChip')));
  });
}
