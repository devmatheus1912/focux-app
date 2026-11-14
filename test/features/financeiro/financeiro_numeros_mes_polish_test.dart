import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_metas_bloco.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_hub_display.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_numeros.dart';
import 'package:focux_app/l10n/pt.dart';

ResumoMensal _resumo({String anteriores = '0', String adiantado = '0'}) =>
    ResumoMensal.fromJson({
      'totalRecebido': '600.00',
      'totalPrevisto': '0.00',
      'inadimplentes': 0,
      'ticketMedio': '0',
      'acumuladoAnual': '0',
      'recebidoDeMesesAnteriores': anteriores,
      'recebidoAdiantado': adiantado,
    });

void main() {
  group('Financeiro: números do mês', () {
    test('o mês vem escrito por extenso', () {
      expect(mesPtBr(DateTime(2026, 11, 14)), 'Novembro');
      expect(mesPtBr(DateTime(2027, 1, 2)), 'Janeiro');
    });

    test('nota do Recebido: anteriores, adiantado, os dois e nenhum', () {
      expect(financeiroNotaDoRecebido(ptS, _resumo()), isNull);
      expect(
        financeiroNotaDoRecebido(ptS, _resumo(anteriores: '200.00')),
        'Inclui R\$ 200,00 pagos de meses anteriores',
      );
      expect(
        financeiroNotaDoRecebido(ptS, _resumo(adiantado: '50.00')),
        'Inclui R\$ 50,00 pago adiantado',
      );
      expect(
        financeiroNotaDoRecebido(
          ptS,
          _resumo(anteriores: '200.00', adiantado: '50.00'),
        ),
        'Inclui R\$ 200,00 pagos de meses anteriores e R\$ 50,00 pago adiantado',
      );
    });

    test('"Marcar lote" só com 2 ou mais em aberto', () {
      expect(financeiroMostrarMarcarLote(0), isFalse);
      expect(financeiroMostrarMarcarLote(1), isFalse);
      expect(financeiroMostrarMarcarLote(2), isTrue);
    });
  });

  group('Folha Definir meta', () {
    test('prazos numa linha; prazo salvo vira "Até dd/mm" na frente', () {
      expect(metaPrazoOpcoes(0), [0, 30, 60, 90]);
      expect(metaPrazoOpcoes(metaPrazoAtual), [metaPrazoAtual, 0, 30, 60, 90]);
      expect(
        metaPrazoRotulo(metaPrazoAtual, prazoAtual: DateTime(2026, 12, 20)),
        'Até 20/12',
      );
      expect(metaPrazoRotulo(0), 'Sem prazo');
      expect(metaPrazoRotulo(30), '30 dias');
    });

    test('motivo diz quem vê; alvo tem exemplo; título sem ícone', () {
      final src = File(
        'lib/features/evolucao/widgets/evolucao_metas_bloco.dart',
      ).readAsStringSync();
      expect(src, contains('ajuda: ptS.metaObservacaoAjuda'));
      expect(src, contains('ptS.metaAlvoExemplo('));
      expect(src, contains('icon: null'));
      expect(ptS.metaObservacaoAjuda, 'Só você vê.');
    });
  });
}
