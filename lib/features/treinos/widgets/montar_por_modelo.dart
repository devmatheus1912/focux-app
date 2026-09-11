import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/screens/widgets/template_split_picker.dart';
import '../data/workout_builder_preset.dart';
import '../providers/treinos_provider.dart';
import '../services/recent_exercise_usage_store.dart';

Future<void> openMontarPorModelo({
  required BuildContext context,
  required WidgetRef ref,
  required int treinoId,
  required Set<int> alreadyInTreinoIds,
}) async {
  HapticFeedback.selectionClick();
  final preset = workoutBuilderPresetById('hypertrophy');
  final completed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (routeContext) => FxShellScaffold(
            useMesh: true,
            appBar: FxShellAppBar(
              title: 'Montar por modelo',
              subtitle: 'Pela frequência do aluno',
              onBack: () => Navigator.pop(routeContext, false),
            ),
            body: TemplateSplitPicker(
              alreadyInTreinoIds: alreadyInTreinoIds,
              onCompleted: () => Navigator.pop(routeContext, true),
              onAdicionar: (Exercicio exercicio) async {
                try {
                  await ref
                      .read(treinoRepositoryProvider)
                      .adicionarExercicio(
                        treinoId,
                        exercicio.id,
                        series: preset.series,
                        repeticoes: preset.repeticoes,
                        descanso: preset.descansoSegundos,
                        observacoes: preset.observacoes,
                        tipoSerie: preset.tipoSerie,
                      );
                  await RecentExerciseUsageStore.recordUsage(exercicio.id);
                  AnalyticsService.instance.track(
                    'template_uso',
                    props: {'treinoId': treinoId, 'exId': exercicio.id},
                  );
                  if (routeContext.mounted) {
                    HapticFeedback.mediumImpact();
                    FeedbackHelper.showSuccess(
                      routeContext,
                      '${exercicio.nomeDisplay} adicionado.',
                    );
                  }
                } catch (e) {
                  if (routeContext.mounted) {
                    FeedbackHelper.showError(routeContext, friendlyError(e));
                  }
                }
              },
            ),
          ),
    ),
  );
  ref.invalidate(treinoProvider(treinoId));
  ref.invalidate(treinoPickerHomeProvider(treinoId));
  if (completed == true && context.mounted) {
    FeedbackHelper.showSuccess(
      context,
      'Modelo concluído! Exercícios adicionados ao treino.',
    );
  }
}
