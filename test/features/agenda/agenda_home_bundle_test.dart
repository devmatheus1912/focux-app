import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';

void main() {
  Map<String, dynamic> agJson({
    required int id,
    required String inicio,
    required String fim,
    String nome = 'Ana',
  }) => {
    'id': id,
    'alunoId': 2,
    'alunoNome': nome,
    'inicio': inicio,
    'fim': fim,
    'titulo': 'Treino',
    'status': 'AGENDADO',
  };

  test('AgendaHomeBundle parses proximos and semana', () {
    final bundle = AgendaHomeBundle.fromJson({
      'proximos': [
        agJson(
          id: 1,
          inicio: '2026-08-17T10:00:00',
          fim: '2026-08-17T11:00:00',
        ),
      ],
      'semana': [
        agJson(
          id: 2,
          inicio: '2026-08-16T08:00:00',
          fim: '2026-08-16T09:00:00',
          nome: 'Bia',
        ),
      ],
    });
    expect(bundle.proximos, hasLength(1));
    expect(bundle.proximos.first.alunoNome, 'Ana');
    expect(bundle.semana, hasLength(1));
    expect(bundle.semana.first.alunoNome, 'Bia');
    expect(bundle.firstPaintItems.map((a) => a.id), [2, 1]);
  });

  test('AgendaHomeBundle firstPaintItems dedupes overlapping ids', () {
    final bundle = AgendaHomeBundle.fromJson({
      'proximos': [
        agJson(
          id: 1,
          inicio: '2026-08-17T10:00:00',
          fim: '2026-08-17T11:00:00',
        ),
      ],
      'semana': [
        agJson(
          id: 1,
          inicio: '2026-08-17T10:00:00',
          fim: '2026-08-17T11:00:00',
        ),
      ],
    });
    expect(bundle.firstPaintItems, hasLength(1));
  });
}
