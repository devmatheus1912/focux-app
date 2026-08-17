import 'package:flutter/material.dart';

import '../../../../core/widgets/fx_empty_state.dart';
import '../../data/exercicio_repository.dart';
import 'exercicio_card.dart';

class ExerciciosListView extends StatelessWidget {
  const ExerciciosListView({
    super.key,
    required this.exercicios,
    required this.selectedIds,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
    required this.onUploadVideo,
    required this.onDelete,
  });

  final List<Exercicio> exercicios;
  final Set<int> selectedIds;
  final ValueChanged<Exercicio> onTap;
  final ValueChanged<Exercicio> onLongPress;
  final ValueChanged<Exercicio> onFavorite;
  final ValueChanged<Exercicio> onUploadVideo;
  final ValueChanged<Exercicio> onDelete;

  @override
  Widget build(BuildContext context) {
    if (exercicios.isEmpty) {
      return const FxEmptyState(
        icon: 'search',
        title: 'Nenhum exercício encontrado',
        subtitle: 'Ajuste os filtros ou cadastre um novo exercício.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: exercicios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exercicio = exercicios[index];
        return ExercicioCard(
          exercicio: exercicio,
          selected: selectedIds.contains(exercicio.id),
          onTapOverride: () => onTap(exercicio),
          onLongPress: () => onLongPress(exercicio),
          onFavoritoToggle: () => onFavorite(exercicio),
          onUploadVideo: () => onUploadVideo(exercicio),
          onDelete: () => onDelete(exercicio),
        );
      },
    );
  }
}
