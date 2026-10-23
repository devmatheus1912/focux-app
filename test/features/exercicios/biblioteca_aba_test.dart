import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/utils/biblioteca_aba.dart';

Exercicio _ex({int? curatedId, bool curado = false, String? videoSource, String? license}) {
  return Exercicio.fromJson({
    'id': 1,
    'nome': 'Supino reto',
    'curado': curado,
    'curatedId': curatedId,
    'videoSource': videoSource,
    'licenseStatus': license,
  });
}

void main() {
  test('catálogo da Focux cai na Biblioteca', () {
    final ex = _ex(curatedId: 4, curado: true, videoSource: 'FOCUX_LIBRARY');
    expect(exercicioNaAba(ex, BibliotecaAba.focux), isTrue);
    expect(exercicioNaAba(ex, BibliotecaAba.meus), isFalse);
    expect(videoFocuxIntocado(ex), isTrue);
  });

  test('exercício sem curatedId cai em Meus exercícios', () {
    final ex = _ex(videoSource: 'PERSONAL_UPLOAD', license: 'PERSONAL_OWNED');
    expect(exercicioNaAba(ex, BibliotecaAba.meus), isTrue);
    expect(exercicioNaAba(ex, BibliotecaAba.focux), isFalse);
  });
}
