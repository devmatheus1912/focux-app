import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/monetizacao/data/cancel_save_repository.dart';

void main() {
  test('CancelSaveOferta parses humanized fields', () {
    final oferta = CancelSaveOferta.fromJson({
      'tipo': 'DISCOUNT_40',
      'titulo': '40% off por 3 meses',
      'descricao': 'Por 3 meses você paga R\$ 47,40/mês.',
      'ctaLabel': 'Aceitar desconto',
      'billingChannel': 'NATIVE_STORE',
      'requiresStoreAction': true,
    });

    expect(oferta.ctaLabel, 'Aceitar desconto');
    expect(oferta.requiresStoreAction, isTrue);
    expect(oferta.billingChannel, 'NATIVE_STORE');
  });

  test('CancelSaveResposta parses billing flags', () {
    final resposta = CancelSaveResposta.fromJson({
      'id': 1,
      'aceita': true,
      'mensagem': 'Preferência salva!',
      'billingApplied': false,
      'requiresStoreAction': true,
    });

    expect(resposta.billingApplied, isFalse);
    expect(resposta.requiresStoreAction, isTrue);
  });
}
