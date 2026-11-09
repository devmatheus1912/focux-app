import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_grafico_linha.dart';
import 'package:focux_app/features/alunos/utils/aluno360_medida_plausivel.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_series.dart';

/// "Está certo" no Confira (SPEC-confira-evolucao).
void main() {
  final pontos = [
    PontoGrafico(DateTime(2026, 10, 31), 90),
    PontoGrafico(DateTime(2026, 11, 9), 120),
  ];

  test('salto de 30 kg em 9 dias pede Confira; conferido não pede mais', () {
    expect(pontosSuspeitos(pontos, 'kg'), {1});
    expect(pontosSuspeitos(pontos, 'kg', conferidas: {'2026-11-09'}), isEmpty);
  });

  test('datas conferidas vêm da medida e da avaliação', () {
    final datas = datasConferidas(
      [
        MedidaCorporal(id: 1, data: '2026-11-09', peso: 120, conferidoEm: '2026-11-09T10:00'),
        MedidaCorporal(id: 2, data: '2026-10-31', peso: 90),
      ],
      massa: [(data: '2026-11-04', valor: 85, avaliacaoId: 7, conferido: true)],
    );
    expect(datas, {'2026-11-09', '2026-11-04'});
  });

  test('gordura e massa magra acima de 105% avisam; 100% e 73% não', () {
    expect(
      medidasSuspeitas(gordura: 40, massaMagra: 80),
      contains('Gordura e massa magra somam 120,0%'),
    );
    expect(medidasSuspeitas(gordura: 15, massaMagra: 85), isEmpty);
    expect(medidasSuspeitas(gordura: 18, massaMagra: 55), isEmpty);
  });
}
