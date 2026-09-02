String? treinoPrescriptionRejection({
  required int series,
  required int descansoSegundos,
}) {
  if (series < 1 || series > 20) {
    return 'Séries deve estar entre 1 e 20.';
  }
  if (descansoSegundos < 0 || descansoSegundos > 600) {
    return 'Descanso deve estar entre 0 e 600 segundos.';
  }
  return null;
}

String treinoPrescriptionSaveLabel() => 'Salvar prescrição';

String treinoPrescriptionSaveConfirmTitle() =>
    'Salvar a prescrição deste exercício?';

String treinoPrescriptionSaveConfirmMessage() =>
    'Séries, reps, descanso e carga passam a valer neste treino.';
