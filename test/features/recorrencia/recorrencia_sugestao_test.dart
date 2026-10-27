import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/features/recorrencia/utils/recorrencia_display.dart';
import 'package:focux_app/features/recorrencia/utils/recorrencia_sugestao.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  final s = lookupS(const Locale('pt'));

  group('recorrenciaValorSugerido', () {
    test('usa o valor da última mensalidade', () {
      expect(
        recorrenciaValorSugerido(FxMoney.parse('150.00'))?.cents,
        15000,
      );
    });
    test('sem histórico ou valor zerado não sugere nada (nunca 199)', () {
      expect(recorrenciaValorSugerido(null), isNull);
      expect(recorrenciaValorSugerido(FxMoney.zero), isNull);
    });
  });

  group('recorrenciaLerValor', () {
    test('aceita vírgula e ponto', () {
      expect(recorrenciaLerValor('199,90')?.cents, 19990);
      expect(recorrenciaLerValor('199.90')?.cents, 19990);
    });
    test('vazio, zero e lixo viram nulo', () {
      expect(recorrenciaLerValor(''), isNull);
      expect(recorrenciaLerValor('  '), isNull);
      expect(recorrenciaLerValor('0'), isNull);
      expect(recorrenciaLerValor('abc'), isNull);
    });
  });

  test('resumo: "Todo dia 26 · R\$ 199,00 · PIX"', () {
    expect(
      recorrenciaResumo(s, dia: 26, valor: FxMoney.parse('199.00')),
      'Todo dia 26 · R\$ 199,00 · PIX',
    );
  });

  group('dia padrão', () {
    test('dia 29 a 31 vira 28', () {
      expect(recorrenciaDiaPadrao(DateTime(2026, 10, 29)), 28);
      expect(recorrenciaDiaPadrao(DateTime(2026, 10, 31)), 28);
      expect(recorrenciaDiaPadrao(DateTime(2026, 10, 26)), 26);
      expect(recorrenciaDiaPadrao(DateTime(2026, 10, 1)), 1);
    });
  });

  group('recorrenciaMostrarFiltros', () {
    test('lista vazia, sem busca nem filtro: só o convite', () {
      expect(
        recorrenciaMostrarFiltros(
          temItens: false,
          filtroAtivo: false,
          buscaAtiva: false,
        ),
        isFalse,
      );
    });
    test('com itens, ou com filtro/busca ativos, mostra', () {
      expect(
        recorrenciaMostrarFiltros(
          temItens: true,
          filtroAtivo: false,
          buscaAtiva: false,
        ),
        isTrue,
      );
      expect(
        recorrenciaMostrarFiltros(
          temItens: false,
          filtroAtivo: true,
          buscaAtiva: false,
        ),
        isTrue,
      );
      expect(
        recorrenciaMostrarFiltros(
          temItens: false,
          filtroAtivo: false,
          buscaAtiva: true,
        ),
        isTrue,
      );
    });
  });

  test('contagem em português, sem "assinatura"', () {
    expect(s.recorrenciaContagem(0), 'Nenhuma recorrência');
    expect(s.recorrenciaContagem(1), '1 recorrência');
    expect(s.recorrenciaContagem(3), '3 recorrências');
    expect(s.recorrenciaVazioTexto, isNot(contains('ssinatura')));
  });
}
