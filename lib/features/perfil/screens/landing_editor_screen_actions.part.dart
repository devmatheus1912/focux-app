part of 'landing_editor_screen.dart';

extension on _LandingEditorScreenState {
  LandingEntrevista _entrevistaFromFields() {
    return LandingEntrevista(
      nomeMarca: _nomeMarca.text,
      nicho: _nicho.text,
      promessa: _promessa.text,
      antiPersona: _antiPersona.text,
      prova: _prova.text,
      ofertaNome: _ofertaNome.text,
      ofertaInclui: _ofertaInclui.text,
      ofertaPreco: _ofertaPreco.text,
      cta: _cta.text,
      duvidas: [
        _duvida1.text,
        _duvida2.text,
        _duvida3.text,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      whatsapp: BrPhone.normalizeOrNull(_whatsapp.text) ?? _whatsapp.text.trim(),
      instagram: _instagram.text.trim().replaceFirst('@', ''),
    );
  }

  void _applyState(LandingStudioState state, {bool preferReview = false}) {
    final e = state.entrevista;
    _nomeMarca.text = e.nomeMarca;
    _nicho.text = e.nicho;
    _promessa.text = e.promessa;
    _antiPersona.text = e.antiPersona;
    _prova.text = e.prova;
    _ofertaNome.text = e.ofertaNome;
    _ofertaInclui.text = e.ofertaInclui;
    _ofertaPreco.text = e.ofertaPreco;
    _cta.text = e.cta;
    _duvida1.text = e.duvidas.isNotEmpty ? e.duvidas[0] : '';
    _duvida2.text = e.duvidas.length > 1 ? e.duvidas[1] : '';
    _duvida3.text = e.duvidas.length > 2 ? e.duvidas[2] : '';
    _whatsapp.text = BrPhone.formatDisplay(e.whatsapp);
    _instagram.text = e.instagram;
    final perfil = ref.read(perfilProvider).value;
    if (_nomeMarca.text.trim().isEmpty) _nomeMarca.text = perfil?.nome ?? '';
    if (_nicho.text.trim().isEmpty) {
      _nicho.text = perfil?.especialidades ?? perfil?.especialidade ?? '';
    }

    _applyGerado(state.gerado);
    _heroImageUrl = state.midia.heroImageUrl;
    _bioImageUrl = state.midia.bioImageUrl;
    _slug = state.slug;
    _publicUrl = state.publicUrl;
    _publicado = state.publicado;
    _needsProof = state.needsProof || state.gerado.needsProof;
    _podePublicar = state.podePublicar || state.gerado.hasPublishableCopy;
    _step = preferReview || state.gerado.hasPublishableCopy ? 1 : 0;
    _dirty = false;
  }

  void _applyGerado(LandingGerado g) {
    _heroTitle.text = g.heroTitle;
    _heroSubtitle.text = g.heroSubtitle;
    _primaryCta.text = g.primaryCta;
    _bio.text = g.bio;
    _fechamento.text = g.fechamento;
    _needsProof = g.needsProof;
    _podePublicar = g.hasPublishableCopy;
    _metodo = List.of(g.metodo);
    _servicos = List.of(g.servicos);
    _faq = List.of(g.faq);
  }

  /// Conta os aprovados para o resumo da seção Depoimentos.
  Future<void> _contarDepoimentos() async {
    try {
      final pagina = await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).listarParaPersonalPagina(aprovado: true);
      if (mounted) setState(() => _depoimentosAprovados = pagina.totalElements);
    } catch (_) {}
  }

