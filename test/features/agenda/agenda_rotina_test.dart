import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/utils/agenda_schedule.dart';
import 'package:focux_app/features/agenda/utils/agenda_slots.dart';
import 'package:focux_app/features/agenda/utils/agenda_status.dart';

Agendamento _ag({String status = 'AGENDADO', String? atendimento}) =>
    Agendamento.fromJson({
      'id': 1,
      'alunoId': 2,
      'alunoNome': 'Julio Cesar',
      'inicio': '2026-10-30T09:00:00',
      'fim': '2026-10-30T10:00:00',
      'status': status,
      'statusAtendimento': atendimento,
    });

void main() {
  test('repetição mantém dia da semana e hora', () {
    final datas = agendaDatasRepetidas(DateTime(2026, 10, 31, 8, 30), 4);
    expect(datas, hasLength(4));
    expect(datas.last, DateTime(2026, 11, 21, 8, 30));
    expect(agendaDatasRepetidas(DateTime(2026, 10, 31, 8), 0), hasLength(1));
  });

  test('período do horário', () {
    expect(agendaPeriodoDe(DateTime(2026, 1, 1, 11, 30)), AgendaPeriodo.manha);
    expect(agendaPeriodoDe(DateTime(2026, 1, 1, 12)), AgendaPeriodo.tarde);
    expect(agendaPeriodoDe(DateTime(2026, 1, 1, 18)), AgendaPeriodo.noite);
  });

  test('presença só depois do fim e uma vez', () {
    final depois = DateTime(2026, 10, 30, 11);
    expect(agendaPrecisaPresenca(_ag(), now: depois), isTrue);
    expect(agendaPrecisaPresenca(_ag(), now: DateTime(2026, 10, 30, 9, 30)), isFalse);
    expect(agendaPrecisaPresenca(_ag(atendimento: 'FALTA'), now: depois), isFalse);
    expect(agendaPrecisaPresenca(_ag(status: 'CANCELADO'), now: depois), isFalse);
  });

  test('botão diz quem e quando', () {
    expect(agendaNovoBotaoLabel(), 'Agendar atendimento');
    expect(
      agendaNovoBotaoLabel(
        alunoNome: 'Julio Cesar',
        inicio: DateTime(2026, 10, 31, 8, 30),
      ),
      'Agendar Julio · sáb, 31 out, 08:30',
    );
  });
}
