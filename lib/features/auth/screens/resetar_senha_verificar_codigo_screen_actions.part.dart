part of 'resetar_senha_verificar_codigo_screen.dart';

extension on _ResetarSenhaVerificarCodigoScreenState {
  String get _loginPath =>
      esqueciLoginPath(isAluno: _isAluno, personalSlug: _personalSlug);

  String get _esqueciPath =>
      loginEsqueciPath(isAluno: _isAluno, personalSlug: _personalSlug);

  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: resetCodigoHelpTitle(),
      subtitle: resetCodigoHelpSubtitle(),
      tips: [
        FxHelpTip('Código', resetCodigoHelpCodigoBody(), icon: 'spark'),
        FxHelpTip('Papel', resetCodigoHelpPapelBody(), icon: 'users'),
      ],
    );
  }

  Future<void> _pedirReenviar() async {
    if (_resending || _email.isEmpty || resendSeconds > 0) return;
    final ok = await showFxConfirmSheet(
      context,
      title: resetCodigoReenviarConfirmTitle(),
      message: resetCodigoReenviarConfirmMessage(),
      confirmLabel: esqueciEnviarLabel(),
    );
    if (!ok || !mounted) return;
    await _resend();
  }

  Future<void> _pedirContinuar() async {
    if (_loading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    await _submit();
  }

  Future<void> _resend() async {
    if (_email.isEmpty) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    HapticFeedback.selectionClick();
    try {
      await ref.read(authRepositoryProvider).solicitarResetSenha(
        email: _email,
        isAluno: _isAluno,
        personalSlug: _isAluno ? _personalSlug : null,
      );
      if (!mounted) return;
      startResendCooldown();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = mapEsqueciSenhaError(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final nonce = await ref.read(authRepositoryProvider).validarResetCodigo(
        email: _email,
        codigo: _codeController.text.trim(),
        isAluno: _isAluno,
        personalSlug: _isAluno ? _personalSlug : null,
      );
      if (!mounted) return;
      context.go(
        resetCodigoNovaSenhaPath(
          nonce: nonce,
          isAluno: _isAluno,
          personalSlug: _personalSlug,
        ),
      );
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _error = mapResetCodigoError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