  Future<void> _load({bool fromRefresh = false}) async {
    unawaited(_contarDepoimentos());
    if (!fromRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final state = await ref.read(landingStudioRepositoryProvider).getState();
      if (!mounted) return;
      setState(() {
        _applyState(state);
        _loading = false;
        _error = null;
      });
      unawaited(
        AnalyticsService.instance.track(
          fromRefresh
              ? ProductEvents.landingRefreshed
              : ProductEvents.landingViewed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _gerar() async {
    FocusScope.of(context).unfocus();
    final entrevista = _entrevistaFromFields();
    if (!entrevista.isReadyToGenerate) {
      FeedbackHelper.showWarn(
        context,
        'Preencha marca, nicho, promessa, oferta e texto do botão.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(landingStudioRepositoryProvider);
      // No ar, a entrevista só grava ao publicar: ela alimenta a página.
      if (!_publicado) await repo.saveEntrevista(entrevista);
      final gerado = await repo.sugerir(entrevista);
      if (!mounted) return;
      setState(() {
        _applyGerado(gerado);
        _needsProof = gerado.needsProof;
        _podePublicar = gerado.hasPublishableCopy;
        _step = 1;
        _dirty = true;
        _busy = false;
      });
      unawaited(AnalyticsService.instance.track(ProductEvents.landingGerado));
      FeedbackHelper.showSuccess(
        context,
        'Página gerada. Revise e publique.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _uploadImage({required bool hero}) async {
    FocusScope.of(context).unfocus();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    setState(() {
      if (hero) {
        _uploadingHero = true;
      } else {
        _uploadingBio = true;
      }
    });
    try {
      final bytes = await file.readAsBytes();
      final url = await MediaUploadService(ref.read(apiClientProvider))
          .uploadBytes(
            bytes: bytes,
            filename: file.name,
            folder: 'landing',
            resourceType: 'image',
          );
      if (!mounted) return;
      setState(() {
        if (hero) {
          _heroImageUrl = url;
        } else {
          _bioImageUrl = url;
        }
        _uploadingHero = false;
        _uploadingBio = false;
        _dirty = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingHero = false;
        _uploadingBio = false;
      });
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  LandingGerado _geradoFromFields() {
    return LandingGerado(
      heroTitle: _heroTitle.text,
      heroSubtitle: _heroSubtitle.text,
      primaryCta: _primaryCta.text,
      bio: _bio.text,
      metodo: _metodo,
      servicos: _servicos,
      faq: _faq,
      fechamento: _fechamento.text,
      needsProof: _needsProof,
    );
  }

  Future<void> _publicar() async {
    FocusScope.of(context).unfocus();
    if (_heroTitle.text.trim().isEmpty || _primaryCta.text.trim().isEmpty) {
      FeedbackHelper.showWarn(
        context,
        'Título principal e texto do botão são obrigatórios.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(landingStudioRepositoryProvider);
      await repo.saveEntrevista(_entrevistaFromFields());
      await repo.saveMidia(
        heroImageUrl: _heroImageUrl,
        bioImageUrl: _bioImageUrl,
      );
      final state = await repo.publicar(gerado: _geradoFromFields());
      if (!mounted) return;
      setState(() {
        _slug = state.slug ?? _slug;
        _publicUrl = state.publicUrl ?? _publicUrl;
        _publicado = true;
        _podePublicar = state.podePublicar;
        _needsProof = state.needsProof;
        _busy = false;
        _dirty = false;
      });
      HapticFeedback.mediumImpact();
      unawaited(
        AnalyticsService.instance.track(ProductEvents.landingPublicado),
      );
      FeedbackHelper.showSuccess(
        context,
        'Landing no ar · ${_publicUrlLabel()}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  /// Só o caminho ("/p/matheus"): cabe com fonte grande. O endereço inteiro
  /// vai ao copiar e ao leitor de tela.
  String _publicUrlCurto() {
    final slug = (_slug ?? '').trim();
    return slug.isEmpty ? _publicUrlLabel() : '/p/$slug';
  }

  String _publicUrlLabel() {
    final slug = (_slug ?? '').trim();
    if (slug.isNotEmpty) return Env.landingPageDisplayLabel(slug);
    final url = (_publicUrl ?? '').trim();
    if (url.isNotEmpty) {
      final host = Uri.tryParse(url)?.host;
      if (host != null && host.isNotEmpty) {
        return url.replaceFirst(RegExp(r'^https?://'), '');
      }
      return url;
    }
    return 'focuxpersonal.com/p/…';
  }

  String? _resolvedPublicUrl() {
    final fromState = (_publicUrl ?? '').trim();
    if (fromState.isNotEmpty) {
      final slug = (_slug ?? '').trim();
      if (slug.isNotEmpty) return Env.landingPageUrl(slug);
      return fromState;
    }
    final slug = (_slug ?? '').trim();
    if (slug.isNotEmpty) return Env.landingPageUrl(slug);
    return null;
  }

  Future<void> _copyLink() async {
    final url = _resolvedPublicUrl();
    if (url == null) {
      FeedbackHelper.showWarn(
        context,
        'Publique a landing para gerar o endereço.',
      );
      return;
    }
    await copyLandingLink(
      context,
      url: url,
      successMessage: 'Link copiado',
    );
  }

  Future<void> _openPublicOrPreview() async {
    final url = _resolvedPublicUrl();
    if (_publicado && !_dirty && url != null) {
      await openLandingLink(context, url: url);
      return;
    }
    try {
      final html = await ref
          .read(landingStudioRepositoryProvider)
          .previewHtml(
            entrevista: _entrevistaFromFields(),
            gerado: _geradoFromFields(),
            heroImageUrl: _heroImageUrl,
            bioImageUrl: _bioImageUrl,
          );
      if (!mounted) return;
      if (html.trim().isEmpty) {
        FeedbackHelper.showWarn(context, 'Preview indisponível ainda.');
        return;
      }
      unawaited(
        AnalyticsService.instance.track(ProductEvents.landingPreviewOpened),
      );
      await openLandingPreviewScreen(context, html: html);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _onBack() async {
    FocusScope.of(context).unfocus();
    if (_step == 0 && _etapa > 0 && !_busy) {
      _etapaAnterior();
      return;
    }
    if (_step == 0 && _heroTitle.text.trim().isNotEmpty && !_busy) {
      setState(() => _step = 1);
      return;
    }
    if (_dirty) {
      final leave = await showFxConfirmSheet(
        context,
        title: 'Sair sem salvar?',
        message: 'As alterações desta tela ainda não foram publicadas.',
        confirmLabel: 'Sair',
        destructive: true,
      );
      if (!leave || !mounted) return;
    }
    if (!mounted) return;
    safePopOrGo(context, '/perfil');
  }

  void _etapaAnterior() => setState(() => _etapa--);

  void _proximaEtapa() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _etapa++);
  }

  List<LandingPendencia> get _pendencias => landingPendencias(
    S.of(context),
    heroImageUrl: _heroImageUrl,
    ofertaPreco: _ofertaPreco.text,
    needsProof: _needsProof,
    provaTexto: _prova.text,
    bioImageUrl: _bioImageUrl,
    heroTitle: _heroTitle.text,
    primaryCta: _primaryCta.text,
    whatsapp: _whatsapp.text,
  );

  /// Código ainda é o padrão: aluno e link dependem dele.
  bool get _codigoProvisorio {
    final slug = (_slug ?? '').trim();
    return slug.isEmpty ||
        slug == 'personal' ||
        RegExp(r'^personal-\d+$').hasMatch(slug);
  }

  String _textoPublicar(S s) {
    if (!_publicado) return s.landingPublicar;
    return _dirty ? s.landingPublicarAlteracoes : s.landingTudoPublicado;
  }

  void _voltarParaEntrevista() => setState(() {
    _step = 0;
    _etapa = 0;
  });

  /// Altera uma lista da página e marca que há o que publicar.
  void _mudarLista(VoidCallback mudanca) {
    mudanca();
    _markDirty();
  }

  Future<void> _abrirSecao(BuildContext context, LandingSecao secao) async {
    await showFxHomeSheet<void>(
      context,
      isScrollControlled: true,
      builder: (_) => _LandingSecaoFolha(secao: secao, state: this),
    );
    if (mounted) setState(() {});
  }

  String _resumoDaSecao(S s, LandingSecao secao) {
    String primeira(String? t) => t?.trim().isNotEmpty == true ? t!.trim() : s.landingVazio;
    return switch (secao) {
      LandingSecao.capa => primeira(_heroTitle.text),
      LandingSecao.sobre => primeira(_bio.text),
      LandingSecao.metodo => landingResumoTitulos(
        [for (final m in _metodo) m.titulo],
        vazio: s.landingVazio,
      ),
      LandingSecao.inclui => landingResumoTitulos(
        [for (final i in _servicos) i.titulo],
        vazio: s.landingVazio,
      ),
      LandingSecao.planos => primeira(
        [_ofertaNome.text, _ofertaPreco.text]
            .where((t) => t.trim().isNotEmpty)
            .join(' · '),
      ),
      LandingSecao.depoimentos => landingDepoimentosResumo(_depoimentosAprovados),
      LandingSecao.perguntas => landingResumoTitulos(
        [for (final f in _faq) f.pergunta],
        vazio: s.landingVazio,
      ),
      LandingSecao.contato => primeira(_whatsapp.text),
    };
  }

  /// "⋯" do topo: refazer a página pela entrevista (pede confirmação).
  Future<void> _maisDaLanding() async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: 'Mais ações',
      grupos: [
        FxActionGroup<String>(null, const [
          FxActionItem(
            valor: 'refazer',
            rotulo: 'Refazer pela entrevista',
            icone: FxIcons.ia,
          ),
        ]),
      ],
    );
    if (escolha != 'refazer' || !mounted) return;
    final ok = await showFxConfirmSheet(
      context,
      title: 'Refazer a página?',
      message:
          'Os textos de todas as seções serão trocados por novos. Fotos, planos e depoimentos ficam.',
      confirmLabel: 'Refazer',
    );
    if (ok && mounted) _voltarParaEntrevista();
  }

  /// Textos atuais de uma seção (para desfazer o "Refazer com IA").
  VoidCallback _guardarSecao(LandingSecao secao) {
    final titulo = _heroTitle.text;
    final sub = _heroSubtitle.text;
    final cta = _primaryCta.text;
    final bio = _bio.text;
    final metodo = List.of(_metodo);
    final servicos = List.of(_servicos);
    final faq = List.of(_faq);
    final fechamento = _fechamento.text;
    return () => setState(() {
      switch (secao) {
        case LandingSecao.capa:
          _heroTitle.text = titulo;
          _heroSubtitle.text = sub;
          _primaryCta.text = cta;
        case LandingSecao.sobre:
          _bio.text = bio;
        case LandingSecao.metodo:
          _metodo = metodo;
        case LandingSecao.inclui:
          _servicos = servicos;
        case LandingSecao.perguntas:
          _faq = faq;
        case LandingSecao.contato:
          _fechamento.text = fechamento;
        case LandingSecao.planos:
        case LandingSecao.depoimentos:
          break;
      }
      _dirty = true;
    });
  }

  /// Texto novo só desta seção; o resto continua como está. Avisa com
  /// "Desfazer", que volta o texto anterior.
  Future<void> _refazerSecao(LandingSecao secao, {VoidCallback? depois}) async {
    FocusScope.of(context).unfocus();
    final desfazer = _guardarSecao(secao);
    try {
      final g = await ref
          .read(landingStudioRepositoryProvider)
          .sugerir(_entrevistaFromFields());
      if (!mounted) return;
      setState(() {
        switch (secao) {
          case LandingSecao.capa:
            _heroTitle.text = g.heroTitle;
            _heroSubtitle.text = g.heroSubtitle;
            _primaryCta.text = g.primaryCta;
          case LandingSecao.sobre:
            _bio.text = g.bio;
          case LandingSecao.metodo:
            _metodo = List.of(g.metodo);
          case LandingSecao.inclui:
            _servicos = List.of(g.servicos);
          case LandingSecao.perguntas:
            _faq = List.of(g.faq);
          case LandingSecao.contato:
            _fechamento.text = g.fechamento;
          case LandingSecao.planos:
          case LandingSecao.depoimentos:
            break;
        }
        _dirty = true;
      });
      FeedbackHelper.showSuccessAction(
        context,
        'Textos de ${landingSecaoTitulo(S.of(context), secao)} refeitos.',
        actionLabel: 'Desfazer',
        onAction: () {
          desfazer();
          depois?.call();
        },
      );
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  bool get _canPublish {
    if (_busy || _uploadingHero || _uploadingBio) return false;
    if (!_podePublicar) return false;
    if (_publicado && !_dirty) return false;
    return _heroTitle.text.trim().isNotEmpty &&
        _primaryCta.text.trim().isNotEmpty;
  }

  String get _appBarSubtitle {
    return _step == 0
        ? 'Entrevista · ${_etapa + 1} de $_etapasEntrevista'
        : _publicado
            ? 'No ar'
            : 'Rascunho';
  }
}

/// "Diagnóstico, Programa, Ajustes"; vazio: "Ainda vazio".
String landingResumoTitulos(List<String> titulos, {required String vazio}) {
  final limpos = [
    for (final t in titulos)
      if (t.trim().isNotEmpty) t.trim(),
  ];
  return limpos.isEmpty ? vazio : limpos.join(', ');
}

/// "2 aprovados" / "Nenhum aprovado ainda"; sem contagem, o texto de antes.
String landingDepoimentosResumo(int? aprovados) => switch (aprovados) {
  null => 'Vêm dos depoimentos aprovados',
  0 => 'Nenhum aprovado ainda',
  1 => '1 aprovado',
  final n => '$n aprovados',
};
