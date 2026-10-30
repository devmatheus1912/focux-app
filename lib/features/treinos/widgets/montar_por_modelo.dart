import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/screens/widgets/template_split_picker.dart';
import '../data/treino_repository.dart';
import '../data/workout_builder_preset.dart';
import '../providers/treinos_provider.dart';
import 'treino_no_lugar.dart';
import '../services/recent_exercise_usage_store.dart';
import '../utils/divisao_catalogo.dart';
import '../../../l10n/app_localizations.dart';

/// Sugere exercícios para **esta** sessão. Se o nome casa com um dia de um modelo
/// ("B · Costas e bíceps"), abre direto os blocos desse dia; senão, o personal
/// escolhe o modelo e um dia só. Tudo entra em [treinoId].
Future<void> openSugerirExercicios({
  required BuildContext context,
  required WidgetRef ref,
  required int treinoId,
  int? alunoId,
  int? modeloId,
  required String nomeDaSessao,
  required Set<int> alreadyInTreinoIds,
}) async {
  HapticFeedback.selectionClick();
  final preset = workoutBuilderPresetById('hypertrophy');
  final sugestao = sugestaoDaSessao(nomeDaSessao);
  final completed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (routeContext) {
        final scheme = Theme.of(routeContext).colorScheme;
        Future<void> adicionar(Exercicio exercicio) =>
            _adicionar(routeContext, ref, treinoId, preset, exercicio);
        void concluir() {
          if (routeContext.mounted) Navigator.pop(routeContext, true);
        }

        if (sugestao != null) {
          return TemplateDiaEditor(
            template: sugestao.$1,
            indice: sugestao.$2,
            alreadyInTreinoIds: alreadyInTreinoIds,
            onAdicionar: adicionar,
            // O editor é a própria rota e se fecha sozinho ao concluir.
          );
        }
        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.of(routeContext).treinoSugerirExercicios),
                Text(
                  S.of(routeContext).treinoSugerirUmDia,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            leading: IconButton(
              tooltip: 'Voltar',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(routeContext, false),
            ),
          ),
          body: TemplateSplitPicker(
            umDiaSo: true,
            alreadyInTreinoIds: alreadyInTreinoIds,
            onCompleted: concluir,
            onAdicionar: adicionar,
          ),
        );
      },
    ),
  );
  sessaoMudou(ref, treinoId, alunoId: alunoId, modeloId: modeloId);
  ref.invalidate(treinoPickerHomeProvider(treinoId));
  if (completed == true && context.mounted) {
    FeedbackHelper.showSuccess(context, S.of(context).treinoSugeridosAdicionados);
  }
}

Future<void> _adicionar(
  BuildContext routeContext,
  WidgetRef ref,
  int treinoId,
  WorkoutBuilderPreset preset,
  Exercicio exercicio,
) async {
  final exId = exercicio.id;
  if (exId <= 0) {
    if (routeContext.mounted) {
      FeedbackHelper.showError(routeContext, 'Exercício inválido. Escolha outro.');
    }
    return;
  }
  try {
    await ref
        .read(treinoRepositoryProvider)
        .adicionarExercicio(
          treinoId,
          exId,
          series: preset.series,
          repeticoes: preset.repeticoes,
          descanso: preset.descansoSegundos,
          observacoes: preset.observacoes,
          tipoSerie: preset.tipoSerie,
        );
    await RecentExerciseUsageStore.recordUsage(exId);
    AnalyticsService.instance.track('template_uso', props: {'treinoId': treinoId, 'exId': exId});
    if (routeContext.mounted) {
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(routeContext, '${exercicio.nomeDisplay} adicionado.');
    }
  } catch (e) {
    if (routeContext.mounted) FeedbackHelper.showApiFailure(routeContext, e);
    rethrow;
  }
}
