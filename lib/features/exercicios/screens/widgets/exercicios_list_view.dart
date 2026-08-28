import 'package:flutter/material.dart';

import '../../../../core/widgets/fx_empty_state.dart';
import '../../../../core/widgets/fx_loading.dart';
import '../../../../core/widgets/fx_settings_group.dart';
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
    this.controller,
    this.accent,
    this.loadingMore = false,
  });

  final List<Exercicio> exercicios;
  final Set<int> selectedIds;
  final ScrollController? controller;
  final Color? accent;
  final bool loadingMore;
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

    final primary = accent ?? Theme.of(context).colorScheme.primary;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        FxSettingsGroup(
          accent: primary,
          children: [
            for (var i = 0; i < exercicios.length; i++)
              ExercicioCard(
                exercicio: exercicios[i],
                accent: primary,
                selected: selectedIds.contains(exercicios[i].id),
                showDivider: i < exercicios.length - 1,
                onTapOverride: () => onTap(exercicios[i]),
                onLongPress: () => onLongPress(exercicios[i]),
                onFavoritoToggle: () => onFavorite(exercicios[i]),
                onUploadVideo: () => onUploadVideo(exercicios[i]),
                onDelete: () => onDelete(exercicios[i]),
              ),
          ],
        ),
        if (loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: FxLoading(size: 22)),
          ),
      ],
    );
  }
}
