import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/grupos/utils/grupo_aula_display.dart';

void main() {
  test('grupoAulaWhenLabel formata data e hora', () {
    expect(
      grupoAulaWhenLabel(DateTime(2026, 9, 2, 7, 0)),
      '02/09 07:00',
    );
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
