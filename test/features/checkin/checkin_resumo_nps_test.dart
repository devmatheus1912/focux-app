import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/checkin_resumo_view.dart';

void main() {
  test('resumo do treino começa fechado para o NPS', () {
    expect(checkinResumoAberto.value, isFalse);
  });

  test('o NPS espera o resumo do treino fechar, nunca sobe por cima dele', () {
    final home =
        File(
          'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
        ).readAsStringSync();
    expect(home, contains('checkinResumoAberto.value'));
    expect(home, contains('checkinResumoAberto.addListener(_agendarNps)'));
    expect(home, contains('checkinResumoAberto.removeListener(_agendarNps)'));
    final resumo =
        File(
          'lib/features/checkin/widgets/checkin_resumo_view.dart',
        ).readAsStringSync();
    expect(resumo, contains('checkinResumoAberto.value = true'));
    expect(resumo, contains('checkinResumoAberto.value = false'));
  });
}
