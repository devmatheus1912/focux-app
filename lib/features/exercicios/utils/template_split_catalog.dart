import '../data/template_splits.dart';

/// Seção do catálogo — lógica pura para testes e UI.
class TemplateSplitSection {
  const TemplateSplitSection({
    required this.grupo,
    required this.items,
  });

  final TemplateSplitGroup grupo;
  final List<TemplateSplit> items;

  String get header => grupo.header;
  String get caption => grupo.caption;
}

/// Agrupa [templateSplits] na ordem dos grupos (agenda do aluno).
List<TemplateSplitSection> buildTemplateSplitSections([
  List<TemplateSplit> source = templateSplits,
]) {
  final byGroup = <TemplateSplitGroup, List<TemplateSplit>>{
    for (final g in TemplateSplitGroup.values) g: <TemplateSplit>[],
  };
  for (final split in source) {
    byGroup[split.grupo]!.add(split);
  }
  return [
    for (final g in TemplateSplitGroup.values)
      if (byGroup[g]!.isNotEmpty)
        TemplateSplitSection(grupo: g, items: List.unmodifiable(byGroup[g]!)),
  ];
}

/// Linha do tile: benefício curto + frequência + contagem.
String templateSplitTileSubtitle(TemplateSplit template) {
  final dias = template.dias.length;
  final slots = template.slotsCount;
  final meta =
      '${template.diasSemana}x/sem · '
      '$dias ${dias == 1 ? 'bloco' : 'blocos'} · '
      '$slots ${slots == 1 ? 'exercício' : 'exercícios'}';
  final desc = template.descricao.trim();
  if (desc.isEmpty) return meta;
  return '$desc · $meta';
}
