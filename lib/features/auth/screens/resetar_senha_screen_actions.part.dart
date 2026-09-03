part of 'resetar_senha_screen.dart';

extension on _ResetarSenhaScreenState {
  bool get _isAluno => _role == 'aluno';

  String get _loginPath =>
      esqueciLoginPath(isAluno: _isAluno, personalSlug: _personalSlug);

  String get _esqueciPath =>
      loginEsqueciPath(isAluno: _isAluno, personalSlug: _personalSlug);

  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: resetSenhaHelpTitle(),
      subtitle: resetSenhaHelpSubtitle(),
      tips: [
        FxHelpTip('Senha', resetSenhaHelpSenhaBody(), icon: 'spark'),
        FxHelpTip('Código', resetSenhaHelpSessaoBody(), icon: 'route'),
      ],
    );
  }

  Future<void> _pedirAlterar() async {
    if (_loading || !resetSenhaHasNonce(_resetNonce)) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final ok = await showFxConfirmSheet(
      context,
      title: resetSenhaConfirmTitle(),
      message: resetSenhaConfirmMessage(),
      confirmLabel: resetSenhaAlterarLabel(),
    );
    if (!ok || !mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (!resetSenhaHasNonce(_resetNonce)) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(authRepositoryProvider)
          .confirmarResetSenha(
            resetNonce: _resetNonce,
            novaSenha: _senhaController.text,
          );
      if (!mounted) return;
      setState(() => _message = resetSenhaSucesso());
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.passwordResetCompleted,
          props: {'role': _isAluno ? 'aluno' : 'personal'},
        ),
      );
      _goLoginTimer?.cancel();
      _goLoginTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) context.go(_loginPath);
      });
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() => _error = mapResetSenhaError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
