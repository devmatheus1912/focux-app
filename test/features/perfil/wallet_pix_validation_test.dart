import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/core/utils/pt_br_display.dart';
import 'package:focux_app/features/perfil/utils/wallet_pix_validation.dart';

void main() {
  group('formatBrlCurrency', () {
    test('formata com separadores brasileiros', () {
      expect(formatBrlCurrency(2000), 'R\$ 2.000,00');
      expect(formatBrlCurrency(79.9), 'R\$ 79,90');
    });
  });

  group('WalletPixValidation', () {
    test('valida CPF com 11 dígitos', () {
      expect(
        WalletPixValidation.validateChave('CPF', '123.456.789-09'),
        isNull,
      );
      expect(
        WalletPixValidation.validateChave('CPF', '123'),
        isNotNull,
      );
    });

    test('valida e-mail', () {
      expect(
        WalletPixValidation.validateChave('EMAIL', 'personal@focux.app'),
        isNull,
      );
      expect(
        WalletPixValidation.validateChave('EMAIL', 'invalido'),
        isNotNull,
      );
    });

    test('formata chave salva para exibição', () {
      expect(
        WalletPixValidation.formatDisplay('CPF', '12345678909'),
        '123.456.789-09',
      );
      expect(
        WalletPixValidation.formatDisplay('TELEFONE', '11999998888'),
        '(11) 99999-8888',
      );
    });

    test('normaliza chave numérica para API', () {
      expect(
        WalletPixValidation.normalizeForApi('CPF', '123.456.789-09'),
        '12345678909',
      );
      expect(
        WalletPixValidation.normalizeForApi('EMAIL', 'a@b.com'),
        'a@b.com',
      );
    });
  });

  test('copy de salvar e descartar fica fora da UI', () {
    expect(walletSalvarTileLabel(), 'Salvar dados');
    expect(walletSalvarConfirmTitle(), 'Salvar dados da carteira?');
    expect(walletDiscardTitle(), 'Descartar alterações?');
    expect(walletChavePixMax, 120);
    expect(walletHubSubtitle(), 'PIX e banco dos recebimentos');
    expect(
      walletRecebidoHint(previsto: 'R\$ 1.000,00', percent: 40),
      '40% de R\$ 1.000,00 previsto',
    );
  });
}
