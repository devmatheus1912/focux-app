import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercise_enum_api.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/providers/exercicio_picker_provider.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';

/// Rótulo de um chip de grupo: "Peito" ou, com exercícios no treino, "Peito · 3".
/// O número é sempre o que já está no treino (o da biblioteca não aparece).
String rotuloChipGrupo({required String nome, required int noTreino}) =>
    noTreino > 0 ? '$nome · $noTreino' : nome;

/// Ordem dos chips: os marcados (grupos da sessão) primeiro, depois os que já
/// estão no treino, depois os maiores da biblioteca. Só grupos com exercícios.
List<GrupoMuscular> ordemDosGrupos({
  required Map<GrupoMuscular, int> naBiblioteca,
  required Map<GrupoMuscular, int> noTreino,
  Set<GrupoMuscular> marcados = const {},
}) {
  final grupos = [
    for (final g in GrupoMuscular.values)
      if ((naBiblioteca[g] ?? 0) > 0 || (noTreino[g] ?? 0) > 0 || marcados.contains(g)) g,
  ];
  grupos.sort((a, b) {
    if (marcados.contains(a) != marcados.contains(b)) return marcados.contains(a) ? -1 : 1;
    final aTreino = noTreino[a] ?? 0;
    final bTreino = noTreino[b] ?? 0;
    if ((aTreino > 0) != (bTreino > 0)) return aTreino > 0 ? -1 : 1;
    if (aTreino != bTreino) return bTreino.compareTo(aTreino);
    final porTotal = (naBiblioteca[b] ?? 0).compareTo(naBiblioteca[a] ?? 0);
    return porTotal != 0 ? porTotal : a.index.compareTo(b.index);
  });
  return grupos;
}

/// A fileira única de filtros: chips de grupo combináveis (Peito + Tríceps)
/// e, no fim, os [extras] ("Equipamento", "Limpar").
class ExerciseGroupChips extends ConsumerWidget {
  const ExerciseGroupChips({
    super.key,
    required this.selecionados,
    required this.noTreino,
    required this.onToggle,
    required this.primary,
    required this.isDark,
    this.marcadosPrimeiro = const {},
    this.antes = const [],
    this.extras = const [],
  });

  final Set<GrupoMuscular> selecionados;
  final Map<GrupoMuscular, int> noTreino;
  final ValueChanged<GrupoMuscular> onToggle;
  final Color primary;
  final bool isDark;

  /// Grupos da sessão: ficam no começo da fileira.
  final Set<GrupoMuscular> marcadosPrimeiro;

  /// No começo da fileira ("Limpar", sempre à vista quando aparece).
  final List<Widget> antes;

  /// Logo depois dos grupos da sessão ("Equipamento"), para ficar à vista.
  final List<Widget> extras;

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
      marcados: marcadosPrimeiro,
    );
    if (grupos.isEmpty && extras.isEmpty && antes.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'Grupos musculares',
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: antes.length + grupos.length + extras.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, indice) {
            // Ordem: [antes] · grupos da sessão · [extras] · demais grupos.
            if (indice < antes.length) return antes[indice];
            final marcados = grupos.where(marcadosPrimeiro.contains).length;
            var i = indice - antes.length;
            if (i >= marcados && i < marcados + extras.length) return extras[i - marcados];
            if (i >= marcados + extras.length) i -= extras.length;
            final grupo = grupos[i];
            return ExercisePickerChip(
              label: rotuloChipGrupo(
                nome: TaxonomyLabels.grupo[grupo] ?? grupo.name,
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
