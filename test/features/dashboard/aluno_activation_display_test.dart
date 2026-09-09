import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_activation_display.dart';

void main() {
  test('próximo passo é o primeiro incompleto', () {
    final progress = alunoActivationProgress(
      profileCompletion: 100,
      hasMedidas: false,
      hasTreinoConcluido: false,
      hasChat: false,
    );

    expect(progress.doneCount, 1);
    expect(progress.current.title, 'Registrar a primeira medida');
    expect(progress.etapaLabel, 'Etapa 2 de 4');
    expect(progress.allDone, isFalse);
  });

  test('tudo feito aponta para o último passo', () {
    final progress = alunoActivationProgress(
      profileCompletion: 100,
      hasMedidas: true,
      hasTreinoConcluido: true,
      hasChat: true,
    );

    expect(progress.allDone, isTrue);
    expect(progress.etapaLabel, 'Etapa 4 de 4');
    expect(alunoActivationQuestion(allDone: false), 'Próximo passo');
  });

  test('perfil conta campos preenchidos sem exigir foto', () {
    expect(
      alunoActivationProfileCompletion(
        telefone: '11999999999',
        whatsapp: '11999999999',
        objetivo: 'Hipertrofia',
        genero: 'M',
        peso: '80',
        altura: '1.80',
        dataNascimento: '1995-01-01',
        fotoUrl: null,
      ),
      100,
    );
    expect(
      alunoActivationProfileCompletion(
        telefone: null,
        whatsapp: ' ',
        objetivo: null,
        genero: null,
        peso: null,
        altura: null,
        dataNascimento: null,
        fotoUrl: null,
      ),
      0,
    );
  });
}
