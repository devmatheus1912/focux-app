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
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder:
          (_) => FxShellScaffold(
            useMesh: true,
            appBar: FxShellAppBar(
              title: 'Montar por modelo',
              subtitle: 'Preencha o treino com modelos prontos',
              onBack: () => Navigator.pop(context),
            ),
            body: TemplateSplitPicker(
              alreadyInTreinoIds: alreadyInTreinoIds,
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
                  if (context.mounted) {
                    HapticFeedback.mediumImpact();
                    FeedbackHelper.showSuccess(
                      context,
                      '${exercicio.nomeDisplay} adicionado.',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    FeedbackHelper.showError(context, friendlyError(e));
                  }
                }
              },
            ),
          ),
    ),
  );
  ref.invalidate(treinoProvider(treinoId));
  ref.invalidate(treinoPickerHomeProvider(treinoId));
}
