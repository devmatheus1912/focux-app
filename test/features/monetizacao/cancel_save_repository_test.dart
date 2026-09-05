import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/monetizacao/data/cancel_save_repository.dart';

void main() {
  test('CancelSaveOferta parses humanized fields', () {
    final oferta = CancelSaveOferta.fromJson({
      'tipo': 'DISCOUNT_20',
      'titulo': '20% off por 3 meses',
      'descricao':
          'Continue com todas as features. Por 3 meses você paga R\$ 159,92/mês (era R\$ 199,90).',
      'ctaLabel': 'Aceitar desconto',
      'billingChannel': 'NATIVE_STORE',
      'requiresStoreAction': true,
    });

    expect(oferta.tipo, 'DISCOUNT_20');
    expect(oferta.titulo, '20% off por 3 meses');

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
