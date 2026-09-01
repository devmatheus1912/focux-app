import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/models/curated_biblioteca.dart';
import 'package:focux_app/features/exercicios/utils/biblioteca_wizard_display.dart';

void main() {
  test('bibliotecaChoiceValue', () {
    expect(bibliotecaChoiceValue(true), 'Sim');
    expect(bibliotecaChoiceValue(false), 'Não');
  });

  test('bibliotecaPreviewTitle', () {
    expect(bibliotecaPreviewTitle(0), 'Nenhum exercício encontrado');
    expect(bibliotecaPreviewTitle(1), '1 exercício encontrado');
    expect(bibliotecaPreviewTitle(12), '12 exercícios encontrados');
  });

  test('bibliotecaImportSuccess', () {
    expect(bibliotecaImportSuccess(0), 'Nenhum exercício carregado.');
    expect(bibliotecaImportSuccess(1), '1 exercício carregado.');
    expect(bibliotecaImportSuccess(8), '8 exercícios carregados.');
  });

  test('bibliotecaPreviewSubtitle junta modalidades e espaços', () {
    final text = bibliotecaPreviewSubtitle(
      {Modalidade.musculacao, Modalidade.cardio},
      {Espaco.outdoor},
    );
    expect(text, contains('Musculação'));
    expect(text, contains('Cardio'));
    expect(text, contains('Outdoor'));
  });

  test('CuratedBibliotecaPreview.fromJson', () {
    expect(
      CuratedBibliotecaPreview.fromJson({'totalCandidatos': 7}).totalCandidatos,
      7,
    );
    expect(CuratedBibliotecaPreview.fromJson({}).totalCandidatos, 0);
  });
}
