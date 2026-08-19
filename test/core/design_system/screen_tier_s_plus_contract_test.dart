import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Tier S+ gate — every production feature screen meets hub-quality baseline.
void main() {
  const allowedWithoutLimiter = {
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/checkin/screens/modo_presencial_screen.dart',
    'lib/features/checkin/screens/checkin_screen.dart',
    'lib/features/checkin/screens/meus_treinos_screen.dart',
    'lib/features/checkin/screens/historico_screen.dart',
    'lib/features/auth/screens/splash_screen.dart',
    'lib/features/auth/screens/login_screen.dart',
    'lib/features/auth/screens/register_screen.dart',
    'lib/features/auth/screens/register_aluno_screen.dart',
    'lib/features/auth/screens/esqueci_senha_screen.dart',
    'lib/features/auth/screens/resetar_senha_screen.dart',
    'lib/features/auth/screens/definir_senha_aluno_screen.dart',
  };

  const excluded = {
    'lib/features/qa/screens/qa_smoke_screen.dart',
    'lib/features/qa/screens/tokens_strip_showcase_screen.dart',
  };

  test('every feature screen meets Tier S+ baseline', () {
    final screens =
        Directory('lib/features')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('_screen.dart'))
            .toList();

    final failures = <String>[];

    for (final file in screens) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (excluded.contains(norm)) continue;

      final mainSource = file.readAsStringSync();
      final source = readScreenSourceBundle(norm);

      if (!source.contains('fxScreenA11yScope') &&
          !source.contains('Semantics(')) {
        failures.add('$norm: sem root a11y');
      }
      if (source.contains('CircularProgressIndicator')) {
        failures.add('$norm: CircularProgressIndicator proibido');
      }
      final rawListTile =
          source.contains('ListTile(') &&
          !source.contains('CheckboxListTile') &&
          !source.contains('SwitchListTile') &&
          !source.contains('RadioListTile') &&
          !source.contains('FxSatelliteListTile') &&
          !source.contains('fxListTileCardShell');
      if (rawListTile &&
          !source.contains('showModalBottomSheet') &&
          !source.contains('showFxHomeSheet') &&
          !source.contains('showFxBottomSheet')) {
        failures.add('$norm: ListTile cru (use FxSatelliteListTile)');
      }

      final isAsync =
          source.contains('.when(') ||
          source.contains('FutureProvider') ||
          source.contains('AsyncValue') ||
          source.contains('_loading');

      if (isAsync) {
        final hasErrorUx =
            source.contains('friendlyError') ||
            source.contains('DashboardErrorState') ||
            source.contains('FxEmptyState') ||
            source.contains('_erro') ||
            source.contains('_erroIaTexto') ||
            source.contains('_TrainingEmptyState') ||
            source.contains('ref.invalidate');
        final hasLoadingUx =
            source.contains('FxLoading') ||
            source.contains('SkeletonLoader') ||
            source.contains('SkeletonList') ||
            source.contains('DashboardShimmer') ||
            source.contains('Shimmer') ||
            source.contains('IaCopilotInsightsLoading') ||
            source.contains('_loading');
        if (!hasErrorUx) failures.add('$norm: async sem estado de erro');
        if (!hasLoadingUx) failures.add('$norm: async sem loading DS');
      }

      if (source.contains('FxShellScaffold') &&
          !allowedWithoutLimiter.contains(norm)) {
        final hasLimiter =
            source.contains('FxContentWidthLimiter') ||
            !source.contains('constrainWidth: false');
        if (!hasLimiter) {
          failures.add('$norm: FxShellScaffold sem width constraint');
        }
      }

      final colorHits = 'Colors.'.allMatches(mainSource).length;
      if (colorHits > 16) {
        failures.add('$norm: $colorHits usos de Colors. (max 16)');
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'Telas fora do Tier S+:\n${failures.join('\n')}',
    );
  });
}
