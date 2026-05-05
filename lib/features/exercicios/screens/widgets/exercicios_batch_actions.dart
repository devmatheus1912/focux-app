import 'package:flutter/material.dart';

class ExerciciosBatchActions extends StatelessWidget {
  const ExerciciosBatchActions({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onFavorite,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Cancelar selecao',
                icon: const Icon(Icons.close_rounded),
                onPressed: onCancel,
              ),
              Expanded(
                child: Text(
                  '$count selecionado${count == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Favoritar',
                icon: const Icon(Icons.star_rounded),
                onPressed: onFavorite,
              ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
