import 'package:flutter/material.dart';

import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_loading.dart';
import '../../../treinos/widgets/exercise_library_row.dart';
import '../../data/exercicio_repository.dart';

/// Lista da aba Exercícios com a mesma linha da biblioteca do "Adicionar
/// exercício" (20/11): mídia à esquerda, nome em até 2 linhas, grupo e
/// equipamento embaixo ("Seu · Peito · Halter"), estrela só no favorito e
/// "⋯" à direita. Segurar favorita; em modo seleção o toque marca.
class ExerciciosListView extends StatelessWidget {
  const ExerciciosListView({
    super.key,
    required this.exercicios,
    required this.selectedIds,
    required this.onTap,
    required this.onFavorite,
    required this.onMais,
    required this.onPreview,
    this.controller,
    this.loadingMore = false,
    this.busca = '',
  });

  final List<Exercicio> exercicios;
  final Set<int> selectedIds;
  final ScrollController? controller;
  final bool loadingMore;
  final String busca;
  final ValueChanged<Exercicio> onTap;
  final ValueChanged<Exercicio> onFavorite;
  final ValueChanged<Exercicio> onMais;
  final ValueChanged<Exercicio> onPreview;

  @override
  Widget build(BuildContext context) {
    final extra = loadingMore ? 1 : 0;
    final selecionando = selectedIds.isNotEmpty;
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s2 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      itemCount: exercicios.length + extra,
      itemBuilder: (context, i) {
        if (i >= exercicios.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: TokensStrip.s3),
            child: Center(child: FxLoading(size: 22)),
          );
        }
        final item = exercicios[i];
        return ExerciseLibraryRow(
          key: ValueKey(item.id),
          exercicio: item,
          picker: false,
          searchQuery: busca,
          selected: selectedIds.contains(item.id),
          showDivider: i < exercicios.length - 1,
          onTap: () => onTap(item),
          onFavoriteToggle: selecionando ? null : () => onFavorite(item),
          onPreviewThumb: () => onPreview(item),
          onMais: selecionando ? null : () => onMais(item),
        );
      },
    );
  }
}
