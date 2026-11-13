import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_personal_display.dart';
import 'package:focux_app/features/checkin/models/checkin_personal_home.dart';

void main() {
  CheckinPersonalItem item({required int alunoId, required String nome}) {
    return CheckinPersonalItem(
      id: alunoId,
      alunoId: alunoId,
      alunoNome: nome,
      treinoNome: 'Full',
    );
  }

  test('aluno com vários treinos aparece uma vez', () {
    final grupos = checkinPorAluno([
      item(alunoId: 1, nome: 'Ana'),
      item(alunoId: 1, nome: 'Ana'),
      item(alunoId: 2, nome: 'Beto'),
    ]);
    expect(grupos.map((g) => g.alunoNome), ['Ana', 'Beto']);
    expect(checkinDoAlunoLinha(grupos.first), '2 treinos · Full');
    expect(checkinDoAlunoLinha(grupos.last), 'Full');
  });

  test('SPEC 12/11: "1 parcial" no singular com vários treinos', () {
    final grupos = checkinPorAluno([
      const CheckinPersonalItem(
        id: 1,
        alunoId: 1,
        alunoNome: 'Ana',
        treinoNome: 'A',
        parcial: true,
      ),
      const CheckinPersonalItem(
        id: 2,
        alunoId: 1,
        alunoNome: 'Ana',
        treinoNome: 'B',
      ),
    ]);
    expect(checkinDoAlunoLinha(grupos.single), '2 treinos · A, B · 1 parcial');
    expect(grupos.single.itens, hasLength(2));
  });

  test('hora no grupo do dia; "há N min" só na última hora de hoje', () {
    final now = DateTime(2026, 11, 12, 18, 53);
    expect(
      checkinHoraLinha(DateTime(2026, 11, 12, 18, 48), now: now),
      'há 5 min',
    );
    expect(checkinHoraLinha(DateTime(2026, 11, 12, 9, 5), now: now), '09:05');
    expect(checkinHoraLinha(DateTime(2026, 11, 9, 20, 10), now: now), '20:10');
  });

  test('folha dos 6 dias sem os de hoje, com a contagem do que mostra', () {
    final now = DateTime(2026, 11, 12, 18);
    final itens = [
      CheckinPersonalItem(
        id: 1,
        alunoId: 1,
        alunoNome: 'Ana',
        treinoNome: 'A',
        iniciadoEm: DateTime(2026, 11, 12, 8),
      ),
      CheckinPersonalItem(
        id: 2,
        alunoId: 1,
        alunoNome: 'Ana',
        treinoNome: 'B',
        iniciadoEm: DateTime(2026, 11, 11, 8),
      ),
    ];
    expect(checkinSemHoje(itens, now: now).map((i) => i.id), [2]);
    expect(checkinSemanaContagem(1), '1 treino nos últimos 6 dias');
    expect(checkinHojeTitulo(3), 'Hoje · 3 treinos');
  });
}
