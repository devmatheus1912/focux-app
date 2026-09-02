import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/treinos/utils/treino_prescription_rules.dart';

void main() {
  test('aceita faixa da prescrição', () {
    expect(
      treinoPrescriptionRejection(series: 1, descansoSegundos: 0),
      isNull,
    );
    expect(
      treinoPrescriptionRejection(series: 20, descansoSegundos: 600),
      isNull,
    );
  });

  test('recusa séries fora de 1–20', () {
    expect(
      treinoPrescriptionRejection(series: 0, descansoSegundos: 60),
      'Séries deve estar entre 1 e 20.',
    );
    expect(
      treinoPrescriptionRejection(series: 21, descansoSegundos: 60),
      'Séries deve estar entre 1 e 20.',
    );
  });

  test('recusa descanso fora de 0–600', () {
    expect(
      treinoPrescriptionRejection(series: 4, descansoSegundos: -1),
      'Descanso deve estar entre 0 e 600 segundos.',
    );
    expect(
      treinoPrescriptionRejection(series: 4, descansoSegundos: 601),
      'Descanso deve estar entre 0 e 600 segundos.',
    );
  });

  test('copy do salvar confirma a mutação', () {
    expect(treinoPrescriptionSaveLabel(), 'Salvar prescrição');
    expect(treinoPrescriptionSaveConfirmTitle(), contains('prescrição'));
    expect(treinoPrescriptionSaveConfirmMessage(), contains('treino'));
  });
}
