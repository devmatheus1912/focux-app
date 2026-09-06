import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_home_client_cache.dart';

void main() {
  tearDown(EvolucaoHomeClientCache.clear);

  test('parses additive evolucaoHome with same shape as /evolucao/home', () {
    final parsed = Aluno360Ferramentas.fromJson({
      'hasWearableHistory': true,
      'evolucaoHome': {
        'medidas': [
          {
            'id': 9,
            'data': '2026-09-01',
            'peso': 78.5,
            'cintura': 84.0,
            'quadril': 98.0,
            'braco': 34.0,
          },
        ],
        'recordes': [
          {
            'id': 3,
            'exercicioId': 12,
            'exercicioNome': 'Supino',
            'data': '2026-08-20',
            'cargaKg': 80.0,
            'repeticoes': 5,
          },
        ],
      },
    });

    expect(parsed.hasWearableHistory, isTrue);
    expect(parsed.evolucaoHome, isNotNull);
    expect(parsed.evolucaoHome!.medidas, hasLength(1));
    expect(parsed.evolucaoHome!.medidas.first.peso, 78.5);
    expect(parsed.evolucaoHome!.recordes, hasLength(1));
    expect(parsed.evolucaoHome!.recordes.first.exercicioNome, 'Supino');
  });

  test('tolerates missing evolucaoHome for older backends', () {
    final parsed = Aluno360Ferramentas.fromJson({
      'hasWearableHistory': false,
    });
    expect(parsed.evolucaoHome, isNull);
  });

  test('hydrate puts evolucaoHome into Medidas cache', () {
    final bundle = Aluno360Ferramentas.fromJson({
      'evolucaoHome': {
        'medidas': [
          {'id': 1, 'data': '2026-09-01', 'peso': 70.0},
        ],
        'recordes': <Map<String, dynamic>>[],
      },
    });
    EvolucaoHomeClientCache.put(42, bundle.evolucaoHome!);
    expect(EvolucaoHomeClientCache.getIfFresh(42), same(bundle.evolucaoHome));
  });
}
