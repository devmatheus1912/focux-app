import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_activation_display.dart';

void main() {
  test('entrada do aluno tem três passos', () {
    final p = alunoActivationProgress(
      temFoto: false,
      anamneseResolvida: false,
      hasTreinoConcluido: false,
    );
    expect(p.totalCount, 3);
    expect(p.current.title, 'Confirmar nome e foto');
  });

  test('próximo passo pula o que já foi feito', () {
    final p = alunoActivationProgress(
      temFoto: true,
      anamneseResolvida: false,
      hasTreinoConcluido: false,
    );
    expect(p.current.route, '/aluno/anamnese');
    expect(p.etapaLabel, 'Etapa 2 de 3');
  });

  test('tudo feito', () {
    final p = alunoActivationProgress(
      temFoto: true,
      anamneseResolvida: true,
      hasTreinoConcluido: true,
    );
    expect(p.allDone, isTrue);
  });
}
