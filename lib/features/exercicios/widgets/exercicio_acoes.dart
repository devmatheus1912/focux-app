import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../treinos/utils/exercise_library_meta.dart';
import '../data/exercicio_repository.dart';
import '../models/exercicio_criado.dart';
import '../providers/exercicios_provider.dart';
import '../screens/widgets/exercise_media_thumb.dart';
import '../screens/widgets/exercise_video_preview_sheet.dart';
import '../utils/exercicios_aba_display.dart';
import 'exercise_video_envio.dart';

IconData _icone(ExercicioAcao a, Exercicio e) => switch (a) {
  ExercicioAcao.assistir => FxIcons.playCirculo,
  ExercicioAcao.video =>
    exercicioHasPersonalVideo(e) ? FxIcons.trocar : FxIcons.upload,
  ExercicioAcao.editar => FxIcons.editar,
  ExercicioAcao.duplicar => FxIcons.duplicar,
  ExercicioAcao.excluir => FxIcons.excluir,
};

/// "⋯" de um exercício na aba Exercícios: folha do kit com Assistir vídeo ·
/// Trocar (ou Enviar) vídeo · Editar · Duplicar e, à parte, Excluir.
/// Devolve `true` quando algo mudou e a lista precisa recarregar.
Future<bool> abrirAcoesDoExercicio(
  BuildContext context,
  WidgetRef ref,
  Exercicio exercicio,
) async {
  final acoes = exercicioAcoesDisponiveis(exercicio);
  FxActionItem<ExercicioAcao> item(ExercicioAcao a) => FxActionItem(
    valor: a,
    rotulo: exercicioAcaoRotulo(a, exercicio),
    icone: _icone(a, exercicio),
  );
  final escolhida = await showFxGroupedActionSheet<ExercicioAcao>(
    context,
    titulo: exercicio.nomeDisplay,
    subtitulo: exerciseLibraryMeta(exercicio),
    icone: null,
    grupos: [
      FxActionGroup(null, [
        for (final a in acoes)
          if (a != ExercicioAcao.excluir) item(a),
      ]),
    ],
    destrutiva:
        acoes.contains(ExercicioAcao.excluir)
            ? item(ExercicioAcao.excluir)
            : null,
    // A confirmação de excluir depende das fichas: feita abaixo.
    confirmar: false,
  );
  if (escolhida == null || !context.mounted) return false;
  switch (escolhida) {
    case ExercicioAcao.assistir:
      await showExerciseMediaPreview(context, exercicio: exercicio);
      return false;
    case ExercicioAcao.video:
      return _enviarVideo(context, ref, exercicio);
    case ExercicioAcao.editar:
      await context.push<bool>('/exercicios/${exercicio.id}/editar');
      return true;
    case ExercicioAcao.duplicar:
      final criado = await context.push<ExercicioCriado>(
        '/exercicios/novo',
        extra: exercicio,
      );
      return criado != null;
    case ExercicioAcao.excluir:
      return _excluir(context, ref, exercicio);
  }
}

Future<bool> _enviarVideo(
  BuildContext context,
  WidgetRef ref,
  Exercicio exercicio,
) async {
  try {
    final enviado = await escolherEEnviarVideoDoExercicio(
      context,
      ref,
      exercicio.id,
    );
    if (enviado == null) return false;
    AnalyticsService.instance.track(
      'video_personal_upload',
      props: {'exId': exercicio.id},
    );
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, 'Vídeo adicionado.');
    }
    return true;
  } catch (e) {
    if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    return false;
  }
}

/// Excluir diz o efeito antes: com fichas usando, vira aviso com a contagem
/// (o servidor recusaria); sem fichas, confirma e exclui.
Future<bool> _excluir(
  BuildContext context,
  WidgetRef ref,
  Exercicio exercicio,
) async {
  final repo = ref.read(exercicioRepositoryProvider);
  int fichas;
  try {
    fichas = (await repo.buscar(exercicio.id)).usadoEmFichas ?? 0;
  } catch (e) {
    if (context.mounted) FeedbackHelper.showApiFailure(context, e);
    return false;
  }
  if (!context.mounted) return false;
  if (fichas > 0) {
    await showFxNoticeSheet(
      context,
      title: exercicioExcluirTitulo(fichas),
      message: exercicioExcluirMensagem(fichas),
      icon: FxIcons.info,
    );
    return false;
  }
  final ok = await showFxConfirmSheet(
    context,
    title: exercicioExcluirTitulo(0),
    subtitle: exercicio.nomeDisplay,
    message: exercicioExcluirMensagem(0),
    icon: FxIcons.excluir,
    confirmLabel: 'Excluir',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  try {
    await repo.excluir(exercicio.id);
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, 'Exercício excluído.');
    }
    return true;
  } catch (e) {
    if (context.mounted) FeedbackHelper.showApiFailure(context, e);
    return false;
  }
}
