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

    MigracaoFileParseResult ler(String csv, [String nome = 'alunos.csv']) =>
        MigracaoFileParser.parse(
          bytes: Uint8List.fromList(utf8.encode(csv)),
          filename: nome,
        );

    test('sem cabeçalho, a coluna de número de linha é ignorada', () {
      final r = ler('1,Maria Silva,11988887777,maria@x.com\n2,Carlos Lima,11977776666,');

      final alunos = r.directAlunos!;
      expect(alunos.map((a) => a.nome), ['Maria Silva', 'Carlos Lima']);
      expect(alunos.first.email, 'maria@x.com');
      expect(alunos.first.objetivo, isNull);
    });

    test('colunas "Nome" e "Sobrenome" se juntam', () {
      final r = ler('Nome,Sobrenome,Email\nMaria,Silva,maria@x.com\nJoão,Pedro Souza,joao@x.com');

      expect(r.directAlunos!.map((a) => a.nome), ['Maria Silva', 'João Pedro Souza']);
      expect(r.colunas!.sobrenome, 1);
    });

    test('cabeçalho de outro app ("Cliente", "Celular") continua lido', () {
      final r = ler('Cliente;Plano;Status;Celular;E-mail\nMaria Silva;Mensal;Ativo;(11) 98888-7777;maria@x.com');

      final a = r.directAlunos!.single;
      expect(a.nome, 'Maria Silva');
      expect(a.telefone, '(11) 98888-7777');
      expect(a.email, 'maria@x.com');
      expect(r.colunas!.objetivo, isNull);
    });

    test('nome da planilha sai sem status, número de lista e traço', () {
      final r = ler('Nome,Email\n1. Maria Silva Ativo,maria@x.com\nguilherme -,g@x.com');

      expect(r.directAlunos!.map((a) => a.nome), ['Maria Silva', 'guilherme']);
    });

    test('objetivo no meio do nome vira objetivo', () {
      final r = ler('Nome,Email\nFernanda Alves emagrecimento,f@x.com');

      final a = r.directAlunos!.single;
      expect(a.nome, 'Fernanda Alves');
      expect(a.objetivo, 'Emagrecimento');
    });

    test('a coluna de objetivo manda sobre a palavra achada no nome', () {
      final r = ler('Nome,Email,Objetivo\nFernanda Alves hipertrofia,f@x.com,Saúde');

      expect(r.directAlunos!.single.objetivo, 'Saúde');
    });

    test('coluna de telefone com número pequeno não é tratada como numeração', () {
      final r = ler('Maria Silva,11988887777,maria@x.com\nCarlos Lima,11977776666,');

      expect(r.directAlunos!.map((a) => a.nome), ['Maria Silva', 'Carlos Lima']);
      expect(r.directAlunos!.first.telefone, '11988887777');
    });
  });
}
