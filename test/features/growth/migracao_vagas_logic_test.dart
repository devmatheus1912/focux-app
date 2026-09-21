import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/models/migracao_importacao_resumo.dart';
import 'package:focux_app/features/growth/utils/migracao_vagas_logic.dart';

void main() {
  group('MigracaoVagasSnapshot', () {
    test('FREE 3 — cabem 2 novos com 1 atual', () {
      final snap = MigracaoVagasSnapshot(
        alunosAtuais: 1,
        limiteAlunos: 3,
        novosParaImportar: 2,
      );
      expect(snap.cabeNoPlano, isTrue);
      expect(snap.vagasRestantes, 2);
      expect(snap.excedentes, 0);
    });

    test('FREE 3 — 4º aluno estoura', () {
      final snap = MigracaoVagasSnapshot(
        alunosAtuais: 3,
        limiteAlunos: 3,
        novosParaImportar: 1,
      );
      expect(snap.cabeNoPlano, isFalse);
      expect(snap.excedentes, 1);
    });

    test('PRO 30 — batch cabe', () {
      final snap = MigracaoVagasSnapshot(
        alunosAtuais: 10,
        limiteAlunos: 30,
        novosParaImportar: 5,
      );
      expect(snap.cabeNoPlano, isTrue);
    });

    test('Enterprise ilimitado', () {
      final snap = MigracaoVagasSnapshot(
        alunosAtuais: 100,
        limiteAlunos: null,
        novosParaImportar: 50,
      );
      expect(snap.isUnlimited, isTrue);
      expect(snap.cabeNoPlano, isTrue);
      expect(snap.vagasRestantes, isNull);
    });
  });

  group('migracaoVagasHint', () {
    test('mostra vagas restantes quando cabe', () {
      final hint = migracaoVagasHint(
        limiteAlunos: 3,
        alunosAtuais: 1,
        novosParaImportar: 1,
      );
      expect(hint, contains('Cabem'));
      expect(hint, contains('3'));
    });

    test('pede upgrade quando estoura', () {
      final hint = migracaoVagasHint(
        limiteAlunos: 3,
        alunosAtuais: 2,
        novosParaImportar: 3,
      );
      expect(hint, contains('upgrade'));
    });
  });

  group('MigracaoImportacaoDetalhe', () {
    test('parse senha email telefone alunoId', () {
      final d = MigracaoImportacaoDetalhe.fromJson({
        'nome': 'Ana',
        'status': 'IMPORTADO',
        'alunoId': 42,
        'email': 'ana@test.com',
        'telefone': '1199999',
        'senhaProvisoria': 'Ab12Cd34',
      });
      expect(d.alunoId, 42);
      expect(d.email, 'ana@test.com');
      expect(d.senhaProvisoria, 'Ab12Cd34');
    });

    test('importadosComAcesso filtra só com senha', () {
      final resumo = MigracaoImportacaoResumo.fromJson({
        'importados': 2,
        'duplicados': 0,
        'erros': 0,
        'detalhes': [
          {
            'nome': 'A',
            'status': 'IMPORTADO',
            'senhaProvisoria': 'x',
            'email': 'a@t.com',
          },
          {'nome': 'B', 'status': 'DUPLICADO', 'motivo': 'dup'},
          {'nome': 'C', 'status': 'IMPORTADO'},
        ],
      });
      expect(resumo.importadosComAcesso, hasLength(1));
      expect(resumo.importadosComAcesso.first.nome, 'A');
    });
  });
}
