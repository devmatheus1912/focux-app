part of 'identidade_visual_screen.dart';

Future<void> _abrirIdentidadeAjuda(BuildContext context) {
  unawaited(
    AnalyticsService.instance.track(ProductEvents.identidadeHelpOpened),
  );
  return showFxHelpSheet(
    context,
    title: identidadeHelpTitle(),
    subtitle: identidadeHelpSubtitle(),
    tips: [
      FxHelpTip('Marca', identidadeHelpMarcaBody(), icon: FxIcons.ia),
      FxHelpTip('Salvar', identidadeHelpSalvarBody(), icon: FxIcons.concluido),
    ],
  );
}

extension on _IdentidadeVisualScreenState {
  /// A faixa aparece quando o fim da prévia passa do topo da área rolável.
  void _atualizarFaixa() {
    final previa = _previaKey.currentContext?.findRenderObject();
    final corpo = _corpoKey.currentContext?.findRenderObject();
    bool visivel;
    if (previa is RenderBox && corpo is RenderBox && previa.attached) {
      final fundo =
          previa
              .localToGlobal(Offset(0, previa.size.height), ancestor: corpo)
              .dy;
      visivel = fundo < 0;
    } else {
      visivel = _scroll.hasClients && _scroll.offset > 0;
    }
    if (visivel != _faixaVisivel) setState(() => _faixaVisivel = visivel);
  }

  Widget _faixa() {
    final parado = TokensStrip.prefersReducedMotion(context);
    return Positioned(
      top: TokensStrip.s2,
      left: FxSettingsLayout.pageInset,
      right: FxSettingsLayout.pageInset,
      child: IgnorePointer(
        ignoring: !_faixaVisivel,
        child: AnimatedOpacity(
          opacity: _faixaVisivel ? 1 : 0,
          duration: Duration(milliseconds: parado ? 0 : 180),
          child: _FaixaDaPrevia(
            palette: _palette,
            estilo: identidadeEstiloLabel(_estilo),
            onTap:
                () => _scroll.animateTo(
                  0,
                  duration: Duration(milliseconds: parado ? 0 : 280),
                  curve: Curves.easeOutCubic,
                ),
          ),
        ),
      ),
    );
  }

  Future<void> _pedirTrocarLogo() async {
    if (_uploadingLogo) return;
    FxKeyboardDismissScope.dismiss();
    final ok = await showFxConfirmSheet(
      context,
      title: identidadeLogoConfirmTitle(),
      message: identidadeLogoConfirmMessage(),
      confirmLabel: identidadeConfirmarLabel(),
    );
    if (!ok || !mounted) return;
    await _pickLogo();
  }

  /// Sem Enterprise: logo, capa e o rodapé levam ao plano.
  void _abrirEnterprise() => context.push('/assinatura');

  Future<void> _pedirSalvar({required bool hasWhiteLabel}) async {
    if (!hasWhiteLabel || _salvando) return;
    FxKeyboardDismissScope.dismiss();
    if (_sloganCtrl.text.trim().length > identidadeSloganMax) {
      FeedbackHelper.showError(
        context,
        'Encurte o slogan para até $identidadeSloganMax caracteres.',
      );
      return;
    }
    final ok = await showFxConfirmSheet(
      context,
      title: identidadeSalvarConfirmTitle(),
      message: identidadeSalvarConfirmMessage(),
      confirmLabel: identidadeSalvarLabel(isSetup: widget.isSetup),
    );
    if (!ok || !mounted) return;
    await _salvar(hasWhiteLabel: hasWhiteLabel);
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1024,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingLogo = true);
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'identidade',
        resourceType: 'image',
      );
      if (mounted) setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _pickCapa() async {
    if (_uploadingCapa) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingCapa = true);
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'identidade',
        resourceType: 'image',
      );
      if (mounted) setState(() => _capaUrl = url);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploadingCapa = false);
    }
  }

  Future<void> _salvar({
    required bool hasWhiteLabel,
    String successMessage = 'Identidade visual salva!',
    bool restored = false,
  }) async {
    if (!hasWhiteLabel) return;
    setState(() => _salvando = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final body = <String, dynamic>{
        'corPrimaria': BrandPalette.toHex(_corPrimaria),
        'corSecundaria': BrandPalette.toHex(_corSecundaria),
        'slogan': _sloganCtrl.text.trim(),
        'estiloMarca': _estilo.api,
        // vazio remove a capa
        'capaUrl': _capaUrl ?? '',
      };
      if (_logoUrl != null) body['logoUrl'] = _logoUrl;
      await dio.put('/api/personal/identidade', data: body);
      ref.read(primaryColorProvider.notifier).value = _corPrimaria;
      ref.read(secondaryColorProvider.notifier).value = _corSecundaria;
      ref.read(brandStyleProvider.notifier).value = _estilo;
      ref.read(capaUrlProvider.notifier).value = _capaUrl;
      final slogan = _sloganCtrl.text.trim();
      ref.read(sloganProvider.notifier).value =
          slogan.isNotEmpty ? slogan : null;
      if (_logoUrl != null && _logoUrl!.isNotEmpty) {
        ref.read(logoUrlProvider.notifier).value = _logoUrl;
      }
      ref.invalidate(perfilProvider);
      unawaited(
        AnalyticsService.instance.track(
          restored
              ? ProductEvents.identidadeRestored
              : ProductEvents.identidadeSaved,
          props: {
            'palette': _palette.id,
            'hasLogo': _logoUrl != null && _logoUrl!.isNotEmpty,
            'hasSlogan': slogan.isNotEmpty,
            'estilo': _estilo.api,
            'hasCapa': _capaUrl != null,
            'setup': widget.isSetup,
          },
        ),
      );
      if (mounted) {
        _fetchedAt = DateTime.now();
        _snapshotBaseline();
        FeedbackHelper.showInfo(context, successMessage);
        if (widget.isSetup) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
