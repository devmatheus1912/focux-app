import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_menu_acoes.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/utils/aluno360_resumo_agora.dart';
import 'package:focux_app/l10n/app_localizations.dart';

final _s = lookupS(const Locale('pt'));

Aluno _aluno({
  int? diasSemTreino,
  int? aderencia,
  bool emRisco = false,
  bool inadimplente = false,
  String status = 'ATIVO',
  bool contaAtiva = true,
}) => Aluno(
  id: 1,
  nome: 'Hugo Silva',
  email: 'hugo@x.com',
  status: status,
  diasSemTreino: diasSemTreino,
  aderenciaPercent: aderencia,
  emRisco: emRisco,
  inadimplente: inadimplente,
  statusFinanceiro: inadimplente ? 'INADIMPLENTE' : 'EM_DIA',
  contaAtiva: contaAtiva,
);

ProximaAcaoResumo _proxima({
  String acao = 'Completar mapa corporal',
  String motivo = 'Faltam medidas para ajustar o treino',
  String? tipo,
}) => ProximaAcaoResumo(
  acao: acao,
  motivo: motivo,
  fonte: 'PADRAO',
  prioridade: 'P2',
  tipoAcao: tipo,
);

Aluno360OperacaoSnapshot _snap(Aluno aluno, ProximaAcaoResumo? proxima) =>
    resolveAluno360OperacaoSnapshot(
      aluno: aluno,
      proximaAcao360: proxima,
      forceIa: false,
      iaAsync: null,
      hasOpenTask: false,
      followUpDue: false,
      wearableRelevant: false,
    );

ResumoAgora? _agora(Aluno aluno, ProximaAcaoResumo? proxima, {String? risco}) {
  final snap = _snap(aluno, proxima);
  return resumoAgora(
    _s,
    sticky: snap.stickyAction,
    proxima: snap.effectiveProxima,
    aluno: aluno,
    contactPriority: snap.contactPriority,
    riscoMotivo: risco,
  );
}

void main() {
  group('motivoDeContato', () {
    test('dias parado vence', () {
      expect(motivoDeContato(_s, _aluno(diasSemTreino: 9)), '9 dias sem treinar');
      expect(motivoDeContato(_s, _aluno(diasSemTreino: 1)), '1 dia sem treinar');
    });

    test('frase do servidor entra; código não', () {
      expect(
        motivoDeContato(_s, _aluno(aderencia: 80), riscoMotivo: 'Sumiu depois do reajuste'),
        'Sumiu depois do reajuste',
      );
      expect(motivoDeContato(_s, _aluno(aderencia: 80), riscoMotivo: 'SEM_TREINO_5D'), isNull);
      expect(motivoDeContato(_s, _aluno(aderencia: 80), riscoMotivo: 'SEM TREINO'), isNull);
    });

    test('nunca treinou: diz isso, não "0%"', () {
      final a = _aluno(aderencia: 0);
      expect(semHistoricoDeTreino(a), isTrue);
      expect(motivoDeContato(_s, a), 'Ainda sem treinos registrados');
    });
  });

  group('resumoAgora', () {
    test('contato prioritário usa o motivo do contato, não a frase de outra sugestão', () {
      final r = _agora(_aluno(emRisco: true, diasSemTreino: 9), _proxima());
      expect(r, isNotNull);
      expect(r!.titulo, 'Retomar contato');
      expect(r.motivo, '9 dias sem treinar');
      expect(r.motivo, isNot(contains('mapa corporal')));
      expect(r.verbo, AgoraVerbo.chamar);
      expect(r.destino, OperacaoStickyDestination.chat);
    });

    test('o botão nunca repete o título', () {
      final r = _agora(_aluno(emRisco: true, diasSemTreino: 9), _proxima())!;
      expect(agoraVerboTexto(_s, r.verbo), isNot(r.titulo));
    });

    test('nunca treinou e em risco: motivo de quem não começou', () {
      final r = _agora(_aluno(emRisco: true, aderencia: 0), _proxima())!;
      expect(r.motivo, 'Ainda sem treinos registrados');
    });

    test('mensalidade em atraso vira Cobrar', () {
      final r = _agora(
        _aluno(inadimplente: true, aderencia: 80, diasSemTreino: 1),
        _proxima(acao: 'Cobrar mensalidade', tipo: 'FINANCEIRO', motivo: 'Mensalidade em atraso'),
      );
      if (r != null && r.destino == OperacaoStickyDestination.financeiro) {
        expect(r.verbo, AgoraVerbo.cobrar);
        expect(r.motivo, 'A mensalidade está em atraso');
      }
    });

    test('aluno em dia, sem nada a dizer: nulo', () {
      expect(_agora(_aluno(aderencia: 90, diasSemTreino: 1), null), isNull);
    });
  });

  group('aluno360MenuItens', () {
    test('Excluir é o último, separado e destrutivo', () {
      final itens = aluno360MenuItens(_aluno());
      expect(itens.last.acao, Aluno360MenuAcao.excluir);
      expect(itens.last.separadorAntes, isTrue);
      expect(itens.last.destrutivo, isTrue);
    });

    test('ativo oferece Pausar e Bloquear, nessa ordem, com o separador antes', () {
      final status = aluno360MenuItens(_aluno())
          .where((i) => i.acao == Aluno360MenuAcao.status)
          .toList();
      expect(status.map((i) => i.novoStatus), ['INATIVO', 'BLOQUEADO']);
      expect(status.first.separadorAntes, isTrue);
      expect(status.last.destrutivo, isTrue);
    });

    test('pausado oferece Reativar', () {
      final status = aluno360MenuItens(_aluno(status: 'INATIVO'))
          .where((i) => i.acao == Aluno360MenuAcao.status)
          .map((i) => i.novoStatus);
      expect(status, contains('ATIVO'));
    });

    test('"Reenviar link" só com a conta ainda não ativa', () {
      expect(
        aluno360MenuItens(_aluno(contaAtiva: true)).map((i) => i.acao),
        isNot(contains(Aluno360MenuAcao.reenviarLink)),
      );
      expect(
        aluno360MenuItens(_aluno(contaAtiva: false)).map((i) => i.acao),
        contains(Aluno360MenuAcao.reenviarLink),
      );
    });

    test('editar e criar tarefa abrem o menu', () {
      final acoes = aluno360MenuItens(_aluno()).map((i) => i.acao).toList();
      expect(acoes.take(2), [Aluno360MenuAcao.editar, Aluno360MenuAcao.criarTarefa]);
    });
  });

  group('mesmaAcao', () {
    test('ignora caixa, espaço e ponto final', () {
      expect(mesmaAcao('Completar mapa corporal', 'completar mapa corporal.'), isTrue);
      expect(mesmaAcao(' Completar mapa corporal ', 'Completar mapa corporal'), isTrue);
    });

    test('frases diferentes ou ausentes não casam', () {
      expect(mesmaAcao('Completar mapa corporal', 'Retomar contato'), isFalse);
      expect(mesmaAcao('Completar mapa corporal', null), isFalse);
      expect(mesmaAcao('', ''), isFalse);
    });
  });
}
