import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_hub_display.dart';

void main() {
  test('cobrança de oferta diz o que é; a mensal diz o mês', () {
    final oferta = Mensalidade.fromJson({
      'id': 1,
      'valor': '200.00',
      'mesReferencia': '2026-11-01',
      'status': 'PENDENTE',
      'descricao': 'Treino 3 meses',
    });
    final mensal = Mensalidade.fromJson({
      'id': 2,
      'valor': '150.00',
      'mesReferencia': '2026-11-01',
      'status': 'PENDENTE',
    });
    expect(financeiroMensalidadeTitulo(oferta), 'Treino 3 meses');
    expect(
      financeiroMensalidadeTitulo(mensal),
      financeiroMensalidadeMesPorExtenso('2026-11-01'),
    );
  });
}
