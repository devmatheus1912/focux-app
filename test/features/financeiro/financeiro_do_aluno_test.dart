import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_do_aluno.dart';
import 'package:focux_app/features/financeiro/utils/vencimento_atalhos.dart';

Mensalidade _m(
  int id,
  String mes,
  String status, {
  String? venc,
  String? pagoEm,
  int valor = 200,
}) => Mensalidade(
  id: id,
  alunoId: 1,
  alunoNome: 'Julio Cesar',
  valor: valor,
  mesReferencia: mes,
  status: status,
  vencimento: venc,
  pagoEm: pagoEm,
);

void main() {
  final hoje = DateTime(2026, 11, 11);

  group('vencimento', () {
    test('mês de hoje ocupado: abre no próximo livre', () {
      final livre = vencimentoPrimeiroMesLivre(
        hoje: hoje,
        ocupados: {'2026-11': MesOcupado(status: 'PAGO', valor: FxMoney.parse(200))},
      );
      expect(livre, DateTime(2026, 12, 1));
    });

    test('próximos três ocupados: o primeiro livre depois deles', () {
      final ocupado = MesOcupado(status: 'PENDENTE', valor: FxMoney.parse(200));
      final livre = vencimentoPrimeiroMesLivre(
        hoje: hoje,
        ocupados: {
          '2026-11': ocupado,
          '2026-12': ocupado,
          '2027-01': ocupado,
          '2027-02': ocupado,
        },
      );
      expect(livre, DateTime(2027, 3, 1));
    });

    test('lista vai de três à frente até três atrás', () {
      final meses = vencimentoMeses(hoje);
      expect(meses.first, DateTime(2027, 2, 1));
      expect(meses.last, DateTime(2026, 8, 1));
    });

    test('cancelada não bloqueia o mês', () {
      final livre = vencimentoPrimeiroMesLivre(
        hoje: hoje,
        ocupados: {'2026-11': MesOcupado(status: 'CANCELADO', valor: FxMoney.parse(200))},
      );
      expect(livre, DateTime(2026, 11, 1));
    });
  });

  group('resumo do aluno', () {
    test('em dia: recebido no ano', () {
      final r = financeiroResumoDoAluno([
        _m(1, '2026-10', 'PAGO', pagoEm: '2026-10-05', valor: 350),
        _m(2, '2026-11', 'PAGO', pagoEm: '2026-11-05', valor: 350),
      ], hoje: hoje, parcial: false);
      expect(r.texto, 'Em dia · R\$ 700,00 recebidos em 2026');
      expect(r.alerta, isFalse);
    });

    test('em aberto: quanto e quando vence', () {
      final r = financeiroResumoDoAluno([
        _m(1, '2026-12', 'PENDENTE', venc: '2026-12-05'),
      ], hoje: hoje, parcial: false);
      expect(r.texto, '1 em aberto · R\$ 200,00 vence 05/12');
    });

    test('atrasada: em alerta, desde quando', () {
      final r = financeiroResumoDoAluno([
        _m(1, '2026-11', 'ATRASADO', venc: '2026-11-05'),
        _m(2, '2026-12', 'PENDENTE', venc: '2026-12-05'),
      ], hoje: hoje, parcial: true);
      expect(r.texto, startsWith('1 em atraso · R\$ 200,00 desde 05/11'));
      expect(r.texto, endsWith('nas cobranças carregadas'));
      expect(r.alerta, isTrue);
    });
  });

  group('linhas', () {
    test('situação do mês', () {
      expect(financeiroSituacaoDoMes(_m(1, '2026-11', 'PAGO', pagoEm: '2026-11-09')), 'Paga em 09/11');
      expect(financeiroSituacaoDoMes(_m(1, '2026-12', 'PENDENTE', venc: '2026-12-05')), 'Vence 05/12');
      expect(financeiroSituacaoDoMes(_m(1, '2026-11', 'ATRASADO', venc: '2026-11-05')), 'Atrasada desde 05/11');
      expect(financeiroSituacaoDoMes(_m(1, '2026-10', 'CANCELADO')), 'Cancelada');
    });

    test('meses sem cobrança entre a primeira e hoje', () {
      final linhas = financeiroLinhasDoAluno([
        _m(1, '2026-11', 'PAGO'),
        _m(2, '2026-08', 'PAGO'),
        _m(3, '2026-09', 'CANCELADO'),
      ], hoje: hoje, comMesesVazios: true);
      final vazios = linhas.whereType<LinhaMesSemCobranca>().map((l) => l.mes.month);
      expect(vazios, [10, 9]);
      expect(linhas.first.mes, DateTime(2026, 11, 1));
    });

    test('fora do filtro "Todas": sem meses vazios', () {
      final linhas = financeiroLinhasDoAluno([
        _m(1, '2026-11', 'PAGO'),
        _m(2, '2026-08', 'PAGO'),
      ], hoje: hoje, comMesesVazios: false);
      expect(linhas.whereType<LinhaMesSemCobranca>(), isEmpty);
    });
  });
}
