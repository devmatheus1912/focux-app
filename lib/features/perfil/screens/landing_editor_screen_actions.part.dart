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

  Future<void> _load({bool fromRefresh = false}) async {
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
        _fetchedAt = DateTime.now();
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
        'Preencha marca, nicho, promessa, oferta e CTA.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(landingStudioRepositoryProvider);
      await repo.saveEntrevista(entrevista);
      final state = await repo.gerar();
      if (!mounted) return;
      setState(() {
        _applyGerado(state.gerado);
        if (state.publicUrl != null) _publicUrl = state.publicUrl;
        if (state.slug != null) _slug = state.slug;
        _needsProof = state.needsProof || state.gerado.needsProof;
        _podePublicar = state.podePublicar || state.gerado.hasPublishableCopy;
        _step = 1;
        _dirty = false;
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
      // Accent vem da identidade; não sobrescreve corPrimaria no BE.
      final midia = await ref.read(landingStudioRepositoryProvider).saveMidia(
            heroImageUrl: hero ? url : _heroImageUrl,
            bioImageUrl: hero ? _bioImageUrl : url,
          );
      if (!mounted) return;
      setState(() {
        _heroImageUrl = midia.heroImageUrl ?? (hero ? url : _heroImageUrl);
        _bioImageUrl = midia.bioImageUrl ?? (hero ? _bioImageUrl : url);
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
        'Título e CTA são obrigatórios para publicar.',
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
    if (_publicado && url != null) {
      await openLandingLink(context, url: url);
      return;
    }
    try {
      final html =
          await ref.read(landingStudioRepositoryProvider).previewHtml();
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
    if (_step == 1 && !_busy) {
      setState(() => _step = 0);
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

  bool get _canGenerate {
    final e = _entrevistaFromFields();
    return e.isReadyToGenerate && !_busy && !_loading;
  }

  bool get _isProfessionalReady => LandingStudioGuidance.isProfessionalReady(
    heroImageUrl: _heroImageUrl,
    ofertaPreco: _ofertaPreco.text,
    needsProof: _needsProof,
    provaTexto: _prova.text,
    bioImageUrl: _bioImageUrl,
    heroTitle: _heroTitle.text,
    primaryCta: _primaryCta.text,
    whatsapp: _whatsapp.text,
  );

  List<String> get _publishMissing => LandingStudioGuidance.missingForPublish(
    heroImageUrl: _heroImageUrl,
    ofertaPreco: _ofertaPreco.text,
    needsProof: _needsProof,
    provaTexto: _prova.text,
    bioImageUrl: _bioImageUrl,
    heroTitle: _heroTitle.text,
    primaryCta: _primaryCta.text,
    whatsapp: _whatsapp.text,
    podePublicar: _podePublicar,
  );

  bool get _canPublish {
    if (_busy || _uploadingHero || _uploadingBio) return false;
    if (!_podePublicar) return false;
    return _heroTitle.text.trim().isNotEmpty &&
        _primaryCta.text.trim().isNotEmpty;
  }

  String get _appBarSubtitle {
    final stepLabel = _step == 0
        ? 'Passo 1 · Entrevista'
        : _publicado
            ? 'No ar · revisar e republicar'
            : 'Passo 2 · Revisar e publicar';
    final fresh = FxHubFreshness.fromFetchedAt(_fetchedAt);
    if (fresh == null || fresh.isEmpty) return stepLabel;
    return '$stepLabel · $fresh';
  }
}
