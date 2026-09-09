part of 'desafios_screen.dart';

extension on _DesafiosScreenState {
  Future<void> _criar() async {
    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    var tipo = desafioTipos.first.value;
    var dias = 30;
    var metaPontos = 100;
    var created = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Novo desafio',
        subtitle: 'Prazo, tipo e meta entram no ranking.',
        icon: Icons.flag_outlined,
        confirmLabel: 'Criar',
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AlunoInsetFormField(
                controller: tituloCtrl,
                label: 'Título',
                icon: Icons.title_outlined,
              ),
              AlunoInsetFormField(
                controller: descricaoCtrl,
                label: 'Descrição (opcional)',
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),
              FxInsetPickerRow(
                icon: Icons.category_outlined,
                label: 'Tipo',
                value: desafioTipoLabel(tipo),
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<String>(
                    ctx,
                    title: 'Tipo',
                    selected: tipo,
                    items: [
                      for (final item in desafioTipos)
                        FxInsetPickerSheetItem(
                          value: item.value,
                          label: item.label,
                        ),
                    ],
                  );
                  if (picked == null) return;
                  setDialogState(() => tipo = picked);
                },
              ),
              FxInsetPickerRow(
                icon: Icons.event_outlined,
                label: 'Prazo',
                value: desafioDuracaoLabel(dias),
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<int>(
                    ctx,
                    title: 'Prazo',
                    selected: dias,
                    items: [
                      for (final d in desafioDuracoes)
                        FxInsetPickerSheetItem(
                          value: d,
                          label: desafioDuracaoLabel(d),
                        ),
                    ],
                  );
                  if (picked == null) return;
                  setDialogState(() => dias = picked);
                },
              ),
              FxInsetPickerRow(
                icon: Icons.emoji_events_outlined,
                label: 'Meta',
                value: desafioMetaLabel(metaPontos),
                showDivider: false,
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<int>(
                    ctx,
                    title: 'Meta',
                    selected: metaPontos,
                    items: const [
                      FxInsetPickerSheetItem(value: 50, label: '50 pts'),
                      FxInsetPickerSheetItem(value: 100, label: '100 pts'),
                      FxInsetPickerSheetItem(value: 200, label: '200 pts'),
                    ],
                  );
                  if (picked == null) return;
                  setDialogState(() => metaPontos = picked);
                },
              ),
            ],
          ),
        ),
      );
      if (ok != true || tituloCtrl.text.trim().isEmpty) return;
      final hoje = DateTime.now();
      await ref.read(_repo).criar(
        titulo: tituloCtrl.text.trim(),
        descricao: descricaoCtrl.text.trim().isEmpty
            ? null
            : descricaoCtrl.text.trim(),
        tipo: tipo,
        metaPontos: metaPontos,
        inicio: hoje,
        fim: hoje.add(Duration(days: dias)),
      );
      AnalyticsService.instance.track(
        ProductEvents.desafioCreated,
        props: {'feature': 'desafios', 'tipo': tipo},
      );
      created = true;
      if (mounted) FeedbackHelper.showSuccess(context, 'Desafio criado');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      tituloCtrl.dispose();
      descricaoCtrl.dispose();
    }
    if (created) await _load();
  }
}
