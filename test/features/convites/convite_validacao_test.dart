import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/convites/data/convite_repository.dart';

void main() {
  test('ConviteValidacao mapeia slug e mensagem', () {
    final v = ConviteValidacao.fromJson({
      'valido': true,
      'personalNome': 'Studio X',
      'personalSlug': 'studio-x',
      'mensagem': null,
    });
    expect(v.valido, isTrue);
    expect(v.personalNome, 'Studio X');
    expect(v.personalSlug, 'studio-x');
  });

  test('ConviteValidacao aceita campo slug legado', () {
    final v = ConviteValidacao.fromJson({
      'valido': true,
      'slug': 'joao',
    });
    expect(v.personalSlug, 'joao');
  });

  test('Convite.shareLink prefere webLink', () {
    final c = Convite(
      token: 'abc',
      link: 'focux://convite/abc',
      webLink: 'https://focuxpersonal.com/convite/abc',
    );
    expect(c.shareLink, 'https://focuxpersonal.com/convite/abc');
  });
}
