import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/utils/migracao_magica_display.dart';

void main() {
  test('copy da migração confirma análise e gravação', () {
    expect(migracaoIniciarLabel(), 'Analisar texto');
    expect(migracaoIniciarConfirmMessage(), contains('Nada é salvo'));
    expect(migracaoSalvarLabel(3), 'Importar 3 alunos');
    expect(migracaoSalvarLabel(0), 'Selecione alunos');
    expect(migracaoIgnoradasLabel(7), '7 linhas ignoradas');
    expect(migracaoSalvarConfirmTitle(3), contains('3 alunos'));
    expect(
      migracaoSalvarConfirmMessage(),
      'Quem tem e-mail recebe o convite sozinho. Quem só tem telefone fica para o WhatsApp.',
    );
    expect(
      migracaoWhatsappFolha(),
      'Estes só têm telefone. O texto já está copiado.',
    );
    expect(migracaoWhatsappAbrirLabel(), 'Abrir WhatsApp');
    expect(migracaoCopiarConvitesLabel(1), 'Copiar o convite');
    expect(migracaoCopiarConvitesLabel(4), 'Copiar os 4 convites');
    expect(migracaoSalvarConfirmMessage(), isNot(contains('um a um')));
    expect(migracaoEtapaLabel(MigracaoEtapa.acesso), 'Etapa 3 de 3');
    expect(migracaoIrParaListaLabel(), 'Ir para lista');
    expect(migracaoDiscardConfirmLabel(), 'Sair');
  });

  // M2 — mensagem de empty state diferencia foto de planilha/texto
  group('migracaoVazioDica', () {
    test('sem foto: orienta planilha ou print', () {
      final dica = migracaoVazioDica(deFoto: false);
      expect(dica, contains('planilha'));
      expect(dica, isNot(contains('Pouco identificado')));
    });

    test('de foto: orienta tirar foto só da lista', () {
      final dica = migracaoVazioDica(deFoto: true);
      expect(dica, contains('Pouco identificado'));
      expect(dica, contains('lista de alunos'));
      expect(dica, isNot(contains('planilha')));
    });

    test('default deFoto é false', () {
      expect(migracaoVazioDica(), equals(migracaoVazioDica(deFoto: false)));
    });
  });
}
