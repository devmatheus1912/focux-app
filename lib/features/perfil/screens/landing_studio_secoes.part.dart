part of 'landing_editor_screen.dart';

/// Edição de uma seção da página, em folha.
class _LandingSecaoFolha extends StatefulWidget {
  const _LandingSecaoFolha({required this.secao, required this.state});

  final LandingSecao secao;
  final _LandingEditorScreenState state;

  @override
  State<_LandingSecaoFolha> createState() => _LandingSecaoFolhaState();
}

class _LandingSecaoFolhaState extends State<_LandingSecaoFolha> {
  var _refazendo = false;

  _LandingEditorScreenState get st => widget.state;

  Future<void> _refazer() async {
    setState(() => _refazendo = true);
    await st._refazerSecao(
      widget.secao,
      depois: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() => _refazendo = false);
  }

  Widget _campo(
    TextEditingController c,
    String rotulo, {
    int min = 1,
    int max = 4,
    TextInputType? teclado,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: TokensStrip.s3),
    child: TextFormField(
      controller: c,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: teclado,
      minLines: min,
      maxLines: max,
      decoration: FxInputDeco.build(context, rotulo),
    ),
  );

  List<Widget> _corpo(S s) => switch (widget.secao) {
    LandingSecao.capa => [
      _campo(st._heroTitle, s.landingTituloPrincipal, min: 2, max: 4),
      _campo(st._heroSubtitle, s.landingSubtitulo, min: 2, max: 4),
      _campo(st._primaryCta, s.landingTextoBotao),
      _LandingStudioImageSlot(
        label: s.landingFotoCapa,
        url: st._heroImageUrl,
        uploading: st._uploadingHero,
        onTap: () async {
          await st._uploadImage(hero: true);
          if (mounted) setState(() {});
        },
      ),
    ],
    LandingSecao.sobre => [
      _campo(st._bio, s.landingSobreTexto, min: 3, max: 8),
      _LandingStudioImageSlot(
        label: s.landingFotoSobre,
        url: st._bioImageUrl,
        uploading: st._uploadingBio,
        onTap: () async {
          await st._uploadImage(hero: false);
          if (mounted) setState(() {});
        },
      ),
    ],
    LandingSecao.metodo => [
      _LandingListaEditavel(
        itens: [for (final m in st._metodo) (m.titulo, m.descricao)],
        rotuloTitulo: s.landingPassoTitulo,
        rotuloTexto: s.landingPassoTexto,
        nomeDoItem: 'Etapa',
        onMudou: (l) => st._mudarLista(() {
          st._metodo = [
            for (final (t, d) in l) LandingMetodoPasso(titulo: t, descricao: d),
          ];
        }),
      ),
    ],
    LandingSecao.inclui => [
      _LandingListaEditavel(
        itens: [for (final i in st._servicos) (i.titulo, i.descricao)],
        rotuloTitulo: s.landingItemTitulo,
        rotuloTexto: s.landingItemTexto,
        nomeDoItem: 'Item',
        onMudou: (l) => st._mudarLista(() {
          st._servicos = [
            for (final (t, d) in l)
              LandingStudioServico(titulo: t, descricao: d),
          ];
        }),
      ),
    ],
    LandingSecao.planos => [
      _campo(st._ofertaNome, s.landingOfertaNome),
      _campo(st._ofertaInclui, s.landingOfertaInclui, min: 2, max: 4),
      _campo(st._ofertaPreco, s.landingOfertaPreco),
      Text(
        s.landingOfertaAjuda,
        style: FocuxHubTypography.bodyMuted(
          color: ShellChrome.of(context).mute,
        ),
      ),
    ],
    LandingSecao.depoimentos => [
      Text(
        s.landingDepoimentosTexto,
        style: FocuxHubTypography.body(color: ShellChrome.of(context).ink),
      ),
      const SizedBox(height: TokensStrip.s3),
      FxTonalButton(
        label: s.landingDepoimentosAbrir,
        expanded: true,
        onPressed: () {
          Navigator.of(context).pop();
          st.context.push('/depoimentos');
        },
      ),
    ],
    LandingSecao.perguntas => [
      _LandingListaEditavel(
        itens: [for (final f in st._faq) (f.pergunta, f.resposta)],
        rotuloTitulo: s.landingPergunta,
        rotuloTexto: s.landingResposta,
        nomeDoItem: 'Pergunta',
        onMudou: (l) => st._mudarLista(() {
          st._faq = [
            for (final (t, d) in l) LandingStudioFaq(pergunta: t, resposta: d),
          ];
        }),
      ),
    ],
    LandingSecao.contato => [
      _campo(st._whatsapp, s.landingWhatsapp, teclado: TextInputType.phone),
      _campo(st._instagram, s.landingInstagram),
      _campo(st._fechamento, s.landingFechamento, min: 2, max: 4),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final secao = widget.secao;
    return FxHomeSheetSurface(
      isDark: ShellChrome.of(context).isDark,
      expand: true,
      maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: ShellChrome.of(context).isDark),
          const SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: ShellChrome.of(context).isDark,
            title: landingSecaoTitulo(s, secao),
            // Sem X: fecha por "Concluir", arrastar ou tocar fora. O ícone de
            // IA refaz os textos desta seção.
            trailing:
                landingSecaoAceitaIa(secao)
                    ? (_refazendo
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: FxLoading(size: 20, strokeWidth: 2),
                        )
                        : IconButton(
                          tooltip: s.landingRefazerSecao,
                          icon: const Icon(FxIcons.ia),
                          onPressed: _refazer,
                        ))
                    : const SizedBox.shrink(),
          ),
          const SizedBox(height: TokensStrip.s3),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: _corpo(s),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          FxLiquidPrimaryButton(
            label: s.landingConcluir,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Lista de título + texto: adicionar, editar, remover e ordenar.
class _LandingListaEditavel extends StatefulWidget {
  const _LandingListaEditavel({
    required this.itens,
    required this.rotuloTitulo,
    required this.rotuloTexto,
    required this.onMudou,
    required this.nomeDoItem,
  });

  /// "Etapa", "Item", "Pergunta": título de cada bloco e da linha de adicionar.
  final String nomeDoItem;
  final List<(String, String)> itens;
  final String rotuloTitulo;
  final String rotuloTexto;
  final ValueChanged<List<(String, String)>> onMudou;

  @override
  State<_LandingListaEditavel> createState() => _LandingListaEditavelState();
}

class _LandingListaEditavelState extends State<_LandingListaEditavel> {
  late List<(TextEditingController, TextEditingController)> _linhas;

  @override
  void initState() {
    super.initState();
    _linhas = [for (final (t, d) in widget.itens) _par(t, d)];
  }

  @override
  void didUpdateWidget(covariant _LandingListaEditavel old) {
    super.didUpdateWidget(old);
    final atuais = [for (final (t, d) in _linhas) (t.text, d.text)];
    if (!_iguais(atuais, widget.itens)) {
      _soltar(_linhas);
      _linhas = [for (final (t, d) in widget.itens) _par(t, d)];
    }
  }

  bool _iguais(List<(String, String)> a, List<(String, String)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  (TextEditingController, TextEditingController) _par(String t, String d) {
    final titulo = TextEditingController(text: t)..addListener(_avisar);
    final texto = TextEditingController(text: d)..addListener(_avisar);
    return (titulo, texto);
  }

  void _soltar(List<(TextEditingController, TextEditingController)> linhas) {
    for (final (t, d) in linhas) {
      t.dispose();
      d.dispose();
    }
  }

  void _avisar() =>
      widget.onMudou([for (final (t, d) in _linhas) (t.text, d.text)]);

  void _adicionar() {
    setState(() => _linhas = [..._linhas, _par('', '')]);
    _avisar();
  }

  /// Some na hora, com "Desfazer" que volta o item no mesmo lugar.
  void _remover(int i) {
    final saiu = _linhas[i];
    setState(() => _linhas = [..._linhas]..removeAt(i));
    _avisar();
    _removidos.add(saiu);
    FeedbackHelper.showSuccessAction(
      context,
      '${widget.nomeDoItem} removida.'.replaceFirst('Item removida', 'Item removido'),
      actionLabel: 'Desfazer',
      onAction: () {
        if (!mounted) return;
        setState(() {
          final l = [..._linhas];
          l.insert(i.clamp(0, l.length), saiu);
          _linhas = l;
        });
        _removidos.remove(saiu);
        _avisar();
      },
    );
  }

  /// [para] já vem ajustado (onReorderItem).
  void _mover(int de, int para) {
    setState(() {
      final l = [..._linhas];
      l.insert(para, l.removeAt(de));
      _linhas = l;
    });
    _avisar();
  }

  /// Removidos ficam vivos até a folha fechar (o "Desfazer" devolve).
  final _removidos = <(TextEditingController, TextEditingController)>[];

  @override
  void dispose() {
    _soltar(_linhas);
    _soltar(_removidos);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _mover,
          children: [
            for (final (i, linha) in _linhas.indexed)
              Column(
                key: ObjectKey(linha.$1),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            FxIcons.arrastar,
                            size: 20,
                            color: chrome.mute,
                            semanticLabel: 'Arrastar para mudar a ordem',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${widget.nomeDoItem} ${i + 1}',
                          style: FocuxHubTypography.cardTitle(color: chrome.mute),
                        ),
                      ),
                      IconButton(
                        tooltip: s.landingRemover,
                        onPressed: () => _remover(i),
                        icon: const Icon(FxIcons.excluir),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: linha.$1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: FxInputDeco.build(context, widget.rotuloTitulo),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  TextFormField(
                    controller: linha.$2,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    decoration: FxInputDeco.build(context, widget.rotuloTexto),
                  ),
                  const SizedBox(height: TokensStrip.s3),
                ],
              ),
          ],
        ),
        // Adicionar é a última linha da lista, não um botão grande.
        InkWell(
          onTap: _adicionar,
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(FxIcons.adicionar, size: 20, color: primary),
                const SizedBox(width: TokensStrip.s2),
                Text(
                  '${s.landingAdicionarItem} ${widget.nomeDoItem.toLowerCase()}',
                  style: FocuxHubTypography.body(color: primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
