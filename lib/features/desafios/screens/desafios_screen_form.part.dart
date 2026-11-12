part of 'desafios_screen.dart';

extension on _DesafiosScreenState {
  /// Folha "Novo desafio": o que conta, prazo, meta na unidade certa (com
  /// sugestão pelo prazo), nome e quem entra. Cria com a folha aberta.
  Future<void> _criar() async {
    // Quantos alunos entram e se dá para contar hábitos: lidos antes de abrir.
    final ativos = ref.read(alunosHomeProvider).value?.stats.totalAtivos;
    var habitosAtivos = 0;
    try {
      final home =
          await HabitoRepository(ref.read(apiClientProvider)).getHome();
      habitosAtivos = home.habitos.where((h) => h.ativo).length;
    } catch (_) {
      // Sem a contagem, "Hábitos marcados" fica desligado: é o lado seguro.
    }
    if (!mounted) return;

    final nomeCtrl = TextEditingController(text: desafioNomeSugerido(30));
    final descricaoCtrl = TextEditingController();
    var tipo = 'TREINOS';
    var dias = 30;
    var meta = desafioMetaSugerida(tipo: tipo, dias: dias);
    var metaMexida = false;
    var nomeMexido = false;
    final mudou = ValueNotifier(0);
    nomeCtrl.addListener(() {
      // Mexeu no nome: a sugestão do prazo para de sobrescrever.
      if (nomeCtrl.text != desafioNomeSugerido(dias)) nomeMexido = true;
      mudou.value++;
    });

    void sugerir() {
      if (!metaMexida) {
        meta = desafioMetaSugerida(
          tipo: tipo,
          dias: dias,
          habitosAtivos: habitosAtivos,
        );
      }
      if (!nomeMexido) nomeCtrl.text = desafioNomeSugerido(dias);
    }

    var created = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Novo desafio',
        subtitle: 'Uma disputa com prazo: quem fizer mais sobe no ranking.',
        icon: FxIcons.meta,
        confirmLabel: 'Criar desafio',
        ouvir: mudou,
        podeConfirmar: () => nomeCtrl.text.trim().isNotEmpty,
        aoConfirmar: () async {
          try {
            final hoje = DateTime.now();
            await ref
                .read(_repo)
                .criar(
                  titulo: nomeCtrl.text.trim(),
                  descricao:
                      descricaoCtrl.text.trim().isEmpty
                          ? null
                          : descricaoCtrl.text.trim(),
                  tipo: tipo,
                  metaPontos: meta,
                  inicio: hoje,
                  fim: hoje.add(Duration(days: dias)),
                );
            AnalyticsService.instance.track(
              ProductEvents.desafioCreated,
              props: {'feature': 'desafios', 'tipo': tipo},
            );
            created = true;
            return null;
          } catch (e) {
            return friendlyError(e);
          }
        },
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            final chrome = ShellChrome.of(ctx);
            Widget rotulo(String t) => Padding(
              padding: const EdgeInsets.only(
                top: TokensStrip.s3,
                bottom: TokensStrip.s2,
              ),
              child: Text(t, style: FocuxHubTypography.chip(chrome.mute)),
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                rotulo('O que conta'),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    for (final t in desafioTipos)
                      FxToggleChip(
                        label: t.label,
                        selected: tipo == t.value,
                        isDark: chrome.isDark,
                        filledWhenSelected: true,
                        onTap:
                            t.value == 'HABITOS' && habitosAtivos == 0
                                ? null
                                : () => setSheet(() {
                                  tipo = t.value;
                                  sugerir();
                                  mudou.value++;
                                }),
                      ),
                  ],
                ),
                if (habitosAtivos == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: TokensStrip.s1),
                    child: Text(
                      'Hábitos marcados: crie um hábito antes.',
                      style: FocuxHubTypography.minimo(color: chrome.mute),
                    ),
                  ),
                rotulo('Prazo'),
                Wrap(
                  spacing: TokensStrip.s2,
                  children: [
                    for (final d in desafioDuracoes)
                      FxToggleChip(
                        label: desafioDuracaoLabel(d),
                        selected: dias == d,
                        isDark: chrome.isDark,
                        filledWhenSelected: true,
                        onTap:
                            () => setSheet(() {
                              dias = d;
                              sugerir();
                              mudou.value++;
                            }),
                      ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s2),
                FxContador(
                  rotulo: 'Meta',
                  valor: meta,
                  valorTexto: desafioUnidade(tipo, meta),
                  min: 1,
                  max: 365,
                  onChanged:
                      (v) => setSheet(() {
                        meta = v;
                        metaMexida = true;
                      }),
                ),
                const SizedBox(height: TokensStrip.s2),
                AlunoInsetFormField(
                  controller: nomeCtrl,
                  label: 'Nome',
                  icon: FxIcons.titulo,
                ),
                AlunoInsetFormField(
                  controller: descricaoCtrl,
                  label: 'Descrição (opcional)',
                  icon: FxIcons.notas,
                  maxLines: 2,
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  desafioQuemEntra(ativos),
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
            );
          },
        ),
      );
      if (ok && created && mounted) {
        FeedbackHelper.showSuccess(context, 'Desafio criado');
      }
    } finally {
      nomeCtrl.dispose();
      descricaoCtrl.dispose();
      mudou.dispose();
    }
    if (created) await _load();
  }
}
