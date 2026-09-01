import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/captura/utils/leads_publicos_display.dart';

void main() {
  test('leadPublicoNome não fica vazio', () {
    expect(leadPublicoNome('ana silva'), 'Ana Silva');
    expect(leadPublicoNome('  '), 'Lead');
    expect(leadPublicoNome(null), 'Lead');
  });

  test('leadPublicoSubtitle junta contato', () {
    expect(
      leadPublicoSubtitle(
        telefone: '11999999999',
        email: 'a@b.com',
        objetivo: 'Emagrecer',
      ),
      '11999999999 · a@b.com · Emagrecer',
    );
    expect(leadPublicoSubtitle(), 'Sem contato extra');
  });

  test('leadPublico status e criar aluno', () {
    expect(leadPublicoValue(true), 'Convertido');
    expect(leadPublicoValue(false), 'Novo');
    expect(leadPublicoFxIcon(true), 'circle-check');
    expect(leadPublicoFxIcon(false), 'users');
    expect(leadPublicoPodeCriarAluno('a@b.com'), isTrue);
    expect(leadPublicoPodeCriarAluno('  '), isFalse);
    expect(leadPublicoPodeCriarAluno(null), isFalse);
  });

  test('leadPublicoHubSubtitle junta freshness', () {
    expect(
      leadPublicoHubSubtitle(null),
      'Contatos captados pela sua página',
    );
    expect(
      leadPublicoHubSubtitle('há 1 min'),
      'Contatos captados pela sua página · há 1 min',
    );
  });
}
