import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/checkin_resumo.dart';

void main() {
  test('execução lê o campo parcial do servidor (padrão falso)', () {
    final base = {
      'id': 1,
      'treinoId': 2,
      'treinoNome': 'A',
      'status': 'CONCLUIDO',
    };
    expect(ExecucaoTreino.fromJson(base).parcial, isFalse);
    expect(ExecucaoTreino.fromJson({...base, 'parcial': true}).parcial, isTrue);
  });

  test('o servidor decide; sem ele vale a regra de 50%', () {
    const completo = CheckinResumo(
      treinoNome: 'A',
      seriesFeitas: 10,
      seriesPlanejadas: 12,
    );
    const pouco = CheckinResumo(
      treinoNome: 'A',
      seriesFeitas: 1,
      seriesPlanejadas: 16,
    );
    const servidor = CheckinResumo(
      treinoNome: 'A',
      seriesFeitas: 10,
      seriesPlanejadas: 12,
      parcialDoServidor: true,
    );
    expect(completo.parcial, isFalse);
    expect(pouco.parcial, isTrue);
    expect(servidor.parcial, isTrue);
  });
}
