part of 'register_screen.dart';

extension on _RegisterScreenState {
  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: registerHelpTitle(),
      subtitle: registerHelpSubtitle(),
      tips: [
        FxHelpTip('Código', registerHelpCodigoBody(), icon: 'spark'),
        FxHelpTip('Google', registerHelpGoogleBody(), icon: 'users'),
      ],
    );
  }

  Future<void> _pedirEnviarCodigo() async {
    if (_sendingCode ||
        _loading ||
        _resendSeconds > 0 ||
        _emailDeliveryAvailable == false) {
      return;
    }
    final ok = await showFxConfirmSheet(
      context,
      title: registerEnviarConfirmTitle(),
      message: registerEnviarConfirmMessage(),
      confirmLabel: registerEnviarCodigoLabel(),
    );
    if (!ok || !mounted) return;
    await _enviarCodigo();
  }

  Future<void> _pedirCriarConta() async {
    if (_loading || _loadingGoogle) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (!_codeSent && _codeController.text.trim().isEmpty) {
      setState(() {
        _error = 'Envie o código para o e-mail antes de criar a conta.';
      });
      return;
    }
    final ok = await showFxConfirmSheet(
      context,
      title: registerCriarConfirmTitle(),
      message: registerCriarConfirmMessage(),
      confirmLabel: registerCriarLabel(),
    );
    if (!ok || !mounted) return;
    await _submit();
  }

  Future<void> _enviarCodigo() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _error = 'Informe um e-mail válido antes de enviar o código.',
      );
      return;
    }
    if (_sendingCode || _resendSeconds > 0) return;

    setState(() {
      _sendingCode = true;
      _error = null;
    });
    HapticFeedback.selectionClick();

    try {
      final result = await ref
          .read(authProvider.notifier)
          .enviarCodigoEmail(email);
      if (!mounted) return;
      if (!result.codigoEnviado) {
        HapticFeedback.heavyImpact();
        setState(() {
          _codeSent = false;
          _error =
              result.hint.isNotEmpty
                  ? result.hint
                  : 'Não enviamos código para este e-mail. Tente Entrar se já tiver conta.';
        });
        return;
      }
      setState(() => _codeSent = true);
      _startResendCountdown();
      FeedbackHelper.showSuccess(
        context,
        result.hint.isNotEmpty
            ? result.hint
            : 'Código enviado. Confira a caixa de entrada (e o spam).',
      );
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() => _error = mapSignupCodeError(error));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (!_codeSent && _codeController.text.trim().isEmpty) {
      setState(() {
        _error = 'Envie o código para o e-mail antes de criar a conta.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
            referralCodigo: widget.referralCodigo,
            telefone: BrPhone.normalizeOrNull(_phoneController.text),
            emailCodigo: _codeController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(perfilProvider);
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.signupSuccess,
          props: {'role': 'personal', 'method': 'email'},
        ),
      );
      context.go('/dashboard/personal');
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.signupFailure,
          props: {'role': 'personal', 'method': 'email'},
        ),
      );
      setState(() {
        _error = mapRegisterError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    if (_loading || _loadingGoogle) return;

    setState(() {
      _loadingGoogle = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final isAndroid = !kIsWeb && Platform.isAndroid;
      final google = GoogleSignIn(
        clientId: isAndroid ? null : Env.googleWebClientId,
        serverClientId: Env.googleWebClientId,
        scopes: const ['email', 'profile'],
      );
      try {
        await google.signOut();
      } catch (_) {}

      final account = await google.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google nao retornou idToken.');
      }

      await ref
          .read(authProvider.notifier)
          .loginGoogle(idToken: idToken, isAluno: false);

      if (!mounted) return;
      ref.invalidate(perfilProvider);
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.signupSuccess,
          props: {'role': 'personal', 'method': 'google'},
        ),
      );
      context.go('/dashboard/personal');
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.signupFailure,
          props: {'role': 'personal', 'method': 'google'},
        ),
      );
      setState(() => _error = mapGoogleSignInError(error, isAluno: false));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }
}
