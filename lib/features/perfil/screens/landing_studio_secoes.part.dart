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
    await st._refazerSecao(widget.secao);
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
          if (landingSecaoAceitaIa(secao)) ...[
            const SizedBox(height: TokensStrip.s2),
            FxTonalButton(
              label: _refazendo ? s.landingRefazendo : s.landingRefazerSecao,
              expanded: true,
              onPressed: _refazendo ? null : _refazer,
            ),
          ],
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
  });

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

  void _remover(int i) {
    final saiu = _linhas[i];
    setState(() => _linhas = [..._linhas]..removeAt(i));
    _avisar();
    _soltar([saiu]);
  }

  void _subir(int i) {
    setState(() {
      final l = [..._linhas];
      l.insert(i - 1, l.removeAt(i));
      _linhas = l;
    });
    _avisar();
  }

  @override
  void dispose() {
    _soltar(_linhas);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, linha) in _linhas.indexed) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  '${i + 1}',
                  style: FocuxHubTypography.cardTitle(
                    color: ShellChrome.of(context).mute,
                  ),
                ),
              ),
              if (i > 0)
                IconButton(
                  tooltip: s.landingSubir,
                  onPressed: () => _subir(i),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              IconButton(
                tooltip: s.landingRemover,
                onPressed: () => _remover(i),
                icon: const Icon(Icons.delete_outline_rounded),
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
        FxTonalButton(
          label: s.landingAdicionarItem,
          icon: Icons.add_rounded,
          expanded: true,
          onPressed: _adicionar,
        ),
      ],
    );
  }
}
