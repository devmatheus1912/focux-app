import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/biblioteca_wizard_draft.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/models/curated_biblioteca.dart';
import 'package:focux_app/features/exercicios/utils/biblioteca_wizard_display.dart';

void main() {
  tearDown(BibliotecaWizardDraftCache.clear);

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

  test('etapa e pergunta de cada passo', () {
    expect(bibliotecaEtapaLabel(0), 'Etapa 1 de 3');
    expect(bibliotecaEtapaLabel(2), 'Etapa 3 de 3');
    expect(bibliotecaQuestionTitle(0), contains('modalidades'));
    expect(bibliotecaContinueLabel(step: 0), 'Continuar');
    expect(bibliotecaContinueLabel(step: 2), 'Carregar biblioteca');
  });

  test('rascunho retoma etapa e escolhas', () {
    BibliotecaWizardDraftCache.put(
      const BibliotecaWizardDraft(
        step: 1,
        modalidades: {Modalidade.cardio},
        espacos: {Espaco.outdoor},
      ),
    );
    final draft = BibliotecaWizardDraftCache.get();
    expect(draft?.step, 1);
    expect(draft?.modalidades, {Modalidade.cardio});
    expect(draft?.espacos, {Espaco.outdoor});
  });

  test('CuratedBibliotecaPreview.fromJson', () {
    expect(
      CuratedBibliotecaPreview.fromJson({'totalCandidatos': 7}).totalCandidatos,
      7,
    );
    expect(CuratedBibliotecaPreview.fromJson({}).totalCandidatos, 0);
  });
}
