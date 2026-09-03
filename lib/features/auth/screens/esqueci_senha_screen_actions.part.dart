part of 'esqueci_senha_screen.dart';

extension on _EsqueciSenhaScreenState {
  String get _loginPath =>
      esqueciLoginPath(isAluno: _isAluno, personalSlug: _personalSlug);

  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: esqueciHelpTitle(),
      subtitle: esqueciHelpSubtitle(),
      tips: [
        FxHelpTip('Código', esqueciHelpCodigoBody(), icon: 'spark'),
        FxHelpTip('Papel', esqueciHelpPapelBody(), icon: 'users'),
      ],
    );
  }

  Future<void> _pedirEnviar() async {
    if (_loading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_isAluno && (_personalSlug == null || _personalSlug!.trim().isEmpty)) {
      setState(() => _error = esqueciAlunoSemSlugError());
      return;
    }
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
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_isAluno && (_personalSlug == null || _personalSlug!.trim().isEmpty)) {
      setState(() => _error = esqueciAlunoSemSlugError());
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
          .solicitarResetSenha(
            email: _emailController.text.trim(),
            isAluno: _isAluno,
            personalSlug: _isAluno ? _personalSlug : null,
          );

      if (!mounted) {
        return;
      }

      context.go(
        esqueciVerificarCodigoPath(
          email: _emailController.text.trim(),
          isAluno: _isAluno,
          personalSlug: _personalSlug,
        ),
      );
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.passwordResetRequested,
          props: {'role': _isAluno ? 'aluno' : 'personal'},
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
