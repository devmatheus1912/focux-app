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

  test('copy de salvar, trocar e descartar fica fora da UI', () {
    expect(walletSalvarTileLabel(), 'Salvar chave');
    expect(walletTrocarConfirmTitle(), 'Trocar a chave PIX?');
    expect(
      walletTrocarConfirmMessage('E-mail · j***@gmail.com'),
      contains('vão para: E-mail · j***@gmail.com'),
    );
    expect(walletDiscardTitle(), 'Descartar alterações?');
    expect(walletChavePixMax, 120);
  });

  test('chave mascarada e leitura para o leitor de tela', () {
    expect(walletRotuloMascarado('CPF', '12345678901'), 'CPF · ***.456.789-**');
    expect(walletChaveSemantica('CPF', '12345678901'), 'CPF terminado em 789');
    expect(
      walletChaveSemantica('TELEFONE', '62999994321'),
      'Celular terminado em 4321',
    );
    expect(
      walletChaveSemantica('EMAIL', 'joana@gmail.com'),
      'E-mail começando com j',
    );
    expect(walletChaveSemantica('ALEATORIA', 'x' * 32), 'Chave aleatória cadastrada');
  });

  test('seletor de tipo: cinco opções, rótulos curtos, sem "Pronta"', () {
    expect(walletTiposChave, ['CPF', 'CNPJ', 'EMAIL', 'TELEFONE', 'ALEATORIA']);
    expect(
      [for (final tipo in walletTiposChave) walletTipoCurto(tipo)],
      ['CPF', 'CNPJ', 'E-mail', 'Celular', 'Aleatória'],
    );
  });
}
