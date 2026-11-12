import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/utils/agenda_display.dart';

Agendamento _ag(int id, String status, DateTime inicio) => Agendamento.fromJson({
  'id': id,
  'alunoId': 1,
  'alunoNome': 'Ana',
  'inicio': inicio.toIso8601String(),
  'fim': inicio.add(const Duration(hours: 1)).toIso8601String(),
  'status': status,
});

void main() {
  final agora = DateTime(2026, 11, 12, 20);

  // Bug de 12/11: sessão cancelada pelo personal virava "Confirmada" no
  // cartão e o "Não vou conseguir ir" falhava.
  test('próxima sessão do cartão ignora cancelada', () {
    final lista = [
      _ag(1, 'CANCELADO', DateTime(2026, 11, 20, 9)),
      _ag(2, 'AGENDADO', DateTime(2026, 11, 27, 9)),
    ];
    expect(agendaAlunoProximaAtiva(lista)?.id, 2);
    expect(agendaAlunoProximaAtiva([lista.first]), isNull);
  });

  test('dia e hora separados para a linha', () {
    final ag = _ag(1, 'AGENDADO', DateTime(2026, 11, 27, 9));
    expect(agendaAlunoSoDia(ag.inicio, now: agora), 'Sex, 27 nov');
    expect(agendaAlunoHorario(ag), '09:00–10:00');
  });

  test('status no feminino (sessão)', () {
    expect(agendaAlunoStatusSessao('AGENDADO'), 'Agendada');
    expect(agendaAlunoStatusSessao('CONFIRMADO'), 'Confirmada');
    expect(agendaAlunoStatusSessao('CANCELADO'), 'Cancelada');
  });
}
