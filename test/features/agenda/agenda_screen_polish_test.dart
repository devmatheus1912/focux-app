import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('agenda cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/agenda_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('friendlyError'),
        contains('DashboardErrorState'),
        contains('FxEmptyState'),
        contains('_erro'),
        contains('_TrainingEmptyState'),
        contains('ref.invalidate'),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('FxLoading'),
        contains('SkeletonLoader'),
        contains('SkeletonList'),
        contains('DashboardShimmer'),
        contains('Shimmer'),
        contains('IaCopilotInsightsLoading'),
        contains('_loading'),
      ),
    );
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('agenda usa estados canônicos da Home', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/agenda_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('AgendaDayEmptyPanel'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, isNot(contains('class _AgendaEmptyState')));
    expect(
      File('lib/features/agenda/screens/agenda_screen.dart').readAsStringSync(),
      isNot(contains('ref.watch(alunosProvider)')),
    );
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, contains('onNew:'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(
      File('lib/features/agenda/widgets/agenda_help_sheet.dart')
          .readAsStringSync(),
      contains('Como calculamos'),
    );
    expect(
      File('lib/features/agenda/screens/agenda_screen.dart').readAsStringSync(),
      isNot(contains('FxSettingsGroup')),
    );
  });

  test('excluir, confirmar e remarcar tratam falha com erro, não sucesso', () {
    final actions = File(
      'lib/features/agenda/screens/agenda_screen_actions.part.dart',
    ).readAsStringSync();
    for (final key in [
      'agendaExcluirFalhou',
      'agendaStatusFalhou',
      'agendaRemarcarFalhou',
    ]) {
      expect(actions, contains('S.of(context).$key'));
    }
    final delete = actions.substring(actions.indexOf('onDelete:'));
    expect(
      delete.indexOf('catch (e)'),
      lessThan(delete.indexOf("showSuccess(context, 'Agendamento excluído.')")),
    );
  });

  test('validação do novo agendamento não usa estilo de sucesso', () {
    final novo = File(
      'lib/features/agenda/screens/novo_agendamento_screen.dart',
    ).readAsStringSync();
    final salvar = novo.substring(
      novo.indexOf('Future<void> _salvar()'),
      novo.indexOf('showFxConfirmSheet(', novo.indexOf('Future<void> _salvar()')),
    );
    expect(salvar, isNot(contains('showSuccess')));
  });
}
