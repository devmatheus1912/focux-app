import '../data/enums.dart';
import '../data/exercicio_taxonomy_labels.dart';

const int bibliotecaWizardVisibleSteps = 3;

String bibliotecaEtapaLabel(int step, {int total = bibliotecaWizardVisibleSteps}) {
  final safeTotal = total <= 0 ? 1 : total;
  final current = step >= safeTotal ? safeTotal : step + 1;
  return 'Etapa $current de $safeTotal';
}

String bibliotecaQuestionTitle(int step) {
  return switch (step) {
    0 => 'Quais modalidades você usa?',
    1 => 'Onde seus alunos treinam?',
    2 => 'Carregar esta biblioteca?',
    _ => 'Carregando biblioteca',
  };
}

String bibliotecaQuestionCaption(int step) {
  return switch (step) {
    0 => 'A biblioteca vem pronta. Escolha o que faz sentido agora.',
    1 => 'Filtra exercícios por equipamento e ambiente.',
    2 =>
      'Vamos carregar exercícios com taxonomia pronta. Vídeos entram para curadoria quando ainda não forem seus.',
    _ => 'Isso leva alguns segundos.',
  };
}

String bibliotecaContinueLabel({required int step}) =>
    step >= 2 ? 'Carregar biblioteca' : 'Continuar';

String bibliotecaVoltarLabel() => 'Voltar';

String bibliotecaPularLabel() => 'Pular';

String bibliotecaPreviewTitle(int total) {
  if (total <= 0) return 'Nenhum exercício encontrado';
  if (total == 1) return '1 exercício encontrado';
  return '$total exercícios encontrados';
}

String bibliotecaImportSuccess(int importados) {
  if (importados <= 0) return 'Nenhum exercício carregado.';
  if (importados == 1) return '1 exercício carregado.';
  return '$importados exercícios carregados.';
}

String bibliotecaJoinedLabels<T>(Set<T> values, Map<T, String> labels) {
  return values.map((value) => labels[value]).whereType<String>().join(', ');
}

String bibliotecaPreviewSubtitle(
  Set<Modalidade> modalidades,
  Set<Espaco> espacos,
) {
  return [
    bibliotecaJoinedLabels(modalidades, TaxonomyLabels.modalidade),
    bibliotecaJoinedLabels(espacos, TaxonomyLabels.espaco),
  ].where((part) => part.isNotEmpty).join('\n');
}

String bibliotecaHelpTitle() => 'Biblioteca curada';

String bibliotecaHelpSubtitle() =>
    'Três etapas. Suas escolhas ficam se você sair e voltar.';

String bibliotecaHelpPassosBody() =>
    'Marque modalidades e espaços. Continuar avança; Voltar corrige. Pular fecha sem importar.';
