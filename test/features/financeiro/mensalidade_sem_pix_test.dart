import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/money/fx_money.dart';
import 'package:focux_app/features/financeiro/utils/mensalidade_surface_actions.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';

PerfilPersonal _perfil(String? chave) => PerfilPersonal.fromJson({
  'id': 1,
  'nome': 'Ana',
  'email': 'a@a.com',
  'plano': 'PRO',
  'chavePix': chave,
});

void main() {
  group('lançar mensalidade sem chave PIX', () {
    test('sem chave (nula, vazia ou só espaço) avisa antes', () {
      expect(mensalidadeLancarPrecisaAvisoPix(_perfil(null)), isTrue);
      expect(mensalidadeLancarPrecisaAvisoPix(_perfil('')), isTrue);
      expect(mensalidadeLancarPrecisaAvisoPix(_perfil('   ')), isTrue);
    });

    test('com chave ou perfil ainda não carregado não avisa', () {
      expect(
        mensalidadeLancarPrecisaAvisoPix(_perfil('ana@coach.com')),
        isFalse,
      );
      expect(mensalidadeLancarPrecisaAvisoPix(null), isFalse);
    });

    test('confirmação ganha a linha do PIX só quando falta a chave', () {
      final venc = DateTime(2026, 12, 10);
      final valor = FxMoney.parse(150);
      final comPix = mensalidadeConfirmacaoTexto(
        aluno: 'Bruno',
        valor: valor,
        vencimento: venc,
      );
      final semPix = mensalidadeConfirmacaoTexto(
        aluno: 'Bruno',
        valor: valor,
        vencimento: venc,
        avisoSemPix: 'Sem PIX: o aluno combina o pagamento com você.',
      );
      expect(comPix, isNot(contains('PIX')));
      expect(semPix, startsWith(comPix));
      expect(
        semPix,
        endsWith('Sem PIX: o aluno combina o pagamento com você.'),
      );
    });
  });
}
