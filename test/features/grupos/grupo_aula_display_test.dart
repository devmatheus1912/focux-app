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

  test('grupoAulaHubSubtitle junta freshness', () {
    expect(grupoAulaHubSubtitle(null), 'Turmas abertas e vagas');
    expect(
      grupoAulaHubSubtitle('há 1 min'),
      'Turmas abertas e vagas · há 1 min',
    );
  });
}
