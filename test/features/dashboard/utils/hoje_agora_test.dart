import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/hoje_agora.dart';

AlertaResumo _risco(int id, String nome, [String motivo = '9 dias sem treinar']) =>
    AlertaResumo(id: id, nomeAluno: nome, motivo: motivo, nivelRisco: 'ALTO');

MensalidadeResumo _cobranca(String nome, double valor, int atraso) => MensalidadeResumo(
  id: 1,
  nomeAluno: nome,
  valor: valor,
  dataVencimento: '2026-10-01',
  diasAtraso: atraso,
);

FilaAcaoResumo _fila({
  String tipo = 'GERAL',
  String chave = 'X',
  String titulo = 'Tarefa',
  String descricao = '',
  String url = '/agenda',
  String prioridade = 'P2',
  String cta = '',
}) => FilaAcaoResumo(
  tipo: tipo,
  actionKey: chave,
  titulo: titulo,
  descricao: descricao,
  acaoUrl: url,
  prioridade: prioridade,
  severidade: 'MEDIA',
  responsavel: 'Personal',
  sla: 'Hoje',
  status: 'ABERTO',
  ctaLabel: cta,
  iaSugerida: false,
);

FilaAcaoResumo _ficha(String nome, String quando, {String prioridade = 'P0', int aluno = 4}) => _fila(
  tipo: 'FICHA',
  chave: 'FICHA_VENCENDO_$aluno',
  titulo: 'Renovar a ficha de $nome',
  descricao: quando,
  url: '/alunos/$aluno/rotina?renovar=1&origem=hoje',
  prioridade: prioridade,
  cta: 'Renovar',
);

List<HojeAgoraItem> _agora({
  List<AlertaResumo> risco = const [],
  List<MensalidadeResumo> cobrancas = const [],
  List<FilaAcaoResumo> fila = const [],
  int conversas = 0,
}) => hojeAgora(
  risco: risco,
  cobrancas: cobrancas,
  fila: fila,
  conversasSemResposta: conversas,
);

