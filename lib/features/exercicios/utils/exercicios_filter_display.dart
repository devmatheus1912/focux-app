import '../data/exercicio_taxonomy_labels.dart';
import '../models/exercicios_ui_filter.dart';

const exerciciosFilterDebounceMs = 400;

String exerciciosSearchHint() => 'Nome do exercício';

String exerciciosSearchLabel() => 'Buscar na biblioteca';

String exerciciosFiltrosHeader() => 'Filtros';

String exerciciosFiltrosTodos() => 'Nenhum';

String exerciciosLimparFiltros() => 'Limpar filtros';

String exerciciosModalidadeTodas() => 'Todas';

String exerciciosGrupoTodos() => 'Todos';

String exerciciosEquipamentoTodos() => 'Todos';

String exerciciosNivelTodos() => 'Todos';

String exerciciosFavoritosLabel() => 'Favoritos';

String exerciciosComVideoLabel() => 'Com vídeo';

String exerciciosSemVideoLabel() => 'Sem vídeo';

String exerciciosVideoTodosLabel() => 'Qualquer vídeo';

String exerciciosCountLabel(int count) {
  if (count <= 0) return 'Nenhum exercício';
  if (count == 1) return '1 exercício';
  return '$count exercícios';
}

String exerciciosFilterSummary(ExerciciosUiFilter filter) {
  final parts = <String>[
    if (filter.modalidade != null)
      TaxonomyLabels.modalidade[filter.modalidade] ?? '',
    if (filter.grupo != null) TaxonomyLabels.grupo[filter.grupo] ?? '',
    if (filter.equipamento != null)
      TaxonomyLabels.equipamento[filter.equipamento] ?? '',
    if (filter.dificuldade != null)
      TaxonomyLabels.dificuldade[filter.dificuldade] ?? '',
    if (filter.favoritos) exerciciosFavoritosLabel(),
    if (filter.comVideo) exerciciosComVideoLabel(),
    if (filter.semVideo) exerciciosSemVideoLabel(),
  ].where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return exerciciosFiltrosTodos();
  if (parts.length == 1) return parts.first;
  return '${parts.first} +${parts.length - 1}';
}

String exerciciosEnumValue<T extends Enum>(
  T? value,
  Map<T, String> labels,
  String empty,
) {
  if (value == null) return empty;
  return labels[value] ?? value.name;
}
