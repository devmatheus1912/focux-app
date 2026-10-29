part of 'treino_detail_screen.dart';

Future<void> _dispatchTreinoDetailAction({
  required BuildContext context,
  required WidgetRef ref,
  required Treino treino,
  required int treinoId,
  required int? alunoId,
  String? alunoNome,
  int? modeloId,
  required bool isDark,
  required String action,
  VoidCallback? onAssigned,
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
        extra: TreinoRouteExtra(alunoId: alunoId).toExtra(),
      );
      if (added == true) {
        ref.invalidate(treinoProvider(treinoId));
      }
      break;
    case 'sugerir':
      await openSugerirExercicios(
        context: context,
        ref: ref,
        treinoId: treinoId,
        nomeDaSessao: treino.nome,
        alreadyInTreinoIds: treino.exercicios
            .map((item) => item.exercicio.id)
            .toSet(),
      );
      break;
    case 'assign':
      try {
        final alunos = await ref.read(alunosProvider.future);
        if (!context.mounted) return;
        final selected = await _showTreinoSheet<TreinoAtribuicaoResult>(
          context: context,
          builder:
              (dialogContext) => TreinoAssignSheet(
                alunos: alunos,
                isDark: isDark,
                includePrazo: true,
              ),
        );
        if (selected == null) return;
        await repo.atribuirAluno(
          treinoId,
          selected.alunoId,
          dataFim: selected.dataFim,
          copiar: true,
        );
        AnalyticsService.instance.track(
          ProductEvents.treinosAssigned,
          props: {'source': 'detail', 'id': treinoId},
        );
        ref.invalidate(treinoProvider(treinoId));
        invalidateTreinosCaches(ref);
        invalidateTreinosDoAluno(ref, selected.alunoId);
        onAssigned?.call();
        if (context.mounted) {
          ref.invalidate(alunoRotinaProvider(selected.alunoId));
          avisarEntrouNoFim(
            context,
            alunoId: selected.alunoId,
            nome: selected.alunoNome,
          );
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showError(context, friendlyError(e));
        }
      }
      break;
    case 'rename':
      final s = S.of(context);
      final nome = await pedirTexto(context, titulo: s.treinoRenomear, inicial: treino.nome);
      if (nome == null || !context.mounted) break;
      try {
        await repo.renomearTreino(treinoId, nome);
        ref.invalidate(treinoProvider(treinoId));
        if (alunoId != null) ref.invalidate(alunoRotinaProvider(alunoId));
        if (modeloId != null) ref.invalidate(fichaModeloProvider(modeloId));
        invalidateTreinosCaches(ref);
      } catch (e) {
        if (context.mounted) FeedbackHelper.showApiFailure(context, e);
      }
      break;
    case 'copy_day':
      final para = await escolherDia(context);
      if (para == null || !context.mounted) break;
      try {
        final semana = await lerSemanaDoLugar(ref, alunoId: alunoId, modeloId: modeloId);
        if (semana == null) break;
        final copia = await repo.duplicar(treinoId);
        await gravarSemanaDoLugar(
          ref,
          alunoId: alunoId,
          modeloId: modeloId,
          dias: comSessaoNoDia(
            semana,
            dia: para,
            sessao: SessaoDaSemana(
              treinoId: copia.id,
              nome: copia.nome,
              exerciciosCount: treino.exercicios.length,
            ),
          ),
        );
        if (context.mounted) {
          FeedbackHelper.showSuccess(context, S.of(context).treinoCopiadoPara(nomesDosDias(S.of(context))[para - 1]));
        }
      } catch (e) {
        if (context.mounted) FeedbackHelper.showApiFailure(context, e);
      }
      break;
    case 'remove_from':
      final s = S.of(context);
      final ok = await showFxConfirmSheet(
        context,
        title: alunoId != null ? s.treinoTirarDaFichaTitulo : s.treinoTirarDoModeloTitulo,
        message: s.treinoTirarTexto,
        confirmLabel: alunoId != null ? s.treinoTirarDaFicha : s.treinoTirarDoModelo,
        destructive: true,
      );
      if (!ok || !context.mounted) break;
      try {
        final semana = await lerSemanaDoLugar(ref, alunoId: alunoId, modeloId: modeloId);
        if (semana == null) break;
        await gravarSemanaDoLugar(
          ref,
          alunoId: alunoId,
          modeloId: modeloId,
          dias: semanaSemASessao(semana, treinoId),
        );
        if (context.mounted) safePopOrGo(context, '/treinos');
      } catch (e) {
        if (context.mounted) FeedbackHelper.showApiFailure(context, e);
      }
      break;
    case 'duplicate':
      try {
        final copia = await repo.duplicar(treinoId);
        AnalyticsService.instance.track(
          ProductEvents.treinosDuplicated,
          props: {'source': 'detail', 'id': treinoId},
        );
        invalidateTreinosCaches(ref);
        if (context.mounted) context.pushReplacement('/treinos/${copia.id}');
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showApiFailure(context, e);
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
          FeedbackHelper.showApiFailure(context, e);
        }
      }
      break;
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
