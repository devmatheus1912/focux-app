import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';

void main() {
  test('frase de reserva do servidor não é sugestão', () {
    const padrao = ProximaAcaoResumo(acao: 'Revisar o perfil', motivo: 'x', fonte: 'PADRAO', prioridade: 'P3');
    const real = ProximaAcaoResumo(acao: 'Retomar contato', motivo: 'x', fonte: 'IA', prioridade: 'P1');
    expect(padrao.ehPadrao, isTrue);
    expect(real.ehPadrao, isFalse);
  });
}
