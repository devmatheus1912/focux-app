import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';

Map<String, dynamic> _payload() => {
  'aluno': {
    'id': 7,
    'nome': 'Ana Souza',
    'email': 'ana@focux.app',
    'status': 'ATIVO',
    'objetivo': 'Hipertrofia',
    'peso': 62.5,
    'altura': 1.65,
  },
  'personalBrand': {
    'nomePersonal': 'Matheus',
    'plano': 'PRO',
    'whiteLabelActive': true,
  },
  'treinos': [
    {
      'id': null,
      'treinoId': 11,
      'treinoNome': 'Treino A',
      'status': 'PENDENTE',
      'exercicios': [],
    },
  ],
  'historico': [
    {
      'id': 90,
      'treinoId': 11,
      'treinoNome': 'Treino A',
      'status': 'CONCLUIDO',
      'concluidoEm': '2026-08-15T10:00:00',
      'exercicios': [],
    },
  ],
  'medidas': [
    {'id': 3, 'data': '2026-08-10', 'peso': 62.5, 'cintura': 70.0},
  ],
  'chat': {
    'possuiMensagemDoAluno': true,
    'ultimaMensagemAlunoEm': '2026-08-14T18:30:00',
    'naoLidasDoPersonal': 2,
  },
  'notificacoesNaoLidas': 4,
};

void main() {
  group('AlunoDashboardHomeBundle', () {
    test('parses the aggregated BFF payload', () {
      final bundle = AlunoDashboardHomeBundle.fromJson(_payload());

      expect(bundle.aluno.id, 7);
      expect(bundle.aluno.nome, 'Ana Souza');
      expect(bundle.personalBrand.nomePersonal, 'Matheus');
      expect(bundle.personalBrand.whiteLabelActive, isTrue);
      expect(bundle.treinos, hasLength(1));
      expect(bundle.treinos.first.status, 'PENDENTE');
      expect(bundle.historico.first.status, 'CONCLUIDO');
      expect(bundle.medidas.first.peso, 62.5);
      expect(bundle.chat.naoLidasDoPersonal, 2);
      expect(bundle.notificacoesNaoLidas, 4);
    });

    test('tolerates missing optional blocks', () {
      final json = _payload()
        ..remove('personalBrand')
        ..remove('treinos')
        ..remove('historico')
        ..remove('medidas')
        ..remove('chat')
        ..remove('notificacoesNaoLidas');

      final bundle = AlunoDashboardHomeBundle.fromJson(json);

      expect(bundle.personalBrand.nomePersonal, '');
      expect(bundle.treinos, isEmpty);
      expect(bundle.historico, isEmpty);
      expect(bundle.medidas, isEmpty);
      expect(bundle.chat.possuiMensagemDoAluno, isFalse);
      expect(bundle.notificacoesNaoLidas, 0);
    });
  });

  group('AlunoDashboardChatResumo.toSyntheticMessages', () {
    test('emits one ALUNO message when the student already wrote', () {
      final chat = AlunoDashboardChatResumo.fromJson({
        'possuiMensagemDoAluno': true,
        'ultimaMensagemAlunoEm': '2026-08-14T18:30:00',
        'naoLidasDoPersonal': 0,
      });

      final messages = chat.toSyntheticMessages();

      expect(messages, hasLength(1));
      expect(messages.first.remetente, 'ALUNO');
      expect(messages.first.enviadoEm, DateTime(2026, 8, 14, 18, 30));
    });

    test('emits nothing when the student never wrote', () {
      expect(
        AlunoDashboardChatResumo.fromJson({
          'possuiMensagemDoAluno': false,
        }).toSyntheticMessages(),
        isEmpty,
      );
    });
  });
}
