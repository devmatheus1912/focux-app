import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/analytics/data/analytics_repository.dart';

void main() {
  test('first paint do Analytics só documenta getDashboard', () {
    final provider =
        File(
          'lib/features/analytics/providers/analytics_provider.dart',
        ).readAsStringSync();
    final repo =
        File(
          'lib/features/analytics/data/analytics_repository.dart',
        ).readAsStringSync();

    expect(provider, contains('getDashboard()'));
    expect(provider, isNot(contains('Future.wait')));
    expect(provider, isNot(contains('getWau')));
    expect(provider, isNot(contains('getCohort')));

    expect(repo, contains("'/api/analytics/home'"));
    expect(repo, contains('Future<AnalyticsDashboard> getDashboard()'));
    expect(repo, contains('AnalyticsDashboard.fromJson'));
    expect(repo, isNot(contains('getWau')));
    expect(repo, isNot(contains('getCohort')));
    expect(repo, isNot(contains('getFunil')));
    expect(repo, isNot(contains("'/api/analytics/wau'")));
    expect(repo, isNot(contains("'/api/analytics/funil'")));
  });

  test('AnalyticsDashboard.fromJson já traz evolucaoWau e cohort', () {
    final dashboard = AnalyticsDashboard.fromJson({
      'totalAlunos': 10,
      'inadimplentes': 1,
      'wau': 7,
      'mau': 9,
      'taxaInadimplencia': 10.0,
      'retencaoD7': 80.0,
      'retencaoD30': 60.0,
      'evolucaoWau': [
        {'semana': '2026-W32', 'usuarios': 5},
      ],
      'cohort': [
        {
          'mesEntrada': '2026-07',
          'cadastrados': 4,
          'ativosD7': 3,
          'ativosD30': 2,
          'retencaoD7': 75.0,
          'retencaoD30': 50.0,
        },
      ],
    });

    expect(dashboard.wau, 7);
    expect(dashboard.evolucaoWau, hasLength(1));
    expect(dashboard.evolucaoWau.first.semana, '2026-W32');
    expect(dashboard.evolucaoWau.first.usuarios, 5);
    expect(dashboard.cohort, hasLength(1));
    expect(dashboard.cohort.first.mesEntrada, '2026-07');
    expect(dashboard.cohort.first.retencaoD30, 50.0);
  });

  test('AnalyticsDashboard.fromJson tolera evolucaoWau e cohort ausentes', () {
    final dashboard = AnalyticsDashboard.fromJson({
      'totalAlunos': 2,
      'inadimplentes': 0,
      'wau': 1,
      'mau': 2,
      'taxaInadimplencia': 0.0,
      'retencaoD7': 0.0,
      'retencaoD30': 0.0,
    });

    expect(dashboard.evolucaoWau, isEmpty);
    expect(dashboard.cohort, isEmpty);
  });
}
