import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/fcm/fcm_tap_route.dart';

void main() {
  test('route explícita vence o type', () {
    expect(
      resolveFcmTapRoute({
        'type': 'mensalidade',
        'route': '/financeiro',
      }),
      '/financeiro',
    );
  });

  test('sem route cai no type já contratado', () {
    expect(
      resolveFcmTapRoute({'type': 'mensalidade'}),
      '/financeiro/aluno',
    );
    expect(resolveFcmTapRoute({'type': 'dunning'}), '/financeiro/aluno');
    expect(resolveFcmTapRoute({'type': 'treino'}), '/dashboard/aluno');
    expect(resolveFcmTapRoute({'type': 'chat'}), '/chat/aluno');
    expect(resolveFcmTapRoute({'type': 'anamnese'}), '/aluno/anamnese');
    expect(resolveFcmTapRoute({'type': 'plan_sync'}), '/assinatura');
    expect(resolveFcmTapRoute({'type': 'retencao'}), '/retencao');
  });

  test('sem type usa alunoId ou chatId', () {
    expect(resolveFcmTapRoute({'alunoId': '12'}), '/alunos/12');
    expect(resolveFcmTapRoute({'chatId': '9'}), '/alunos/9/chat');
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
