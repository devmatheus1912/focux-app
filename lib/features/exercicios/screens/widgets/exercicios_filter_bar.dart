import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

class ExerciciosUiFilter {
  final String query;
  final Modalidade? modalidade;
  final GrupoMuscular? grupo;
  final Equipamento? equipamento;
  final Dificuldade? dificuldade;
  final bool favoritos;
  final bool comVideo;
  final bool semVideo;

  const ExerciciosUiFilter({
    this.query = '',
    this.modalidade,
    this.grupo,
    this.equipamento,
    this.dificuldade,
    this.favoritos = false,
    this.comVideo = false,
    this.semVideo = false,
  });

  bool get hasActive =>
      query.trim().isNotEmpty ||
      modalidade != null ||
      grupo != null ||
      equipamento != null ||
      dificuldade != null ||
      favoritos ||
      comVideo ||
      semVideo;

  ExerciciosUiFilter copyWith({
    String? query,
    Modalidade? modalidade,
    GrupoMuscular? grupo,
    Equipamento? equipamento,
    Dificuldade? dificuldade,
    bool? favoritos,
    bool? comVideo,
    bool? semVideo,
    bool clearModalidade = false,
    bool clearGrupo = false,
    bool clearEquipamento = false,
    bool clearDificuldade = false,
  }) {
    return ExerciciosUiFilter(
      query: query ?? this.query,
      modalidade: clearModalidade ? null : (modalidade ?? this.modalidade),
      grupo: clearGrupo ? null : (grupo ?? this.grupo),
      equipamento: clearEquipamento ? null : (equipamento ?? this.equipamento),
      dificuldade: clearDificuldade ? null : (dificuldade ?? this.dificuldade),
      favoritos: favoritos ?? this.favoritos,
      comVideo: comVideo ?? this.comVideo,
      semVideo: semVideo ?? this.semVideo,
    );
  }
}

class ExerciciosFilterBar extends StatelessWidget {
  const ExerciciosFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.onClear,
  });

  final ExerciciosUiFilter filter;
  final ValueChanged<ExerciciosUiFilter> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar exercicio por nome',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  filter.query.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => onChanged(filter.copyWith(query: '')),
                      ),
              border: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (value) => onChanged(filter.copyWith(query: value)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _EnumChip<Modalidade>(
                  label: 'Modalidade',
                  value: filter.modalidade,
                  values: Modalidade.values,
                  labels: TaxonomyLabels.modalidade,
                  onChanged: (v) => onChanged(filter.copyWith(modalidade: v)),
                  onClear:
                      () => onChanged(filter.copyWith(clearModalidade: true)),
                ),
                _EnumChip<GrupoMuscular>(
                  label: 'Grupo',
                  value: filter.grupo,
                  values: GrupoMuscular.values,
                  labels: TaxonomyLabels.grupo,
                  onChanged: (v) => onChanged(filter.copyWith(grupo: v)),
                  onClear: () => onChanged(filter.copyWith(clearGrupo: true)),
                ),
                _EnumChip<Equipamento>(
                  label: 'Equipamento',
                  value: filter.equipamento,
                  values: Equipamento.values,
                  labels: TaxonomyLabels.equipamento,
                  onChanged: (v) => onChanged(filter.copyWith(equipamento: v)),
                  onClear:
                      () => onChanged(filter.copyWith(clearEquipamento: true)),
                ),
                _EnumChip<Dificuldade>(
                  label: 'Nivel',
                  value: filter.dificuldade,
                  values: Dificuldade.values,
                  labels: TaxonomyLabels.dificuldade,
                  onChanged: (v) => onChanged(filter.copyWith(dificuldade: v)),
                  onClear:
                      () => onChanged(filter.copyWith(clearDificuldade: true)),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Favoritos'),
                  selected: filter.favoritos,
                  onSelected: (v) => onChanged(filter.copyWith(favoritos: v)),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Com video'),
                  selected: filter.comVideo,
                  onSelected:
                      (v) => onChanged(
                        filter.copyWith(comVideo: v, semVideo: false),
                      ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Sem video'),
                  selected: filter.semVideo,
                  onSelected:
                      (v) => onChanged(
                        filter.copyWith(semVideo: v, comVideo: false),
                      ),
                ),
                if (filter.hasActive) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Limpar'),
                    onPressed: onClear,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnumChip<T extends Enum> extends StatelessWidget {
  const _EnumChip({
    required this.label,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
    required this.onClear,
  });

  final String label;
  final T? value;
  final List<T> values;
  final Map<T, String> labels;
  final ValueChanged<T> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<T>(
        onSelected: onChanged,
        itemBuilder:
            (_) => [
              for (final item in values)
                PopupMenuItem<T>(
                  value: item,
                  child: Text(labels[item] ?? item.name),
                ),
            ],
        child: Chip(
          label: Text(value == null ? label : labels[value] ?? value!.name),
          deleteIcon: value == null ? null : const Icon(Icons.close, size: 16),
          onDeleted: value == null ? null : onClear,
        ),
      ),
    );
  }
}
