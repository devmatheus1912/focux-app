import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/models/migracao_importacao_resumo.dart';

void main() {
  MigracaoImportacaoDetalhe aluno({
    required String nome,
    String? email,
    String? telefone,
    bool emailEnviado = false,
    bool emailReal = false,
  }) =>
      MigracaoImportacaoDetalhe(
        nome: nome,
        status: 'IMPORTADO',
        linkAtivacao: 'https://focuxpersonal.com/aluno/ativar/tok',
        email: email,
        telefone: telefone,
        emailEnviado: emailEnviado,
        emailReal: emailReal,
      );

  MigracaoImportacaoResumo resumo(List<MigracaoImportacaoDetalhe> detalhes) =>
      MigracaoImportacaoResumo(
        importados: detalhes.length,
        duplicados: 0,
        erros: 0,
        detalhes: detalhes,
      );

  group('MigracaoImportacaoResumo — grupos pelo que aconteceu', () {
    test('cada aluno cai num grupo só', () {
      final r = resumo([
        aluno(nome: 'Ana', email: 'ana@email.com', emailReal: true, emailEnviado: true),
        aluno(nome: 'Bia', email: 'bia@email.com', emailReal: true),
        aluno(nome: 'Carlos', telefone: '11999990000'),
        aluno(nome: 'Pedro'),
      ]);

      expect(r.emailEnviadoAutomaticamente.map((d) => d.nome), ['Ana']);
      expect(r.emailNaoSaiu.map((d) => d.nome), ['Bia']);
      expect(r.soTelefone.map((d) => d.nome), ['Carlos']);
      expect(r.semContato.map((d) => d.nome), ['Pedro']);
    });

    test('tem e-mail real e o envio falhou: "e-mail não saiu", mesmo sem telefone', () {
      final r = resumo([aluno(nome: 'Lucia', email: 'lucia@email.com', emailReal: true)]);

      expect(r.emailNaoSaiu, hasLength(1));
      expect(r.semContato, isEmpty);
      expect(r.soTelefone, isEmpty);
    });

    test('tem e-mail real e telefone, envio falhou: continua em "e-mail não saiu"', () {
      final r = resumo([
        aluno(nome: 'Rui', email: 'rui@email.com', emailReal: true, telefone: '11988887777'),
      ]);

      expect(r.emailNaoSaiu, hasLength(1));
      expect(r.soTelefone, isEmpty);
    });

    test('aluno só com nome vai para "sem contato"', () {
      final r = resumo([aluno(nome: 'Marcos')]);

      expect(r.semContato, hasLength(1));
      expect(r.emailEnviadoAutomaticamente, isEmpty);
      expect(r.emailNaoSaiu, isEmpty);
      expect(r.soTelefone, isEmpty);
    });

    test('os grupos somam todos os importados com link', () {
      final detalhes = [
        for (var i = 0; i < 5; i++)
          aluno(nome: 'A$i', email: 'a$i@e.com', emailReal: true, emailEnviado: true),
        for (var i = 0; i < 2; i++) aluno(nome: 'F$i', email: 'f$i@e.com', emailReal: true),
        for (var i = 0; i < 3; i++) aluno(nome: 'B$i', telefone: '1199999000$i'),
        aluno(nome: 'C1'),
        aluno(nome: 'C2'),
      ];
      final r = resumo(detalhes);

      expect(r.emailEnviadoAutomaticamente, hasLength(5));
      expect(r.emailNaoSaiu, hasLength(2));
      expect(r.soTelefone, hasLength(3));
      expect(r.semContato, hasLength(2));
      expect(
        r.emailEnviadoAutomaticamente.length +
            r.emailNaoSaiu.length +
            r.soTelefone.length +
            r.semContato.length,
        r.importadosComAcesso.length,
      );
    });

    test('fromJson lê emailEnviado, emailReal e emailFalha', () {
      final d = MigracaoImportacaoDetalhe.fromJson({
        'nome': 'Test',
        'status': 'IMPORTADO',
        'linkAtivacao': 'https://test.com/tok',
        'emailEnviado': false,
        'emailReal': true,
        'emailFalha': 'resend-domain',
      });

      expect(d.emailEnviado, isFalse);
      expect(d.emailReal, isTrue);
      expect(d.emailFalha, 'resend-domain');
    });

    test('campos ausentes (servidor antigo) viram falso e nulo', () {
      final d = MigracaoImportacaoDetalhe.fromJson({
        'nome': 'Test',
        'status': 'IMPORTADO',
        'linkAtivacao': 'https://test.com/tok',
      });

      expect(d.emailEnviado, isFalse);
      expect(d.emailReal, isFalse);
      expect(d.emailFalha, isNull);
    });
  });
}
