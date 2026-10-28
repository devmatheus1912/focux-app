import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno_invite_copy.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  final s = lookupS(const Locale('pt'));
  const link = 'https://example.com/aluno/ativar/abc';

  test('convite usa primeiro nome e link, sem senha', () {
    final text = alunoAtivacaoMessage(s, nome: 'Nathalia Costa', link: link);
    expect(text, contains('Olá Nathalia!'));
    expect(text, contains(link));
    expect(text, contains('7 dias'));
    expect(text.toLowerCase(), isNot(contains('senha provisória')));
  });

  test('reenvio avisa que é um novo link', () {
    final text = alunoAtivacaoMessage(
      s,
      nome: 'Nathalia Costa',
      link: link,
      reenvio: true,
    );
    expect(text, contains('novo link'));
    expect(text, contains(link));
  });

  test('sem nome usa saudação genérica', () {
    expect(
      alunoAtivacaoMessage(s, nome: ' ', link: link),
      contains('Olá aluno!'),
    );
  });

  group('convite com a marca do personal', () {
    test('diz quem cadastrou e o nome do app', () {
      final text = alunoAtivacaoMessage(
        s,
        nome: 'Nathalia Costa',
        link: link,
        marca: const ConviteMarca(nomePersonal: 'Matheus Teste'),
      );
      expect(text, contains('Olá Nathalia! Matheus Teste te cadastrou no Focux.'));
      expect(text, contains(link));
      expect(text, contains('7 dias'));
    });

    test('white-label: app com o nome do personal e slogan entre aspas', () {
      final text = alunoAtivacaoMessage(
        s,
        nome: 'Ana',
        link: link,
        marca: const ConviteMarca(
          nomePersonal: 'Matheus Teste',
          nomeApp: 'Studio Força',
          slogan: 'Treino com método',
        ),
      );
      expect(text, contains('Matheus Teste te cadastrou no Studio Força.'));
      expect(text, contains('“Treino com método”'));
      expect(text, isNot(contains('Focux')));
    });

    test('sem slogan não deixa linha vazia sobrando', () {
      final text = alunoAtivacaoMessage(
        s,
        nome: 'Ana',
        link: link,
        marca: const ConviteMarca(nomePersonal: 'Matheus', slogan: '  '),
      );
      expect(text, isNot(contains('“')));
      expect(text.split('\n').take(2).last, isEmpty); // 1 linha em branco só
    });

    test('reenvio com marca fala do app e não do cadastro', () {
      final text = alunoAtivacaoMessage(
        s,
        nome: 'Ana',
        link: link,
        reenvio: true,
        marca: const ConviteMarca(nomePersonal: 'Matheus', nomeApp: 'Studio Força'),
      );
      expect(text, contains('novo link de acesso ao Studio Força'));
      expect(text, contains(link));
    });

    test('personal sem nome volta ao convite padrão', () {
      final padrao = alunoAtivacaoMessage(s, nome: 'Ana', link: link);
      final semNome = alunoAtivacaoMessage(
        s,
        nome: 'Ana',
        link: link,
        marca: const ConviteMarca(nomePersonal: '  '),
      );
      expect(semNome, padrao);
    });
  });
}
