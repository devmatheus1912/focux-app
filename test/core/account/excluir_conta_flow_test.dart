import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/account/excluir_conta_flow.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

void main() {
  final l10n = SPt();

  group('excluirContaBody', () {
    test('com senha não manda código', () {
      final body = excluirContaBody(
        senha: 'segredo',
        codigo: '123456',
        confirmacao: ' EXCLUIR ',
        usarCodigo: false,
      );
      expect(body, {'senha': 'segredo', 'confirmacao': 'EXCLUIR'});
    });

    test('conta Google/Apple manda só o código', () {
      final body = excluirContaBody(
        senha: '',
        codigo: ' 123456 ',
        confirmacao: 'EXCLUIR',
        usarCodigo: true,
      );
      expect(body, {'codigoEmail': '123456', 'confirmacao': 'EXCLUIR'});
    });
  });

  group('excluirContaErroLocal', () {
    test('exige EXCLUIR', () {
      expect(
        excluirContaErroLocal(
          l10n,
          senha: 'x',
          codigo: '',
          confirmacao: 'excluir',
          usarCodigo: false,
        ),
        'Digite EXCLUIR para confirmar.',
      );
    });

    test('exige senha ou código', () {
      expect(
        excluirContaErroLocal(
          l10n,
          senha: '',
          codigo: '',
          confirmacao: 'EXCLUIR',
          usarCodigo: true,
        ),
        'Informe a senha ou o código que chegou no e-mail.',
      );
    });

    test('ok com código preenchido', () {
      expect(
        excluirContaErroLocal(
          l10n,
          senha: '',
          codigo: '123456',
          confirmacao: 'EXCLUIR',
          usarCodigo: true,
        ),
        isNull,
      );
    });
  });
}
