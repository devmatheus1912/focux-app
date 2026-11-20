part of 'exercicios_list_screen.dart';

/// Seleção de vários (tela cheia): favoritar e excluir em lote.
extension on _ExerciciosListScreenState {
  void _selectAllVisible() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_items.map((e) => e.id));
    });
  }

  Future<void> _favoriteBatch() async {
    final repo = ref.read(exercicioRepositoryProvider);
    final ids = _selected.toList();
    var queued = 0;
    var failed = 0;
    for (final id in ids) {
      final ex = _items.firstWhere((item) => item.id == id);
      if (ex.favoritado) continue;
      try {
        await repo.favoritarExercicio(id);
      } on OfflineQueuedException {
        queued++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(_selected.clear);
    _refresh();
    final s = S.of(context);
    switch (resolveBatchMutationNotice(failed: failed, queued: queued)) {
      case BatchMutationNotice.failure:
        FeedbackHelper.showError(context, s.exerciciosFavoritarLoteFalhou);
      case BatchMutationNotice.failureWithQueued:
        FeedbackHelper.showError(
          context,
          '${s.exerciciosFavoritarLoteFalhou}\n${s.acaoEnfileiradaOffline}',
        );
      case BatchMutationNotice.queued:
        FeedbackHelper.showWarn(context, s.acaoEnfileiradaOffline);
      case BatchMutationNotice.success:
        break;
    }
  }

  Future<void> _deleteBatch() async {
    final count = _selected.length;
    if (count == 0) return;
    final ok = await showFxConfirmSheet(
      context,
      title: count == 1 ? 'Excluir 1 exercício?' : 'Excluir $count exercícios?',
      message:
          'Saem da sua lista. Os que estiverem em alguma ficha ficam, e '
          'você vê quais foram.',
      icon: FxIcons.excluir,
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    final repo = ref.read(exercicioRepositoryProvider);
    final byId = {for (final ex in _items) ex.id: ex};
    final deleted = <int>[];
    final blocked = <({int id, String nome, String motivo})>[];
    var queued = 0;

    for (final id in _selected.toList()) {
      try {
        await repo.excluir(id);
        deleted.add(id);
      } on OfflineQueuedException {
        deleted.add(id);
        queued++;
      } catch (e) {
        blocked.add((
          id: id,
          nome: byId[id]?.nomeDisplay ?? 'Exercício #$id',
          motivo: friendlyError(e),
        ));
      }
    }
    if (!mounted) return;
    setState(_selected.clear);
    _refresh();
    switch (resolveBatchMutationNotice(
      failed: blocked.length,
      queued: queued,
    )) {
      case BatchMutationNotice.success:
        FeedbackHelper.showSuccess(
          context,
          deleted.length == 1
              ? '1 exercício excluído.'
              : '${deleted.length} exercícios excluídos.',
        );
        return;
      case BatchMutationNotice.queued:
        FeedbackHelper.showWarn(context, S.of(context).acaoEnfileiradaOffline);
        return;
      case BatchMutationNotice.failure:
      case BatchMutationNotice.failureWithQueued:
        break;
    }

    await showFxNoticeSheet(
      context,
      title: 'Alguns exercícios ficaram',
      icon: FxIcons.info,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deleted.length > queued)
            Text('${deleted.length - queued} excluído(s).'),
          if (queued > 0) Text(S.of(context).acaoEnfileiradaOffline),
          const SizedBox(height: TokensStrip.s2),
          for (final item in blocked)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s2),
              child: Text('${item.nome}\n${item.motivo}'),
            ),
        ],
      ),
    );
  }
}
