import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';

/// Qui e Sex "segue a sequência" mostram a sessão prevista (A, B…), não um
/// texto genérico.
void main() {
  DiaDaSemana dia(int d, [String? nome, int? id]) => DiaDaSemana(
    dia: d,
    sessoes: nome == null ? const [] : [SessaoDaSemana(treinoId: id, nome: nome)],
    segueSequencia: nome == null && d <= 5,
    descanso: nome == null && d > 5,
  );

  test('PPL em 5 dias: Qui = A, Sex = B', () {
    final previstos = nomesDaSequencia([
      dia(1, 'A · Empurrar', 1),
      dia(2, 'B · Puxar', 2),
      dia(3, 'C · Pernas', 3),
      dia(4),
      dia(5),
      dia(6),
      dia(7),
    ]);
    expect(previstos, {4: 'A · Empurrar', 5: 'B · Puxar'});
  });

  test('sem sessões, nada previsto', () {
    expect(nomesDaSequencia([dia(1), dia(2)]), isEmpty);
  });
}
