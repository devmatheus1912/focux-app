import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/pacotes/data/pacote_repository.dart';

void main() {
  test('PacotesHomeBundle parses pacotes + perfil slug', () {
    final bundle = PacotesHomeBundle.fromJson({
      'pacotes': [
        {
          'id': 1,
          'titulo': 'Musculação',
          'valor': 150,
          'duracaoMeses': 3,
          'incluiTreino': true,
          'incluiNutri': false,
          'incluiConsultoria': false,
          'destaque': true,
          'ativo': true,
        },
      ],
      'perfil': {'slug': 'ana-silva', 'nome': 'Ana Silva'},
    });
    expect(bundle.pacotes, hasLength(1));
    expect(bundle.pacotes.first.titulo, 'Musculação');
    expect(bundle.pacotes.first.valor, 150);
    expect(bundle.perfil?.slug, 'ana-silva');
    expect(bundle.perfil?.nome, 'Ana Silva');
  });

  test('PacotesHomeBundle tolerates missing perfil', () {
    final bundle = PacotesHomeBundle.fromJson({'pacotes': []});
    expect(bundle.pacotes, isEmpty);
    expect(bundle.perfil, isNull);
  });
}
