import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_icons.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/providers/treinos_provider.dart';

/// Rota do modo presencial: o aluno sempre no caminho (a rota antiga deixava
/// faltar e quebrava). O nome vai no `extra`, nunca na URL.
String treinarComAlunoPath(int alunoId, int treinoId) => '/alunos/$alunoId/treinar?treinoId=$treinoId';

/// O próximo treino da fila do aluno: a sessão aberta, senão o que vem depois
/// do último feito, senão o primeiro.
int? proximoTreinoDaFila(RotinaFila fila) {
  final treinos = [for (final i in fila.itens) if (!i.descanso && i.treinoId != null) i.treinoId!];
  if (treinos.isEmpty) return null;
  if (fila.sessaoAbertaTreinoId != null && treinos.contains(fila.sessaoAbertaTreinoId)) {
    return fila.sessaoAbertaTreinoId;
  }
  final ultimo = fila.ultimoTreinoId == null ? -1 : treinos.indexOf(fila.ultimoTreinoId!);
  return treinos[(ultimo + 1) % treinos.length];
}

/// "Treinar com {nome} agora": pergunta qual treino (o próximo da fila já
/// marcado em cima) e abre a execução conduzida pelo personal.
Future<void> treinarComAluno(BuildContext context, WidgetRef ref, {required int alunoId, required String nome}) async {
  final RotinaFila fila;
  try {
    fila = await ref.read(alunoRotinaProvider(alunoId).future);
  } catch (e) {
    if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    return;
  }
  if (!context.mounted) return;
  final proximo = proximoTreinoDaFila(fila);
  final treinos = [
    for (final i in fila.itens)
      if (!i.descanso && i.treinoId != null) i,
  ];
  if (treinos.isEmpty || proximo == null) {
    FeedbackHelper.showError(context, '$nome ainda não tem treino na ficha.');
    return;
  }
  final vistos = <int>{};
  final escolhido = await showFxGroupedActionSheet<int>(
    context,
    titulo: 'Qual treino?',
    subtitulo: 'Treinar com $nome agora',
    icone: FxIcons.treino,
    confirmar: false,
    grupos: [
      FxActionGroup<int>(null, [
        for (final i in [...treinos.where((t) => t.treinoId == proximo), ...treinos])
          if (vistos.add(i.treinoId!))
            FxActionItem(
              valor: i.treinoId!,
              rotulo: i.nome ?? 'Treino',
              descricao: i.treinoId == proximo ? 'Próximo da fila' : null,
              icone: FxIcons.treino,
            ),
      ]),
    ],
  );
  if (escolhido == null || !context.mounted) return;
  await context.push<Object?>(treinarComAlunoPath(alunoId, escolhido), extra: nome);
}
