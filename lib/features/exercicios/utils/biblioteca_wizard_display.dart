import '../data/enums.dart';
import '../data/exercicio_taxonomy_labels.dart';

String bibliotecaChoiceValue(bool on) => on ? 'Sim' : 'Não';

String bibliotecaModalidadeIcon(Modalidade modalidade) {
  return switch (modalidade) {
    Modalidade.musculacao => 'dumbbell',
    Modalidade.mobilidade => 'spark',
    Modalidade.cardio => 'flame',
  };
}

String bibliotecaEspacoIcon(Espaco espaco) {
  return switch (espaco) {
    Espaco.academiaCompleta => 'dumbbell',
    Espaco.academiaBasica => 'target',
    Espaco.casaEquipada => 'home',
    Espaco.casaSemEquipo => 'article',
    Espaco.outdoor => 'sun',
  };
}

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
