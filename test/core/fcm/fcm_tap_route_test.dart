import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/fcm/fcm_tap_route.dart';

void main() {
  test('route de personal vaza e vira rota do aluno', () {
    expect(
      resolveFcmTapRoute({'type': 'mensalidade', 'route': '/financeiro'}),
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
    expect(resolveFcmTapRoute({'type': 'mensalidade'}), '/financeiro/aluno');
    expect(resolveFcmTapRoute({'type': 'dunning'}), '/financeiro/aluno');
    expect(resolveFcmTapRoute({'type': 'treino'}), '/checkin/treinos');
    expect(
      resolveFcmTapRoute({'type': 'treino', 'treinoId': '11'}),
      '/checkin/executar?treinoId=11',
    );
    expect(resolveFcmTapRoute({'type': 'chat'}), '/chat/aluno');
    expect(resolveFcmTapRoute({'type': 'anamnese'}), '/aluno/anamnese');
    expect(resolveFcmTapRoute({'type': 'broadcast'}), '/dashboard/aluno');
    expect(resolveFcmTapRoute({'type': 'plan_sync'}), '/assinatura');
    expect(resolveFcmTapRoute({'type': 'retencao'}), '/dashboard/aluno');
    expect(
      resolveFcmTapRoute({'type': 'retencao'}, role: 'PERSONAL'),
      '/retencao',
    );
  });

  test('hub operacional do personal não abre na sessão aluno', () {
    expect(
      resolveFcmTapRoute({'route': '/retencao'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/dunning'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/leads-publicos'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/depoimentos'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/loja'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/pacotes'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/busca'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/assinatura'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/perfil/equipe'}, role: 'ALUNO'),
      '/dashboard/aluno',
    );
    expect(
      resolveFcmTapRoute({'route': '/retencao'}, role: 'PERSONAL'),
      '/retencao',
    );
    expect(
      resolveFcmTapRoute({'route': '/depoimentos'}, role: 'PERSONAL'),
      '/depoimentos',
    );
  });

  test('sem type usa hub do aluno, não /alunos do personal', () {
    expect(resolveFcmTapRoute({'alunoId': '12'}), '/dashboard/aluno');
    expect(resolveFcmTapRoute({'chatId': '9'}), '/chat/aluno');
  });

  test('execucaoId empurra o histórico do check-in', () {
    expect(
      resolveFcmTapRoute({'type': 'treino', 'execucaoId': '44'}),
      '/checkin/historico/44',
    );
  });

  test('treinoId vence execucaoId no type treino', () {
    expect(
      resolveFcmTapRoute({
        'type': 'treino',
        'treinoId': '11',
        'execucaoId': '44',
      }),
      '/checkin/executar?treinoId=11',
    );
  });

  test('payload vazio ou URL externa não navega', () {
    expect(resolveFcmTapRoute(const {}), isNull);
    expect(resolveFcmTapRoute({'route': 'https://evil.test'}), isNull);
    expect(resolveFcmTapRoute({'route': '//evil.test'}), isNull);
  });
}
