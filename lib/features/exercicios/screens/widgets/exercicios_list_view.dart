import 'package:flutter/material.dart';

import '../../../../core/widgets/fx_empty_state.dart';
import '../../../../core/widgets/fx_loading.dart';
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
    final extra = loadingMore ? 1 : 0;

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: exercicios.length + extra,
      itemBuilder: (context, i) {
        if (i >= exercicios.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: FxLoading(size: 22)),
          );
        }
        final item = exercicios[i];
        return ExercicioCard(
          exercicio: item,
          accent: primary,
          selected: selectedIds.contains(item.id),
          onTapOverride: () => onTap(item),
          onLongPress: () => onLongPress(item),
          onFavoritoToggle: () => onFavorite(item),
          onUploadVideo: () => onUploadVideo(item),
          onDelete: () => onDelete(item),
        );
      },
    );
  }
}
