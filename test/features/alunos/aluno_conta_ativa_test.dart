import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  // ── Modelo ─────────────────────────────────────────────────────────────────

  group('Aluno.contaAtiva', () {
    test('default é false quando campo ausente no JSON', () {
      final aluno = Aluno.fromJson({
        'id': 1,
        'nome': 'João',
        'email': 'joao@test.com',
        'status': 'ATIVO',
      });
      expect(aluno.contaAtiva, isFalse);
    });

    test('lê true do JSON quando backend envia true', () {
      final aluno = Aluno.fromJson({
        'id': 2,
        'nome': 'Maria',
        'email': 'maria@test.com',
        'status': 'ATIVO',
        'contaAtiva': true,
      });
      expect(aluno.contaAtiva, isTrue);
    });

    test('lê false do JSON quando backend envia false', () {
      final aluno = Aluno.fromJson({
        'id': 3,
        'nome': 'Pedro',
        'email': 'pedro@test.com',
        'status': 'ATIVO',
        'contaAtiva': false,
      });
      expect(aluno.contaAtiva, isFalse);
    });
  });

  // ── Contrato do card ────────────────────────────────────────────────────────

  test('aluno_list_card exibe badge de aguardando ativação para contaAtiva=false', () {
    final source = readScreenSourceBundle(
        'lib/features/alunos/widgets/aluno_list_card.dart');
    expect(source, contains('contaAtiva'));
    expect(source, contains('Aguardando ativação'));
    // badge só aparece para ATIVO sem conta ativa
    expect(source, contains('alunoStatusAtivo'));
  });

  test('aluno_list_card não mostra badge quando contaAtiva é true', () {
    final source = readScreenSourceBundle(
        'lib/features/alunos/widgets/aluno_list_card.dart');
    // A condição é negada: !aluno.contaAtiva
    expect(source, contains('!aluno.contaAtiva'));
  });
}
