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
      FxHelpTip('Marca', identidadeHelpMarcaBody(), icon: 'spark'),
      FxHelpTip('Salvar', identidadeHelpSalvarBody(), icon: 'circle-check'),
    ],
  );
}

extension on _IdentidadeVisualScreenState {
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

  Future<void> _pedirSalvar({required bool hasWhiteLabel}) async {
    if (!hasWhiteLabel || _salvando) return;
    FxKeyboardDismissScope.dismiss();
    final ok = await showFxConfirmSheet(
      context,
      title: identidadeSalvarConfirmTitle(),
      message: identidadeSalvarConfirmMessage(),
      confirmLabel: identidadeSalvarLabel(isSetup: widget.isSetup),
    );
    if (!ok || !mounted) return;
    await _salvar(hasWhiteLabel: hasWhiteLabel);
  }

  Future<void> _pedirRestaurarCores({required bool hasWhiteLabel}) async {
    if (!hasWhiteLabel || _salvando) return;
    FxKeyboardDismissScope.dismiss();
    final ok = await showFxConfirmSheet(
      context,
      title: identidadeRestaurarConfirmTitle(),
      message: identidadeRestaurarConfirmMessage(),
      confirmLabel: identidadeRestaurarCoresLabel(),
    );
    if (!ok || !mounted) return;
    await _restoreDefaultBrandColors(hasWhiteLabel: hasWhiteLabel);
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

  Future<void> _restoreDefaultBrandColors({required bool hasWhiteLabel}) async {
    if (!hasWhiteLabel) return;
    setState(() => _palette = CuratedBrandPalette.focuxDefault);
    await _salvar(
      hasWhiteLabel: hasWhiteLabel,
      successMessage: 'Cores padrão do Focux restauradas!',
      restored: true,
    );
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
      };
      if (_logoUrl != null) body['logoUrl'] = _logoUrl;
      await dio.put('/api/personal/identidade', data: body);
      ref.read(primaryColorProvider.notifier).value = _corPrimaria;
      ref.read(secondaryColorProvider.notifier).value = _corSecundaria;
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
