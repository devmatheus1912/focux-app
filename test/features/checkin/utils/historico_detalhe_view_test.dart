import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/historico_detalhe_texts.dart';
import 'package:focux_app/features/checkin/utils/historico_detalhe_view.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

final _s = SPt();
final _inicio = DateTime(2026, 9, 23, 7);

Map<String, dynamic> _serie(double carga, String reps) => {
  'cargaKg': carga,
  'repeticoes': reps,
};

ExecucaoTreino _execucao({
  String status = 'CONCLUIDO',
  Duration duracao = const Duration(minutes: 48),
  List<Map<String, dynamic>>? exercicios,
  List<Map<String, dynamic>> cargas = const [],
}) => ExecucaoTreino.fromJson({
  'id': 90,
  'treinoId': 1,
  'treinoNome': 'Treino A',
  'status': status,
  'iniciadoEm': _inicio.toIso8601String(),
  if (status == 'CONCLUIDO')
    'concluidoEm': _inicio.add(duracao).toIso8601String(),
  'exercicios':
      exercicios ??
      [
        {
          'exercicioNome': 'Supino',
          'series': 3,
          'seriesFeitas': 3,
          'cargaAnteriorKg': 17.5,
          'rpe': 8,
          'seriesDetalhes': [
            _serie(20, '10'),
            _serie(20, '10'),
            _serie(20, '8'),
          ],
        },
        {
          'exercicioNome': 'Remada',
          'series': 4,
          'seriesFeitas': 1,
          'observacoes': 'Pegada neutra',
          'seriesDetalhes': [_serie(30, '12')],
        },
      ],
  'evolucoesCarga': cargas,
});

void main() {
  setUpAll(() => GlobalMaterialLocalizations.delegate.load(const Locale('pt')));

  test('sem evolução do servidor, os números saem das séries', () {
    final v = buildHistoricoDetalheView(_execucao());

    expect(v.concluida, isTrue);
    expect(v.duracao, const Duration(minutes: 48));
    expect(v.seriesFeitas, 4);
    expect(v.seriesPlanejadas, 7);
    expect(v.exerciciosFeitos, 1);
    expect(v.exerciciosTotal, 2);
    expect(v.volumeKg, 20 * 28 + 30 * 12);
    expect(v.comparacao, isNull);
    expect(v.recordes, isEmpty);
    expect(v.notas, [(exercicio: 'Remada', nota: 'Pegada neutra')]);
  });

  test('evolução do servidor manda no volume, séries e comparação', () {
    final v = buildHistoricoDetalheView(
      _execucao(),
      evolucao: SessaoEvolucaoDto.fromJson({
        'volumeKg': 3200.0,
        'seriesFeitas': 5,
        'seriesPlanejadas': 8,
        'sinal': 'MELHOROU',
        'destaqueExercicio': 'Supino',
        'destaqueDeltaKg': 2.5,
      }),
    );

    expect(v.volumeKg, 3200);
    expect(v.seriesFeitas, 5);
    expect(v.seriesPlanejadas, 8);
    expect(
      historicoComparacaoTexto(_s, v.comparacao),
      'Volume acima da sessão anterior',
    );
    expect(
      historicoDestaqueTexto(_s, v),
      'Supino: +2,5 kg vs a sessão anterior',
    );
    expect(historicoKgTexto(_s, v.volumeKg!), '3,2 mil kg');
  });

  test('"Já fiz": concluído sem séries, sem volume nem duração', () {
    final v = buildHistoricoDetalheView(
      _execucao(
        duracao: const Duration(seconds: 1),
        exercicios: [
          {'exercicioNome': 'Supino', 'series': 3},
        ],
      ),
    );

    expect(v.semSeries, isTrue);
    expect(v.volumeKg, isNull);
    expect(v.duracao, isNull);
    expect(historicoDetalheStatus(_s, v), 'Concluído sem séries');
    expect(
      historicoNDeMTexto(_s, v.seriesFeitas, v.seriesPlanejadas),
      '0 de 3',
    );
    expect(historicoExercicioDetalhe(_s, v.exercicios.single), 'Sem séries');
  });

  test('linha do exercício junta carga, séries, RPE e diferença', () {
    final v = buildHistoricoDetalheView(_execucao());

    expect(
      historicoExercicioDetalhe(_s, v.exercicios.first),
      '20 kg · 3 de 3 séries · RPE 8 · +2,5 kg vs anterior',
    );
    expect(v.exercicios.first.cargas, [20, 20, 20]);
    expect(
      historicoExercicioDetalhe(_s, v.exercicios.last),
      '30 kg · 1 de 4 séries',
    );
  });

  test('recorde usa a mensagem do servidor; sem ela, a carga', () {
    final v = buildHistoricoDetalheView(
      _execucao(
        cargas: [
          {'exercicioNome': 'Supino', 'cargaAtualKg': 20.0, 'mensagem': ''},
          {
            'exercicioNome': 'Remada',
            'cargaAtualKg': 30.0,
            'mensagem': 'Novo recorde de carga',
          },
        ],
      ),
    );

    expect(historicoRecordeDetalhe(_s, v.recordes.first), '20 kg');
    expect(
      historicoRecordeDetalhe(_s, v.recordes.last),
      'Novo recorde de carga',
    );
  });

  test('subtítulo: data de conclusão ou em andamento', () {
    final feita = buildHistoricoDetalheView(_execucao());
    final aberta = buildHistoricoDetalheView(_execucao(status: 'EM_ANDAMENTO'));

    expect(historicoDetalheSubtitulo(_s, feita), startsWith('Concluído · '));
    expect(historicoDetalheSubtitulo(_s, feita), contains('23'));
    expect(historicoDetalheSubtitulo(_s, aberta), 'Em andamento');
    expect(aberta.duracao, isNull);
  });

  test('rota do detalhe', () {
    expect(historicoDetalhePath(90), '/checkin/historico/90');
  });
}
