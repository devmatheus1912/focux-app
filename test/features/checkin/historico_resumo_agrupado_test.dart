import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/historico_detalhe_view.dart';

HistoricoExercicioLinha _l(String nome) =>
    HistoricoExercicioLinha(nome: nome, feito: true, seriesFeitas: 1);

void main() {
  test(
    'recordes: um cartão por exercício, sem repetir, com o nome da lista',
    () {
      final g = historicoRecordesPorExercicio(
        [
          (
            exercicio: 'Agachamento com Elástico',
            mensagem: 'Repetições: 8 → 10',
            cargaKg: null,
          ),
          (
            exercicio: 'Agachamento com Elástico',
            mensagem: 'Volume: 160 → 200 kg',
            cargaKg: null,
          ),
          (
            exercicio: 'Agachamento com elástico',
            mensagem: 'Volume: 160 → 200 kg',
            cargaKg: null,
          ),
        ],
        nomesDaLista: ['Agachamento com elástico'],
      );
      expect(g, hasLength(1));
      expect(g.single.exercicio, 'Agachamento com elástico');
      expect(g.single.linhas, ['Repetições: 8 → 10', 'Volume: 160 → 200 kg']);
    },
  );

  test('mesmo exercício duas vezes: o segundo ganha a ordem', () {
    final r = historicoNomesComOrdem([
      _l('Agachamento com elástico'),
      _l('Agachamento com elástico'),
      _l('Afundo'),
    ]);
    expect(r.map((l) => l.nome), [
      'Agachamento com elástico',
      'Agachamento com elástico · 2º',
      'Afundo',
    ]);
  });
}
