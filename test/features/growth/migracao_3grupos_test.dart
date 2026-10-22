import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/models/migracao_importacao_resumo.dart';

void main() {
  MigracaoImportacaoDetalhe aluno({
    required String nome,
    String? email,
    String? telefone,
    bool emailEnviado = false,
  }) =>
      MigracaoImportacaoDetalhe(
        nome: nome,
        status: 'IMPORTADO',
        linkAtivacao: 'https://focuxpersonal.com/aluno/ativar/tok',
        email: email,
        telefone: telefone,
        emailEnviado: emailEnviado,
      );

  group('MigracaoImportacaoResumo — agrupamento 3 grupos', () {
    test('emailEnviadoAutomaticamente só contém alunos com emailEnviado=true', () {
      final resumo = MigracaoImportacaoResumo(
        importados: 3,
        duplicados: 0,
        erros: 0,
        detalhes: [
          aluno(nome: 'Ana', email: 'ana@email.com', emailEnviado: true),
          aluno(nome: 'Carlos', telefone: '11999990000', emailEnviado: false),
          aluno(nome: 'Pedro', emailEnviado: false),
        ],
      );

      expect(resumo.emailEnviadoAutomaticamente.map((d) => d.nome), ['Ana']);
      expect(resumo.enviarViaWhatsapp.map((d) => d.nome), ['Carlos']);
      expect(resumo.enviarManualmente.map((d) => d.nome), ['Pedro']);
    });

    test('aluno só com nome (sem telefone, sem email) vai para enviarManualmente', () {
      final resumo = MigracaoImportacaoResumo(
        importados: 1,
        duplicados: 0,
        erros: 0,
        detalhes: [aluno(nome: 'Marcos')],
      );

      expect(resumo.enviarManualmente, hasLength(1));
      expect(resumo.emailEnviadoAutomaticamente, isEmpty);
      expect(resumo.enviarViaWhatsapp, isEmpty);
    });

    test('aluno com email real e emailEnviado=false vai para enviarManualmente se sem telefone', () {
      final resumo = MigracaoImportacaoResumo(
        importados: 1,
        duplicados: 0,
        erros: 0,
        detalhes: [
          aluno(
            nome: 'Lucia',
            email: 'lucia@email.com',
            emailEnviado: false,
          ),
        ],
      );

      // Sem telefone → manualmente (backend não enviou e não tem número)
      expect(resumo.enviarManualmente, hasLength(1));
    });

    test('grupos somam corretamente com mix de 10 alunos', () {
      final detalhes = [
        aluno(nome: 'A1', email: 'a1@e.com', emailEnviado: true),
        aluno(nome: 'A2', email: 'a2@e.com', emailEnviado: true),
        aluno(nome: 'A3', email: 'a3@e.com', emailEnviado: true),
        aluno(nome: 'A4', email: 'a4@e.com', emailEnviado: true),
        aluno(nome: 'A5', email: 'a5@e.com', emailEnviado: true),
        aluno(nome: 'B1', telefone: '11999990001'),
        aluno(nome: 'B2', telefone: '11999990002'),
        aluno(nome: 'B3', telefone: '11999990003'),
        aluno(nome: 'C1'),
        aluno(nome: 'C2'),
      ];
      final resumo = MigracaoImportacaoResumo(
        importados: 10,
        duplicados: 0,
        erros: 0,
        detalhes: detalhes,
      );

      expect(resumo.emailEnviadoAutomaticamente, hasLength(5));
      expect(resumo.enviarViaWhatsapp, hasLength(3));
      expect(resumo.enviarManualmente, hasLength(2));
      expect(
        resumo.emailEnviadoAutomaticamente.length +
            resumo.enviarViaWhatsapp.length +
            resumo.enviarManualmente.length,
        equals(resumo.importadosComAcesso.length),
      );
    });

    test('fromJson parseia emailEnviado', () {
      final json = {
        'nome': 'Test',
        'status': 'IMPORTADO',
        'linkAtivacao': 'https://test.com/tok',
        'emailEnviado': true,
      };
      final d = MigracaoImportacaoDetalhe.fromJson(json);
      expect(d.emailEnviado, isTrue);
    });

    test('fromJson emailEnviado ausente vira false', () {
      final json = {
        'nome': 'Test',
        'status': 'IMPORTADO',
        'linkAtivacao': 'https://test.com/tok',
      };
      final d = MigracaoImportacaoDetalhe.fromJson(json);
      expect(d.emailEnviado, isFalse);
    });
  });
}
