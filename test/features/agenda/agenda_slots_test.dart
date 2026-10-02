import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_novo_args.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/utils/agenda_day_lane.dart';
import 'package:focux_app/features/agenda/utils/agenda_slots.dart';

Agendamento _ag({
  int id = 1,
  required DateTime inicio,
  int minutos = 60,
  String status = 'AGENDADO',
  String nome = 'Nathalia Souza',
}) {
  return Agendamento(
    id: id,
    alunoId: 1,
    alunoNome: nome,
    inicio: inicio,
    fim: inicio.add(Duration(minutes: minutos)),
    status: status,
  );
}

DioException _http(int status, Map<String, dynamic> data) {
  final options = RequestOptions(path: '/api/agenda');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  final dia = DateTime(2026, 11, 20);
  final nathalia = _ag(inicio: DateTime(2026, 11, 20, 15));

  test('grade vai de 06:00 a 22:30 de 30 em 30', () {
    final slots = agendaSlotsDoDia(dia);
    expect(slots.first, DateTime(2026, 11, 20, 6));
    expect(slots.last, DateTime(2026, 11, 20, 22, 30));
    expect(slots.length, 34);
  });

  test('ocupado quando o período cruza outro atendimento', () {
    expect(
      agendaSlotConflict(DateTime(2026, 11, 20, 14, 30), 60, [nathalia]),
      nathalia,
    );
    expect(
      agendaSlotConflict(DateTime(2026, 11, 20, 15, 30), 30, [nathalia]),
      nathalia,
    );
  });

  test('encostar no início ou no fim não conflita', () {
    expect(
      agendaSlotConflict(DateTime(2026, 11, 20, 14), 60, [nathalia]),
      isNull,
    );
    expect(
      agendaSlotConflict(DateTime(2026, 11, 20, 16), 90, [nathalia]),
      isNull,
    );
  });

  test('cancelado e o próprio horário remarcado não ocupam', () {
    final cancelado = _ag(
      id: 2,
      inicio: DateTime(2026, 11, 20, 15),
      status: 'CANCELADO',
    );
    expect(
      agendaSlotConflict(DateTime(2026, 11, 20, 15), 60, [cancelado]),
      isNull,
    );
    expect(
      agendaSlotConflict(DateTime(2026, 11, 20, 15), 60, [
        nathalia,
      ], excludeId: nathalia.id),
      isNull,
    );
  });

  test('fim não passa das 23:59', () {
    expect(agendaSlotFitsDay(DateTime(2026, 11, 20, 22, 30), 60), isTrue);
    expect(agendaSlotFitsDay(DateTime(2026, 11, 20, 22, 30), 90), isFalse);
  });

  test('mensagem de conflito usa o primeiro nome', () {
    expect(
      agendaConflitoMensagem(nathalia),
      'Horário ocupado: Nathalia 15:00–16:00.',
    );
  });

  test('rótulos e chips de duração', () {
    expect(agendaDuracaoLabel(30), '30 min');
    expect(agendaDuracaoLabel(60), '1h');
    expect(agendaDuracaoLabel(90), '1h30');
    expect(agendaDuracoesCom(60), [30, 45, 60, 90]);
    expect(agendaDuracoesCom(120), [30, 45, 60, 90, 120]);
  });

  test('próximo slot arredonda para cima em 30 min', () {
    expect(
      agendaProximoSlot(DateTime(2026, 11, 20, 10, 5)),
      DateTime(2026, 11, 20, 10, 30),
    );
    expect(
      agendaProximoSlot(DateTime(2026, 11, 20, 10, 40)),
      DateTime(2026, 11, 20, 11),
    );
    expect(
      agendaProximoSlot(DateTime(2026, 11, 20, 10, 30)),
      DateTime(2026, 11, 20, 10, 30),
    );
  });

  group('encaixe de lacuna', () {
    final now = DateTime(2026, 11, 20, 10, 10);

    test('lacuna futura encaixa até 60 min', () {
      final seed = agendaGapSeed(
        AgendaLaneGap(
          from: DateTime(2026, 11, 20, 12),
          to: DateTime(2026, 11, 20, 14),
        ),
        now: now,
      );
      expect(seed?.inicio, DateTime(2026, 11, 20, 12));
      expect(seed?.duracaoMin, 60);
    });

    test('lacuna curta usa a maior duração que cabe', () {
      final seed = agendaGapSeed(
        AgendaLaneGap(
          from: DateTime(2026, 11, 20, 12),
          to: DateTime(2026, 11, 20, 12, 50),
        ),
        now: now,
      );
      expect(seed?.duracaoMin, 45);
    });

    test('lacuna fora da grade começa no slot seguinte', () {
      final seed = agendaGapSeed(
        AgendaLaneGap(
          from: DateTime(2026, 11, 20, 10, 45),
          to: DateTime(2026, 11, 20, 12),
        ),
        now: now,
      );
      expect(seed?.inicio, DateTime(2026, 11, 20, 11));
      expect(seed?.duracaoMin, 60);
    });

    test('lacuna de 20 min não encaixa', () {
      expect(
        agendaGapSeed(
          AgendaLaneGap(
            from: DateTime(2026, 11, 20, 12),
            to: DateTime(2026, 11, 20, 12, 20),
          ),
          now: now,
        ),
        isNull,
      );
    });

    test('lacuna em andamento começa no próximo slot', () {
      final seed = agendaGapSeed(
        AgendaLaneGap(
          from: DateTime(2026, 11, 20, 9),
          to: DateTime(2026, 11, 20, 11, 30),
        ),
        now: now,
      );
      expect(seed?.inicio, DateTime(2026, 11, 20, 10, 30));
      expect(seed?.duracaoMin, 60);
    });

    test('lacuna passada não encaixa', () {
      expect(
        agendaGapSeed(
          AgendaLaneGap(
            from: DateTime(2026, 11, 20, 8),
            to: DateTime(2026, 11, 20, 9),
          ),
          now: now,
        ),
        isNull,
      );
    });
  });

  test('validação local barra passado e conflito', () {
    final now = DateTime(2026, 11, 20, 10);
    expect(
      agendaSlotLocalError(DateTime(2026, 11, 20, 9), 60, const [], now: now),
      'Escolha um horário a partir de agora.',
    );
    expect(
      agendaSlotLocalError(DateTime(2026, 11, 20, 15, 30), 60, [
        nathalia,
      ], now: now),
      'Horário ocupado: Nathalia 15:00–16:00.',
    );
    expect(
      agendaSlotLocalError(DateTime(2026, 11, 20, 16), 60, [
        nathalia,
      ], now: now),
      isNull,
    );
  });

  test('erro de horário do servidor traz a mensagem', () {
    final conflito = _http(409, {
      'erro': 'Horário ocupado: Nathalia 15:00–16:00.',
      'codigo': 'AGENDA_CONFLITO',
    });
    expect(agendaIsSlotError(conflito), isTrue);
    expect(
      agendaSlotErrorMessage(conflito),
      'Horário ocupado: Nathalia 15:00–16:00.',
    );
    final passado = _http(400, {'codigo': 'AGENDA_HORARIO_PASSADO'});
    expect(
      agendaSlotErrorMessage(passado),
      'Escolha um horário a partir de agora.',
    );
    expect(agendaIsSlotError(_http(400, {'erro': 'x'})), isFalse);
    expect(agendaSlotErrorMessage(StateError('x')), isNull);
  });

  test('extra antigo com hora vira início sugerido', () {
    final comHora = AgendaNovoArgs.fromSeed(DateTime(2026, 11, 20, 9, 30));
    expect(comHora.inicio, DateTime(2026, 11, 20, 9, 30));
    final soDia = AgendaNovoArgs.fromSeed(DateTime(2026, 11, 20));
    expect(soDia.inicio, isNull);
    expect(soDia.day, DateTime(2026, 11, 20));
  });
}