void main() {
  group('verbo e motivo de cada tipo', () {
    test('aluno sumido: Chamar, com o motivo do servidor e a rota do aluno', () {
      final itens = _agora(risco: [_risco(7, 'hugo silva')]);
      expect(itens, hasLength(1));
      expect(itens.single.verbo, HojeVerbo.chamar);
      expect(itens.single.rotulo, 'Chamar');
      expect(itens.single.titulo, 'Hugo Silva');
      expect(itens.single.motivo, '9 dias sem treinar');
      expect(itens.single.rota, '/alunos/7');
    });

    test('aluno sumido sem motivo usa um texto neutro', () {
      expect(_agora(risco: [_risco(7, 'Hugo', '')]).single.motivo, 'Precisa de contato');
    });

    test('cobrança vencida: Cobrar, com valor e dias de atraso', () {
      final item = _agora(cobrancas: [_cobranca('Ana', 150, 3)]).single;
      expect(item.verbo, HojeVerbo.cobrar);
      expect(item.motivo, matches(RegExp(r'^R\$\s150 vencida há 3 dias$')));
      expect(item.rota, '/financeiro');
    });

    test('um dia de atraso fica no singular e centavos aparecem', () {
      final item = _agora(cobrancas: [_cobranca('Ana', 150.5, 1)]).single;
      expect(item.motivo, contains('vencida há 1 dia'));
      expect(item.motivo, contains('150,50'));
    });

    test('ficha que vence hoje: Renovar, com o nome sem o prefixo do servidor', () {
      final item = _agora(fila: [_ficha('Pedro', 'Vence hoje')]).single;
      expect(item.verbo, HojeVerbo.renovar);
      expect(item.titulo, 'Pedro');
      expect(item.motivo, 'Ficha: vence hoje');
      expect(item.rota, '/alunos/4/rotina?renovar=1&origem=hoje');
    });

    test('conversas viram uma linha só, no singular e no plural', () {
      final uma = _agora(conversas: 1).single;
      expect(uma.verbo, HojeVerbo.responder);
      expect(uma.titulo, '1 conversa');
      expect(uma.rota, '/chat/inbox');
      expect(_agora(conversas: 3).single.titulo, '3 conversas');
    });
  });

  group('o que não entra', () {
    test('cobrança em aberto e no prazo não aparece', () {
      expect(_agora(cobrancas: [_cobranca('Ana', 150, 0)]), isEmpty);
    });

    test('servidor sem diasAtraso (0) não gera cobrança', () {
      final antiga = MensalidadeResumo.fromJson({'id': 1, 'nomeAluno': 'Ana', 'valor': '100.00'});
      expect(antiga.diasAtraso, 0);
      expect(_agora(cobrancas: [antiga]), isEmpty);
    });

    test('ficha que ainda vai vencer (P1) não é urgência, mas conta em "A base"', () {
      final fila = [_ficha('Pedro', 'Vence em 3 dias', prioridade: 'P1')];
      expect(_agora(fila: fila), isEmpty);
      expect(fichasAVencer(fila), 1);
    });

    test('zero conversas não gera linha', () {
      expect(_agora(conversas: 0), isEmpty);
    });

    test('resumo de risco e cobrança da fila não duplicam as linhas por pessoa', () {
      final fila = [
        _fila(chave: 'RISK_STUDENTS', tipo: 'RISCO', titulo: '2 alunos em risco'),
        _fila(chave: 'BILLING_PENDING', tipo: 'COBRANCA', titulo: 'Cobrar pendências'),
      ];
      expect(_agora(fila: fila), isEmpty);
    });

    test('"Radar Focux: Nome" não repete o aluno que já tem linha', () {
      final itens = _agora(
        risco: [_risco(7, 'Hugo Silva')],
        fila: [_fila(titulo: 'Radar Focux: hugo silva')],
      );
      expect(itens, hasLength(1));
    });
  });

  group('ordem', () {
    test('sumido, cobrança, ficha, conversas e o resto da fila', () {
      final itens = _agora(
        risco: [_risco(1, 'Hugo')],
        cobrancas: [_cobranca('Ana', 100, 2)],
        fila: [_ficha('Pedro', 'Vence hoje'), _fila(titulo: 'Conferir agenda', cta: 'Conferir')],
        conversas: 2,
      );
      expect(itens.map((i) => i.verbo), [
        HojeVerbo.chamar,
        HojeVerbo.cobrar,
        HojeVerbo.renovar,
        HojeVerbo.responder,
        HojeVerbo.abrir,
      ]);
      expect(itens.last.rotulo, 'Conferir');
    });

    test('a cobrança mais atrasada vem primeiro', () {
      final itens = _agora(
        cobrancas: [_cobranca('Ana', 100, 2), _cobranca('Bruno', 100, 9), _cobranca('Carla', 100, 5)],
      );
      expect(itens.map((i) => i.titulo), ['Bruno', 'Carla', 'Ana']);
    });

    test('rótulo de servidor longo demais cai em "Abrir"', () {
      final item = _agora(
        fila: [_fila(titulo: 'Algo', cta: 'Abrir a central de comando')],
      ).single;
      expect(item.rotulo, 'Abrir');
    });

    test('tarefa do copiloto: Revisar, abrindo o copiloto', () {
      final item = _agora(fila: [_fila(tipo: 'IA_COPILOTO', titulo: 'Ajustar ficha')]).single;
      expect(item.verbo, HojeVerbo.revisar);
      expect(item.rota, '/dashboard/command-center/copiloto');
    });

    test('url que não é rota interna volta para a Hoje', () {
      final item = _agora(fila: [_fila(titulo: 'Algo', url: 'https://x.com')]).single;
      expect(item.rota, '/dashboard/personal');
    });
  });

  test('dia quieto: nenhuma linha', () {
    expect(_agora(), isEmpty);
  });
}
