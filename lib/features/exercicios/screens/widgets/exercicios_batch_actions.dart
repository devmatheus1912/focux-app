import 'package:flutter/material.dart';
import '../../../../core/theme/fx_icons.dart';

class ExerciciosBatchActions extends StatelessWidget {
  const ExerciciosBatchActions({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onSelectAll,
    required this.onFavorite,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            6,
            8,
            6 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Cancelar selecao',
                icon: const Icon(FxIcons.fechar),
                onPressed: onCancel,
              ),
              Expanded(
                child: Text(
                  '$count selecionado${count == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Selecionar todos filtrados',
                icon: const Icon(FxIcons.selecionarTudo),
                onPressed: onSelectAll,
              ),
              IconButton(
                tooltip: 'Favoritar',
                icon: const Icon(FxIcons.estrela),
                onPressed: onFavorite,
              ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(FxIcons.excluir),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
