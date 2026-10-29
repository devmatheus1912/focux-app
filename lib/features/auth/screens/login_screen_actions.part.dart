part of 'login_screen.dart';

extension on _LoginScreenState {
  void _trackLogin({
    required bool success,
    required String method,
    String? codigo,
  }) {
    unawaited(
      AnalyticsService.instance.track(
        success ? ProductEvents.loginSuccess : ProductEvents.loginFailure,
        props: {
          'role': loginRoleQuery(isAluno: _isAluno),
          'method': method,
          if (codigo != null && codigo.isNotEmpty) 'codigo': codigo,
        },
      ),
    );
  }

  Future<void> _carregarBiometria() async {
    final tipo = await ref.read(biometriaLoginProvider).tipoParaEntrar();
    if (mounted) setState(() => _biometria = tipo);
  }

  Future<void> _entrarComBiometria() async {
    if (_loading || _loadingGoogle || _loadingApple) return;
    final tipo = _biometria;
    final cred = await ref
        .read(biometriaLoginProvider)
        .entrar('Entrar no Focux${tipo == null ? '' : ' com ${tipo.rotulo}'}');
    if (cred == null || !mounted) return;
    _emailController.text = cred.email;
    _passwordController.text = cred.senha;
    setState(() {
      _isAluno = cred.aluno;
      _editandoCodigo = false;
      final slug = cred.personalSlug;
      if (slug != null) _slugController.text = slug;
    });
    _viaBiometria = true;
    try {
      await _submit();
    } finally {
      _viaBiometria = false;
    }
  }

  /// Depois do login com senha: mantém a biometria em dia ou oferece ativar.
  Future<void> _posLoginBiometria({required bool aluno, String? slug}) async {
    final bio = ref.read(biometriaLoginProvider);
    final cred = CredencialBiometria(
      email: _emailController.text.trim(),
      senha: _passwordController.text,
      aluno: aluno,
      personalSlug: aluno ? slug : null,
    );
    try {
      if (await bio.ativa()) {
        await bio.atualizarSeAtiva(cred);
        return;
      }
      if (_viaBiometria) return;
      final tipo = await bio.tipoParaOferecer();
      if (tipo == null || !mounted) return;
      final aceitou = await showAuthBiometriaSheet(context, tipo: tipo);
      if (aceitou == true) {
        await bio.ativar(cred, 'Confirme para ativar ${tipo.rotulo}');
      } else {
        await bio.adiarOferta();
      }
    } catch (_) {
      // Biometria é conveniência: nunca trava o login.
    }
  }

