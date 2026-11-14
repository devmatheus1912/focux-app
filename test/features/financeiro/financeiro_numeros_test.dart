import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_status_pill.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_numeros.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Mensalidade _m(
  String status, {
  String mes = '2026-10-01',
  String? vencimento,
  String? pagoEm,
}) => Mensalidade(
  id: 1,
  alunoId: 2,
  alunoNome: 'Hugo',
  valor: '100.00',
  mesReferencia: mes,
  status: status,
  vencimento: vencimento,
  pagoEm: pagoEm,
);

void main() {
  final hoje = DateTime(2026, 10, 26);
  final s = lookupS(const Locale('pt'));

  group('financeiroFiltroInicial', () {
    test('com atraso abre em Atrasadas', () {
      expect(
        financeiroFiltroInicial(quantidadeAtrasadas: 1),
        MensalidadeFiltro.atrasadas,
      );
    });
    test('sem atraso abre em Em aberto', () {
      expect(
        financeiroFiltroInicial(quantidadeAtrasadas: 0),
        MensalidadeFiltro.abertas,
      );
    });
  });

  group('financeiroDiasDeAtraso', () {
    test('conta a partir do vencimento', () {
      expect(
        financeiroDiasDeAtraso(
          mesReferencia: '2026-10-01',
          vencimento: '2026-10-20',
          hoje: hoje,
        ),
        6,
      );
    });
    test('sem vencimento usa o primeiro dia do mês', () {
      expect(
        financeiroDiasDeAtraso(mesReferencia: '2026-10-01', hoje: hoje),
        25,
      );
    });
    test('vence hoje ou no futuro não tem atraso', () {
      expect(
        financeiroDiasDeAtraso(
          mesReferencia: '2026-10-01',
          vencimento: '2026-10-26',
          hoje: hoje,
        ),
        0,
      );
      expect(
        financeiroDiasDeAtraso(
          mesReferencia: '2026-10-01',
          vencimento: '2026-11-02',
          hoje: hoje,
        ),
        0,
      );
    });
  });

  group('financeiroSelo', () {
    test('atrasada diz há quantos dias, no singular e no plural', () {
      final um = financeiroSelo(
        s,
        _m('ATRASADO', vencimento: '2026-10-25'),
        hoje: hoje,
      );
      expect(um.texto, 'Atrasada há 1 dia');
      expect(um.tom, FxPillTone.danger);
      final seis = financeiroSelo(
        s,
        _m('ATRASADO', vencimento: '2026-10-20'),
        hoje: hoje,
      );
      expect(seis.texto, 'Atrasada há 6 dias');
    });
    test('pendente, paga e cancelada', () {
      expect(financeiroSelo(s, _m('PENDENTE'), hoje: hoje).texto, 'Pendente');
      final paga = financeiroSelo(
        s,
        _m('PAGO', pagoEm: '2026-10-22T10:00:00'),
        hoje: hoje,
      );
      expect(paga.texto, 'Paga em 22/10');
      expect(paga.tom, FxPillTone.success);
      expect(financeiroSelo(s, _m('CANCELADO'), hoje: hoje).texto, 'Cancelada');
    });
  });

  group('ResumoMensal', () {
    test('lê os campos novos e mantém compatibilidade com o JSON antigo', () {
      final novo = ResumoMensal.fromJson({
        'totalRecebido': '100.00',
        'totalPrevisto': '0.00',
        'inadimplentes': 1,
        'ticketMedio': '100.00',
        'acumuladoAnual': '100.00',
        'totalEmAberto': '250.00',
        'totalAtrasado': '300.00',
        'quantidadeAtrasadas': 2,
        'recebidoDeMesesAnteriores': '100.00',
      });
      expect(novo.totalEmAberto.cents, 25000);
      expect(novo.totalAtrasado.cents, 30000);
      expect(novo.quantidadeAtrasadas, 2);
      expect(novo.recebidoDeMesesAnteriores.cents, 10000);

      final antigo = ResumoMensal.fromJson({
        'totalRecebido': '100.00',
        'totalPrevisto': '0.00',
        'inadimplentes': 0,
        'ticketMedio': '0',
        'acumuladoAnual': '0',
      });
      expect(antigo.totalAtrasado.cents, 0);
      expect(antigo.quantidadeAtrasadas, 0);
      expect(antigo.recebidoDeMesesAnteriores.cents, 0);
    });
  });
}
