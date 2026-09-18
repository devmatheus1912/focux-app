part of 'treino_detail_screen.dart';

Future<void> _dispatchTreinoDetailAction({
  required BuildContext context,
  required WidgetRef ref,
  required Treino treino,
  required int treinoId,
  required int? alunoId,
  required bool isDark,
  required String action,
}) async {
  final repo = ref.read(treinoRepositoryProvider);

  switch (action) {
    case 'add':
      AnalyticsService.instance.track(
        ProductEvents.treinoDetailAddTapped,
        props: {'source': 'menu', 'id': treinoId},
      );
      final added = await context.push<bool>(
        '/treinos/$treinoId/exercicios/add',
        extra: alunoId == null ? null : {'alunoId': alunoId},
      );
      if (added == true) {
        ref.invalidate(treinoProvider(treinoId));
      }
      break;
    case 'template_split':
      await openMontarPorModelo(
        context: context,
        ref: ref,
        treinoId: treinoId,
        alreadyInTreinoIds: treino.exercicios
            .map((item) => item.exercicio.id)
            .toSet(),
      );
      break;
    case 'presencial':
      if (treino.exercicios.isEmpty) {
        FeedbackHelper.showError(
          context,
          'Adicione exercícios antes do modo presencial.',
        );
        break;
      }
      var aid = alunoId;
      if (aid == null) {
        try {
          final alunos = await ref.read(alunosProvider.future);
          if (!context.mounted) return;
          aid = await _showTreinoSheet<int>(
            context: context,
            builder:
                (dialogContext) =>
                    _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
          );
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
          break;
        }
      }
      if (aid == null || !context.mounted) break;
      context.push(
        '/treino-presencial/$treinoId?alunoId=$aid',
        extra: {'alunoId': aid},
      );
      break;
    case 'assign':
      try {
        final alunos = await ref.read(alunosProvider.future);
        if (!context.mounted) return;
        final selected = await _showTreinoSheet<int>(
          context: context,
          builder:
              (dialogContext) =>
                  _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
        );
        if (selected == null) return;
        await repo.atribuirAluno(treinoId, selected);
        AnalyticsService.instance.track(
          ProductEvents.treinosAssigned,
          props: {'source': 'detail', 'id': treinoId},
        );
        ref.invalidate(treinoProvider(treinoId));
        invalidateTreinosCaches(ref);
        invalidateTreinosDoAluno(ref, selected);
        if (context.mounted) {
          FeedbackHelper.showSuccess(context, 'Treino atribuído ao aluno.');
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showError(context, friendlyError(e));
        }
      }
      break;
    case 'clone':
      try {
        final alunos = await ref.read(alunosProvider.future);
        if (!context.mounted) return;
        final selected = await _showTreinoSheet<int>(
          context: context,
          builder:
              (dialogContext) =>
                  _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
        );
        if (selected == null) return;
        await repo.clonarParaAluno(treinoId, selected);
        AnalyticsService.instance.track(
          ProductEvents.treinosCloned,
          props: {'source': 'detail', 'id': treinoId},
        );
        invalidateTreinosCaches(ref);
        invalidateTreinosDoAluno(ref, selected);
        if (context.mounted) {
          FeedbackHelper.showSuccess(
            context,
            'Cópia dedicada criada para o aluno.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showError(context, friendlyError(e));
        }
      }
      break;
    case 'duplicate':
      try {
        await repo.duplicar(treinoId);
        AnalyticsService.instance.track(
          ProductEvents.treinosDuplicated,
          props: {'source': 'detail', 'id': treinoId},
        );
        invalidateTreinosCaches(ref);
        if (context.mounted) {
          FeedbackHelper.showSuccess(context, 'Treino duplicado com sucesso.');
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showError(context, friendlyError(e));
        }
      }
      break;
    case 'template':
      try {
        await repo.salvarComoTemplate(treinoId);
        if (context.mounted) {
          FeedbackHelper.showSuccess(context, 'Treino salvo como template.');
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showError(context, friendlyError(e));
        }
      }
      break;
    case 'delete':
      final confirm = await _showTreinoSheet<bool>(
        context: context,
        builder:
            (dialogContext) =>
                _DeleteTrainingSheet(title: treino.nome, isDark: isDark),
      );
      if (confirm != true) break;
      HapticFeedback.mediumImpact();
      try {
        await repo.excluirTreino(treinoId);
        AnalyticsService.instance.track(
          ProductEvents.treinosDeleted,
          props: {'source': 'detail', 'id': treinoId},
        );
        invalidateTreinosCaches(ref);
        if (context.mounted) {
          FeedbackHelper.showSuccess(context, 'Treino excluído.');
          _popTreinoDetail(context, alunoId: alunoId);
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showError(context, friendlyError(e));
        }
      }
      break;
  }
}

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
