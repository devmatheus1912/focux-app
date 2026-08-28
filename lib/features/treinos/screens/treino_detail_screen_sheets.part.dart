part of 'treino_detail_screen.dart';

class _RemoveExerciseSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _RemoveExerciseSheet({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TreinoInsetConfirmSheet(
      isDark: isDark,
      headerIcon: Icons.remove_circle_outline_rounded,
      title: 'Remover exercício?',
      message: '$title sai apenas deste treino. O exercício continua na biblioteca.',
      confirmLabel: 'Remover',
    );
  }
}

class _DeleteTrainingSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _DeleteTrainingSheet({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TreinoInsetConfirmSheet(
      isDark: isDark,
      headerIcon: Icons.delete_outline_rounded,
      title: 'Excluir treino?',
      message:
          '$title sai da biblioteca. Históricos já concluídos continuam preservados.',
      confirmLabel: 'Excluir',
    );
  }
}
