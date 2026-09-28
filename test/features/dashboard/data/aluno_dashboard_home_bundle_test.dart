import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
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
  'historicoResumo': [
    {
      'id': 90,
      'treinoId': 11,
      'treinoNome': 'Treino A',
      'status': 'CONCLUIDO',
      'concluidoEm': '2026-08-15T10:00:00',
      'exerciciosCount': 5,
    },
  ],
  'medidas': [
    {'id': 3, 'data': '2026-08-10', 'peso': 62.5, 'cintura': 70.0},
  ],
  'chat': {'possuiMensagemDoAluno': true, 'naoLidasDoPersonal': 2},
  'notificacoesNaoLidas': 4,
  'coachMensagens': [
    {
      'id': 21,
      'tipo': 'INATIVIDADE',
      'mensagem': 'Bora treinar hoje?',
      'criadoEm': '2026-08-16T08:00:00',
      'lido': false,
    },
  ],
  'upsellPendentes': [
    {
      'alunoOfertaId': 5,
      'ofertaId': 9,
      'titulo': 'Consultoria extra',
      'descricao': 'Uma sessão avulsa',
      'valor': 150.0,
      'status': 'PENDENTE',
    },
  ],
  'npsDeveResponder': true,
  'streakAtual': 12,
  'volumeSemanaKg': 240.0,
  'concluidosSemanaIso': 2,
  'frequenciaDias': 4,
  'hasWearableHistory': true,
  'recovery': {
    'dataReferencia': '2026-08-16',
    'steps': 8200,
    'caloriesBurned': 410.0,
    'avgHeartRate': 62.0,
    'sleepHours': 7.5,
    'recoveryScore': 78,
    'recoveryLabel': 'Pronto',
    'recoveryHint': 'Boa noite de sono',
    'sincronizadoEm': '2026-08-16T07:10:00',
  },
  'forcaDeltaPercent': 4.5,
  'recoveryStale': false,
  'insight': {
    'tipo': 'VOLUME_SUBINDO',
    'confianca': 'HIGH',
    'chave': 'insightVolumeSubindo',
    'params': {'pct': '12'},
    'titulo': 'Volume subindo',
    'mensagem': '+12% vs média das 6 semanas anteriores',
  },
  'recursosIndisponiveis': ['HABIT_COACHING'],
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
      expect(bundle.coachMensagens, hasLength(1));
      expect(bundle.coachMensagens.first.mensagem, 'Bora treinar hoje?');
      expect(bundle.upsellPendentes.single.titulo, 'Consultoria extra');
      expect(bundle.npsDeveResponder, isTrue);
      expect(bundle.recovery?.recoveryScore, 78);
      expect(bundle.recovery?.recoveryLabel, 'Pronto');
      expect(bundle.hasWearableHistory, isTrue);
      expect(bundle.streakAtual, 12);
      expect(bundle.volumeSemanaKg, 240);
      expect(bundle.concluidosSemanaIso, 2);
      expect(bundle.frequenciaDias, 4);
      expect(bundle.forcaDeltaPercent, 4.5);
      expect(bundle.recoveryStale, isFalse);
      expect(bundle.insight?.tipo, AlunoInsightTipo.volumeSubindo);
      expect(bundle.recursosIndisponiveis, {'HABIT_COACHING'});
      // BFF não manda mais campos de CRM do personal; o modelo usa defaults.
      expect(bundle.aluno.emRisco, isFalse);
      expect(bundle.aluno.statusFinanceiro, 'ATIVO');
      expect(bundle.aluno.inadimplente, isFalse);
      expect(bundle.aluno.ultimoContato, isNull);
    });

    test('tolerates missing optional blocks', () {
      final json =
          _payload()
            ..remove('personalBrand')
            ..remove('treinos')
            ..remove('historicoResumo')
            ..remove('medidas')
            ..remove('chat')
            ..remove('notificacoesNaoLidas')
            ..remove('coachMensagens')
            ..remove('upsellPendentes')
            ..remove('npsDeveResponder')
            ..remove('recovery')
            ..remove('streakAtual')
            ..remove('volumeSemanaKg')
            ..remove('concluidosSemanaIso')
            ..remove('frequenciaDias')
            ..remove('forcaDeltaPercent')
            ..remove('recoveryStale')
            ..remove('insight')
            ..remove('recursosIndisponiveis');

      final bundle = AlunoDashboardHomeBundle.fromJson(json);

      expect(bundle.personalBrand.nomePersonal, '');
      expect(bundle.treinos, isEmpty);
      expect(bundle.historico, isEmpty);
      expect(bundle.medidas, isEmpty);
      expect(bundle.chat.possuiMensagemDoAluno, isFalse);
      expect(bundle.notificacoesNaoLidas, 0);
      expect(bundle.coachMensagens, isEmpty);
      expect(bundle.upsellPendentes, isEmpty);
      expect(bundle.npsDeveResponder, isFalse);
      expect(bundle.recovery, isNull);
      expect(bundle.streakAtual, 0);
      expect(bundle.volumeSemanaKg, 0);
      expect(bundle.concluidosSemanaIso, isNull);
      expect(bundle.frequenciaDias, isNull);
      expect(bundle.forcaDeltaPercent, isNull);
      expect(bundle.recoveryStale, isFalse);
      expect(bundle.insight, isNull);
      expect(bundle.recursosIndisponiveis, isEmpty);
    });

    test('insight malformado é ignorado sem derrubar a Home', () {
      final json = _payload()..['insight'] = {'tipo': 'QUALQUER'};
      final bundle = AlunoDashboardHomeBundle.fromJson(json);
      expect(bundle.insight, isNull);
      expect(bundle.aluno.nome, 'Ana Souza');
    });

    test('prontidão velha chega como recovery null + recoveryStale', () {
      final json =
          _payload()
            ..['recovery'] = null
            ..['recoveryStale'] = true;
      final bundle = AlunoDashboardHomeBundle.fromJson(json);
      expect(bundle.recovery, isNull);
      expect(bundle.recoveryStale, isTrue);
    });

    test(
      'escalares novos malformados viram null/false sem derrubar a Home',
      () {
        final json =
            _payload()
              ..['forcaDeltaPercent'] = '4.5'
              ..['recoveryStale'] = 'sim'
              ..['concluidosSemanaIso'] = 'x';
        final bundle = AlunoDashboardHomeBundle.fromJson(json);
        expect(bundle.forcaDeltaPercent, isNull);
        expect(bundle.recoveryStale, isFalse);
        expect(bundle.concluidosSemanaIso, isNull);
        expect(bundle.aluno.nome, 'Ana Souza');
      },
    );
  });

  group('AlunoDashboardChatResumo.fromJson', () {
    test('reads unread count from the personal', () {
      final chat = AlunoDashboardChatResumo.fromJson({
        'possuiMensagemDoAluno': true,
        'naoLidasDoPersonal': 2,
      });

      expect(chat.naoLidasDoPersonal, 2);
      expect(chat.possuiMensagemDoAluno, isTrue);
    });

    test('null payload means nothing unread', () {
      expect(AlunoDashboardChatResumo.fromJson(null).naoLidasDoPersonal, 0);
    });
  });
}
