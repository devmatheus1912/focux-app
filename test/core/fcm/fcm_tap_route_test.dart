import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/fcm/fcm_tap_route.dart';

void main() {
  test('route de personal vaza e vira rota do aluno', () {
    expect(
      resolveFcmTapRoute({
        'type': 'mensalidade',
        'route': '/financeiro',
      }),
      '/financeiro/aluno',
    );
    expect(
      resolveFcmTapRoute({
        'type': 'anamnese',
        'route': '/alunos/7/anamnese',
        'alunoId': '7',
      }),
      '/aluno/anamnese',
    );
  });

  test('sem route cai no type já contratado', () {
    expect(
      resolveFcmTapRoute({'type': 'mensalidade'}),
      '/financeiro/aluno',
    );
    expect(resolveFcmTapRoute({'type': 'dunning'}), '/financeiro/aluno');
    expect(resolveFcmTapRoute({'type': 'treino'}), '/checkin/treinos');
    expect(resolveFcmTapRoute({'type': 'chat'}), '/chat/aluno');
    expect(resolveFcmTapRoute({'type': 'anamnese'}), '/aluno/anamnese');
    expect(resolveFcmTapRoute({'type': 'broadcast'}), '/dashboard/aluno');
    expect(resolveFcmTapRoute({'type': 'plan_sync'}), '/assinatura');
    expect(resolveFcmTapRoute({'type': 'retencao'}), '/retencao');
  });

  test('sem type usa hub do aluno, não /alunos do personal', () {
    expect(resolveFcmTapRoute({'alunoId': '12'}), '/dashboard/aluno');
    expect(resolveFcmTapRoute({'chatId': '9'}), '/chat/aluno');
  });

  test('execucaoId empurra o histórico do check-in', () {
    expect(
      resolveFcmTapRoute({
        'type': 'treino',
        'execucaoId': '44',
      }),
      '/checkin/historico/44',
    );
  });

  test('payload vazio ou URL externa não navega', () {
    expect(resolveFcmTapRoute(const {}), isNull);
    expect(resolveFcmTapRoute({'route': 'https://evil.test'}), isNull);
    expect(resolveFcmTapRoute({'route': '//evil.test'}), isNull);
  });
}
