import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercise_enum_api.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/providers/exercicio_picker_provider.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';

/// Rótulo de um chip de grupo: "Peito · 41" ou, com exercícios no treino,
/// "Peito · 3 no treino".
String rotuloChipGrupo({
  required String nome,
  required int naBiblioteca,
  required int noTreino,
}) =>
    noTreino > 0 ? '$nome · $noTreino no treino' : '$nome · $naBiblioteca';

/// Ordem dos chips: primeiro os grupos que já estão no treino, depois os
/// maiores da biblioteca. Só grupos com exercícios.
List<GrupoMuscular> ordemDosGrupos({
  required Map<GrupoMuscular, int> naBiblioteca,
  required Map<GrupoMuscular, int> noTreino,
}) {
  final grupos = [
    for (final g in GrupoMuscular.values)
      if ((naBiblioteca[g] ?? 0) > 0 || (noTreino[g] ?? 0) > 0) g,
  ];
  grupos.sort((a, b) {
    final aTreino = noTreino[a] ?? 0;
    final bTreino = noTreino[b] ?? 0;
    if ((aTreino > 0) != (bTreino > 0)) return aTreino > 0 ? -1 : 1;
    if (aTreino != bTreino) return bTreino.compareTo(aTreino);
    final porTotal = (naBiblioteca[b] ?? 0).compareTo(naBiblioteca[a] ?? 0);
    return porTotal != 0 ? porTotal : a.index.compareTo(b.index);
  });
  return grupos;
}

/// Fileira de chips de grupo muscular, combináveis (Peito + Tríceps).
class ExerciseGroupChips extends ConsumerWidget {
  const ExerciseGroupChips({
    super.key,
    required this.selecionados,
    required this.noTreino,
    required this.onToggle,
    required this.onLimpar,
    required this.primary,
    required this.isDark,
  });

  final Set<GrupoMuscular> selecionados;
  final Map<GrupoMuscular, int> noTreino;
  final ValueChanged<GrupoMuscular> onToggle;
  final VoidCallback onLimpar;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(exercicioPickerStatsProvider).value;
    final naBiblioteca = <GrupoMuscular, int>{
      if (stats != null)
        for (final g in GrupoMuscular.values)
          g: exercisePickerStatCount(stats.porGrupo, g.name),
    };
    final grupos = ordemDosGrupos(
      naBiblioteca: naBiblioteca,
      noTreino: noTreino,
    );
    if (grupos.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'Grupos musculares',
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: grupos.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            if (i == 0) {
              return ExercisePickerChip(
                label: 'Todos',
                selected: selecionados.isEmpty,
                primary: primary,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onLimpar();
                },
              );
            }
            final grupo = grupos[i - 1];
            return ExercisePickerChip(
              label: rotuloChipGrupo(
                nome: TaxonomyLabels.grupo[grupo] ?? grupo.name,
                naBiblioteca: naBiblioteca[grupo] ?? 0,
                noTreino: noTreino[grupo] ?? 0,
              ),
              selected: selecionados.contains(grupo),
              primary: primary,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle(grupo);
              },
            );
          },
        ),
      ),
    );
  }
}
