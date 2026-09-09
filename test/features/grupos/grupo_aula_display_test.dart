import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/grupos/utils/grupo_aula_display.dart';

void main() {
  test('grupoAulaWhenLabel formata data e hora', () {
    expect(
      grupoAulaWhenLabel(DateTime(2026, 9, 2, 7, 0)),
      '02/09 07:00',
    );
  });

  test('grupoAulaVagasLabel e lotada', () {
    expect(
      grupoAulaVagasLabel(inscritos: 3, capacidadeMax: 20),
      '17 vagas',
    );
    expect(
      grupoAulaVagasLabel(inscritos: 19, capacidadeMax: 20),
      '1 vaga',
    );
    expect(
      grupoAulaVagasLabel(inscritos: 20, capacidadeMax: 20),
      'Lotada',
    );
    expect(grupoAulaLotada(inscritos: 20, capacidadeMax: 20), isTrue);
    expect(grupoAulaLotada(inscritos: 5, capacidadeMax: 20), isFalse);
    expect(grupoAulaFxIcon(inscritos: 20, capacidadeMax: 20), 'alert-triangle');
    expect(grupoAulaFxIcon(inscritos: 5, capacidadeMax: 20), 'calendar');
  });

  test('grupoAulaSubtitle junta local', () {
    expect(
      grupoAulaSubtitle(
        inicio: DateTime(2026, 9, 2, 7, 0),
        localAula: 'Praia',
      ),
      '02/09 07:00 · Praia',
    );
    expect(
      grupoAulaSubtitle(inicio: DateTime(2026, 9, 2, 7, 0), localAula: '  '),
      '02/09 07:00',
    );
  });

  test('grupoAulaCountLabel e filtro', () {
    expect(grupoAulaCountLabel(0), 'Nenhuma aula');
    expect(grupoAulaCountLabel(2), '2 aulas');
    expect(
      grupoAulaMatches(
        titulo: 'Funcional',
        localAula: 'Praia',
        lotada: false,
        query: 'praia',
        chip: GrupoAulaChip.abertas,
      ),
      isTrue,
    );
    expect(
      grupoAulaMatches(
        titulo: 'Funcional',
        localAula: 'Praia',
        lotada: true,
        query: '',
        chip: GrupoAulaChip.abertas,
      ),
      isFalse,
    );
    expect(grupoAulaChipQuery(GrupoAulaChip.todas), isNull);
    expect(grupoAulaChipQuery(GrupoAulaChip.abertas), 'ABERTAS');
    expect(grupoAulaChipQuery(GrupoAulaChip.lotadas), 'LOTADAS');
  });

  test('grupoAulaHubSubtitle junta freshness', () {
    expect(grupoAulaHubSubtitle(null), 'Turmas abertas e vagas');
    expect(
      grupoAulaHubSubtitle('há 1 min'),
      'Turmas abertas e vagas · há 1 min',
    );
  });

  test('opções de data da aula usam horizontes ou dias corridos', () {
    final now = DateTime(2026, 9, 4);
    final ops = grupoAulaDateOptions(
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initial: now.add(const Duration(days: 1)),
      now: now,
    );
    expect(ops.map(grupoAulaDay).toList(), [
      DateTime(2026, 9, 4),
      DateTime(2026, 9, 5),
      DateTime(2026, 9, 7),
      DateTime(2026, 9, 11),
      DateTime(2026, 9, 18),
      DateTime(2026, 10, 4),
    ]);
    expect(grupoAulaDateOptionLabel(DateTime(2026, 9, 4), now), 'Hoje');
    expect(grupoAulaDateOptionLabel(DateTime(2026, 9, 5), now), 'Amanhã');
    expect(grupoAulaDateLabel(DateTime(2026, 9, 5)), '05/09');
    final curto = grupoAulaDateOptions(
      firstDate: DateTime(2026, 9, 5),
      lastDate: DateTime(2026, 9, 6),
      now: now,
    );
    expect(curto, [DateTime(2026, 9, 5), DateTime(2026, 9, 6)]);
  });
}
