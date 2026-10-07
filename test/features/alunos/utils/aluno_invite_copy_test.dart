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
}
