import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/utils/migracao_file_parser.dart';

void main() {
  group('MigracaoFileParser', () {
    test('parseia CSV com cabeçalho conhecido', () {
      const csv = 'nome,email,telefone,objetivo\n'
          'Ana Silva,ana@test.com,11999998888,Hipertrofia\n'
          'Bruno Costa,,11988887777,Emagrecimento\n';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'alunos.csv',
      );

      expect(result.usesDirectParse, isTrue);
      expect(result.directAlunos, hasLength(2));
      expect(result.directAlunos!.first.nome, 'Ana Silva');
      expect(result.directAlunos!.first.email, 'ana@test.com');
      expect(result.directAlunos!.first.telefone, '11999998888');
      expect(result.directAlunos!.first.objetivo, 'Hipertrofia');
    });

    test('parseia CSV com ponto e vírgula', () {
      const csv = 'Nome;E-mail;Celular\nJoão;joao@test.com;21999990000';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'lista.csv',
      );

      expect(result.usesDirectParse, isTrue);
      expect(result.directAlunos!.single.nome, 'João');
      expect(result.directAlunos!.single.email, 'joao@test.com');
    });

    test('texto livre em TXT vai para IA', () {
      const text = 'Maria Souza — maria@gmail.com — emagrecimento';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(text)),
        filename: 'notas.txt',
      );

      expect(result.usesDirectParse, isFalse);
      expect(result.textForIa, contains('Maria Souza'));
    });

    test('cabeçalho casa palavra inteira, não pedaço', () {
      const csv = 'Nome,Hotel preferido,Telefone celular\n'
          'Ana Silva,Ibis,11999998888\n';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'alunos.csv',
      );

      expect(result.colunas!.telefone, 2);
      expect(result.directAlunos!.single.telefone, '11999998888');
    });

    test('Tel. abreviado é telefone', () {
      const csv = 'Nome,Tel.,E-mail\nAna Silva,11999998888,ana@example.com\n';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'alunos.csv',
      );

      expect(result.colunas!.telefone, 1);
      expect(result.colunas!.email, 2);
    });

    test('reaplicar colunas troca o mapeamento', () {
      const csv = 'Aluno,Contato,Obs\nAna Silva,11999998888,Treina cedo\n';
      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'alunos.csv',
      );

      final remapeado = MigracaoFileParser.reaplicarColunas(
        result,
        const MigracaoColunas(nome: 0, telefone: 1, objetivo: 2),
      );

      expect(remapeado.directAlunos!.single.telefone, '11999998888');
      expect(remapeado.directAlunos!.single.objetivo, 'Treina cedo');
    });

    test('linhas de documento sem cabeçalho não viram alunos', () {
      const csv = 'EMENTA: Conforme art. 10, Medida\nde janeiro de 2002, Código Civil\n';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'doc.csv',
      );

      expect(result.usesDirectParse, isFalse);
    });

    test('linha duvidosa entra desmarcada', () {
      const csv = 'nome,email\nAna,\nBruno Costa,bruno@example.com\n';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'alunos.csv',
      );

      final ana = result.directAlunos!.firstWhere((a) => a.nome == 'Ana');
      expect(ana.selecionado, isFalse);
      expect(result.directAlunos!.last.selecionado, isTrue);
    });

    test('CSV sem colunas reconhecíveis cai para texto IA', () {
      const csv = 'coluna_a,coluna_b\nfoo,bar';

      final result = MigracaoFileParser.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'weird.csv',
      );

      expect(result.usesDirectParse, isFalse);
      expect(result.textForIa, contains('foo'));
    });
  });
}
