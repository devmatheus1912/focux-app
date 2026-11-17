part of 'treino_detail_screen.dart';

/// Devolve a prescrição e as séries de cada exercício como estavam (desfazer).
Future<void> _restaurarPrescricoes(
  TreinoRepository repo,
  int treinoId,
  List<TreinoExercicioItem> anteriores,
) async {
  for (final o in anteriores) {
    await repo.atualizarExercicioPrescricao(
      treinoId,
      o.id,
      series: o.series,
      repeticoes: o.repeticoes,
      descansoSegundos: o.descansoSegundos ?? 60,
      cargaKg: o.cargaKg,
      rpeAlvo: o.rpeAlvo,
      observacoes: o.observacoes ?? '',
      tipoSerie: tipoSerieParaApi(o.metodo.tecnica, o.metodo.progressao),
    );
    if (o.seriesLinhas.isNotEmpty) {
      await repo.salvarSeries(
        treinoId,
        o.id,
        linhas: o.seriesLinhas,
        bloco: o.bloco,
        descansoSegundos: o.descansoSegundos,
      );
    }
  }
}

/// Aplica o preset às válidas de um exercício; aquecimento, ajuste e
/// back-off ficam como estão. A carga das válidas também fica.
Future<void> _aplicarPresetNoExercicio(
  TreinoRepository repo,
  int treinoId,
  TreinoExercicioItem e,
  WorkoutBuilderPreset p,
) async {
  final extras = gruposExtras(e.seriesLinhas);
  final validas = e.seriesLinhas.where((l) => l.papel == PapelDaSerie.valida);
  final carga = validas.isNotEmpty ? validas.first.cargaKg : e.cargaKg;
  await repo.atualizarExercicioPrescricao(
    treinoId,
    e.id,
    series: p.series,
    repeticoes: p.repeticoes,
    descansoSegundos: p.descansoSegundos,
    cargaKg: e.cargaKg,
    rpeAlvo: e.rpeAlvo,
    observacoes: e.observacoes ?? '',
    tipoSerie: tipoSerieParaApi(e.metodo.tecnica, e.metodo.progressao),
  );
  await repo.salvarSeries(
    treinoId,
    e.id,
    linhas: desagruparSeries([
      ...extras.antes,
      GrupoDeSeries(
        papel: PapelDaSerie.valida,
        series: p.series,
        repeticoes: p.repeticoes,
        cargaKg: carga,
      ),
      ...extras.depois,
    ]),
    bloco: e.bloco,
    descansoSegundos: p.descansoSegundos,
  );
}

/// "Objetivo da sessão": escolhe, grava na sessão e, se já há exercícios,
/// pergunta se aplica neles também ("Só aos novos" é o padrão).
Future<void> _escolherObjetivoDaSessao({
  required BuildContext context,
  required WidgetRef ref,
  required Treino treino,
  required int treinoId,
  required int? alunoId,
  required int? modeloId,
}) async {
  final atual = presetIdDoObjetivo(treino.objetivo);
  final escolhido = await showFxGroupedActionSheet<String>(
    context,
    titulo: _objetivoTitulo,
    subtitulo: _objetivoSubtitulo,
    icone: FxIcons.meta,
    confirmar: false,
    grupos: [
      FxActionGroup<String>(null, [
        for (final p in workoutBuilderPresets)
          FxActionItem(
            valor: p.id,
            rotulo: p.id == atual ? '${p.label} · atual' : p.label,
            descricao: efeitoDoPreset(p),
            icone: p.id == atual ? FxIcons.check : FxIcons.meta,
          ),
      ]),
    ],
  );
  if (escolhido == null || escolhido == atual || !context.mounted) return;
  final preset = workoutBuilderPresetById(escolhido);
  final repo = ref.read(treinoRepositoryProvider);
  try {
    await repo.atualizarObjetivo(treinoId, objetivoDoPreset(escolhido));
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showApiFailure(
        context,
        e,
        fallback: 'Não foi possível trocar o objetivo.',
      );
    }
    return;
  }
  void mudou() => sessaoMudou(ref, treinoId, alunoId: alunoId, modeloId: modeloId);
  final existentes = [...treino.exercicios];
  if (existentes.isEmpty || !context.mounted) {
    mudou();
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, 'Objetivo: ${preset.label}.');
    }
    return;
  }
  final nomes = existentes.map((e) => e.exercicio.nomeDisplay).toList();
  final todos = await showFxConfirmSheet(
    context,
    title: existentes.length == 1
        ? 'Aplicar também ao exercício que já está aqui?'
        : 'Aplicar também aos ${existentes.length} exercícios que já estão aqui?',
    message: '${efeitoDoPreset(preset)} em: ${_listaCurta(nomes)}.',
    icon: FxIcons.meta,
    confirmLabel: 'Aplicar a todos',
    cancelLabel: 'Só aos novos',
  );
  if (!todos) {
    mudou();
    if (context.mounted) {
      FeedbackHelper.showSuccess(
        context,
        'Objetivo: ${preset.label}. Vale para os próximos exercícios.',
      );
    }
    return;
  }
  try {
    for (final e in existentes) {
      await _aplicarPresetNoExercicio(repo, treinoId, e, preset);
    }
  } catch (e) {
    mudou();
    if (context.mounted) {
      FeedbackHelper.showApiFailure(
        context,
        e,
        fallback: 'Parte dos exercícios não mudou.',
      );
    }
    return;
  }
  mudou();
  if (!context.mounted) return;
  FeedbackHelper.showSuccessAction(
    context,
    'Objetivo: ${preset.label}, aplicado a ${existentes.length == 1 ? '1 exercício' : '${existentes.length} exercícios'}.',
    actionLabel: 'Desfazer',
    onAction: () async {
      await _restaurarPrescricoes(repo, treinoId, existentes);
      mudou();
    },
  );
}

const _objetivoTitulo = 'Objetivo da sessão';
const _objetivoSubtitulo = 'Define a prescrição de quem entra na sessão.';

/// "Agachamento, Leg press e mais 2".
String _listaCurta(List<String> nomes) {
  if (nomes.length <= 2) return nomes.join(' e ');
  return '${nomes.take(2).join(', ')} e mais ${nomes.length - 2}';
}

/// "Hipertrofia" para o objetivo gravado; nulo quando não há.
String? _rotuloDoObjetivo(String? objetivo) {
  final id = presetIdDoObjetivo(objetivo);
  return id == null ? null : workoutBuilderPresetById(id).label;
}
