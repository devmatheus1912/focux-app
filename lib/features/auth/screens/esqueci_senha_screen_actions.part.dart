part of 'esqueci_senha_screen.dart';

extension on _EsqueciSenhaScreenState {
  String get _loginPath =>
      esqueciLoginPath(isAluno: _isAluno, personalSlug: _personalSlug);

  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: esqueciHelpTitle(),
      subtitle: esqueciHelpSubtitle(isAluno: _isAluno),
      tips: [
        if (esqueciMostraCodigo(isAluno: _isAluno))
          FxHelpTip('Código', esqueciHelpCodigoBody(), icon: 'spark'),
        FxHelpTip(
          'Papel',
          esqueciHelpPapelBody(isAluno: _isAluno),
          icon: 'users',
        ),
      ],
    );
  }

  Future<void> _pedirEnviar() async {
    if (_loading || !esqueciMostraCodigo(isAluno: _isAluno)) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final ok = await showFxConfirmSheet(
      context,
      title: esqueciConfirmTitle(),
      message: esqueciConfirmMessage(),
      confirmLabel: esqueciEnviarLabel(),
    );
    if (!ok || !mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    if (!esqueciMostraCodigo(isAluno: _isAluno)) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(authRepositoryProvider)
          .solicitarResetSenha(email: _emailController.text.trim());

      if (!mounted) {
        return;
      }

      context.go(
        esqueciVerificarCodigoPath(
          email: _emailController.text.trim(),
          isAluno: false,
          personalSlug: _personalSlug,
        ),
      );
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.passwordResetRequested,
          props: {'role': 'personal'},
        ),
      );
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() {
        _error = mapEsqueciSenhaError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