  /// Credencial guardada recusada: a senha mudou. Apaga e pede a senha.
  Future<void> _credencialBiometriaRecusada() async {
    await ref.read(biometriaLoginProvider).desativar();
    if (!mounted) return;
    _passwordController.clear();
    setState(() {
      _biometria = null;
      _error = 'Sua senha mudou. Entre com e-mail e senha.';
    });
  }

  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: loginHelpTitle(),
      subtitle: loginHelpSubtitle(),
      tips: [
        FxHelpTip('Personal', loginHelpPersonalBody(), icon: 'users'),
        FxHelpTip('Aluno', loginHelpAlunoBody(), icon: 'route'),
      ],
    );
  }

  Future<void> _submit() async {
    if (_loading || _loadingGoogle || _loadingApple) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      logAuthApiUrl('login');
      if (_isAluno) {
        final slug = _effectivePersonalSlug;
        if (slug == null || slug.isEmpty) {
          setState(() {
            _error = loginSlugMissingError();
            _loading = false;
          });
          return;
        }
        logAuthHttpCall(
          'login',
          path: '/api/auth/login/aluno',
          method: 'POST',
          isAluno: true,
          hasPersonalSlug: true,
        );
        await ref
            .read(authProvider.notifier)
            .loginAluno(
              _emailController.text.trim(),
              _passwordController.text,
              personalSlug: slug,
            );
        if (!mounted) return;
        logAuthHttpOk('login', path: '/api/auth/login/aluno');
        await PersonalSlugStore.save(slug);
        if (!mounted) return;
        await _posLoginBiometria(aluno: true, slug: slug);
        if (!mounted) return;
        _trackLogin(success: true, method: 'password');
        final requiresChange =
            ref.read(authProvider.notifier).requiresPasswordChange;
        if (!requiresChange) {
          await _prefetchAlunoAfterLogin();
          if (!mounted) return;
        }
        context.go(
          requiresChange
              ? '/aluno/definir-senha'
              : _postLoginRedirect(context, isAluno: true),
        );
      } else {
        logAuthHttpCall(
          'login',
          path: '/api/auth/login',
          method: 'POST',
          isAluno: false,
        );
        final result = await ref
            .read(authProvider.notifier)
            .login(_emailController.text.trim(), _passwordController.text);
        if (!mounted) return;
        logAuthHttpOk('login', path: '/api/auth/login');
        if (await _maybeOpenMfa(result, method: 'password')) return;
        if (!mounted) return;
        // ignore: unawaited_futures
        PersonalSlugStore.save(null);
        await _posLoginBiometria(aluno: false);
        if (!mounted) return;
        _trackLogin(success: true, method: 'password');
        await _prefetchPersonalAfterLogin();
        if (!mounted) return;
        context.go(await _personalPostLoginDestination());
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      logAuthHttpError('login', error);
      _trackLogin(
        success: false,
        method: 'password',
        codigo: ApiError.from(error)?.codigo,
      );
      final status = ApiError.from(error)?.status;
      if (_viaBiometria && (status == 400 || status == 401 || status == 403)) {
        await _credencialBiometriaRecusada();
      } else {
        setState(() {
          _error = mapLoginError(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Se o backend pediu MFA, guarda mfaToken em memória e abre a challenge.
  Future<bool> _maybeOpenMfa(
    AuthLoginResult result, {
    required String method,
  }) async {
    if (!result.mfaRequired) return false;
    final token = result.mfaToken?.trim();
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Não foi possível iniciar a verificação MFA.');
      return true;
    }
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    ref.read(mfaChallengeProvider.notifier).value = MfaChallenge(
      mfaToken: token,
      returnTo: from,
    );
    _trackLogin(success: true, method: '${method}_mfa_pending');
    context.go('/login/mfa');
    return true;
  }

  Future<void> _submitGoogle() async {
    if (_loading || _loadingGoogle || _loadingApple) return;
    setState(() {
      _loadingGoogle = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final google = await GoogleSignInService().signInForIdToken();
      if (google == null) return;
      final result = await ref
          .read(authProvider.notifier)
          .loginGoogle(idToken: google.idToken);
      if (!mounted) return;
      if (await _maybeOpenMfa(result, method: 'google')) return;
      if (!mounted) return;
      _trackLogin(success: true, method: 'google');
      await _prefetchPersonalAfterLogin();
      if (!mounted) return;
      context.go(await _personalPostLoginDestination());
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      _trackLogin(
        success: false,
        method: 'google',
        codigo: ApiError.from(error)?.codigo,
      );
      setState(() => _error = mapGoogleSignInError(error));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _submitApple() async {
    if (_loading || _loadingGoogle || _loadingApple) return;
    setState(() {
      _loadingApple = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      logAuthApiUrl('login/apple');
      final credential = await const AppleSignInService().signIn();
      if (credential == null) return;
      logAuthHttpCall(
        'login/apple',
        path: '/api/auth/apple',
        method: 'POST',
        isAluno: false,
        identityTokenLen: credential.identityToken.length,
      );
      final result = await ref
          .read(authProvider.notifier)
          .loginApple(
            identityToken: credential.identityToken,
            fullName: credential.fullName,
            email: credential.email,
            authorizationCode: credential.authorizationCode,
            rawNonce: credential.rawNonce,
          );
      if (!mounted) return;
      logAuthHttpOk('login/apple', path: '/api/auth/apple');
      if (await _maybeOpenMfa(result, method: 'apple')) return;
      if (!mounted) return;
      _trackLogin(success: true, method: 'apple');
      await _prefetchPersonalAfterLogin();
      if (!mounted) return;
      context.go(await _personalPostLoginDestination());
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      logAuthHttpError('login/apple', error, path: '/api/auth/apple');
      _trackLogin(
        success: false,
        method: 'apple',
        codigo: ApiError.from(error)?.codigo,
      );
      setState(() => _error = mapAppleSignInError(error));
    } finally {
      if (mounted) setState(() => _loadingApple = false);
    }
  }


  String _postLoginRedirect(BuildContext context, {required bool isAluno}) {
    final fallback = isAluno ? '/dashboard/aluno' : '/dashboard/personal';
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from == null) return fallback;
    return safePostLoginPath(from, isAluno: isAluno) ?? fallback;
  }

  Future<String> _personalPostLoginDestination() async {
    return _postLoginRedirect(context, isAluno: false);
  }

  Future<void> _prefetchPersonalAfterLogin() async {
    try {
      // `main.dart` já faz invalidateSessionUserCaches no flip authenticated.
      // Segundo bust aqui matava o cache e flashava "Algo saiu do ar".
      await Future.wait([
        prefetchPersonalDashboardHome(ref),
        ref.read(perfilProvider.future),
      ]);
      prefetchAlunosHome(ref);
    } catch (_) {
      // Prefetch best-effort — Home ainda é o destino.
    }
  }

  Future<void> _prefetchAlunoAfterLogin() async {
    try {
      await Future.wait([
        prefetchAlunoDashboardHome(ref),
        ref.read(perfilProvider.future),
      ]);
    } catch (_) {}
  }
}
