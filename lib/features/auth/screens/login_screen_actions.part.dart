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
      setState(() {
        _error = mapLoginError(error);
      });
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
    ref.read(mfaChallengeProvider.notifier).state = MfaChallenge(
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
      final idToken = google.idToken;
      if (_isAluno &&
          (_effectivePersonalSlug == null ||
              _effectivePersonalSlug!.isEmpty)) {
        throw StateError('PERSONAL_SLUG_REQUIRED');
      }
      final result = await ref
          .read(authProvider.notifier)
          .loginGoogle(
            idToken: idToken,
            isAluno: _isAluno,
            personalSlug: _isAluno ? _effectivePersonalSlug : null,
          );
      if (!mounted) return;
      if (!_isAluno && await _maybeOpenMfa(result, method: 'google')) {
        return;
      }
      if (!mounted) return;
      _trackLogin(success: true, method: 'google');
      if (_isAluno) {
        await _prefetchAlunoAfterLogin();
        if (!mounted) return;
        context.go(_postLoginRedirect(context, isAluno: true));
      } else {
        await _prefetchPersonalAfterLogin();
        if (!mounted) return;
        context.go(await _personalPostLoginDestination());
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      _trackLogin(
        success: false,
        method: 'google',
        codigo: ApiError.from(error)?.codigo,
      );
      setState(() => _error = mapGoogleSignInError(error, isAluno: _isAluno));
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
      if (_isAluno &&
          (_effectivePersonalSlug == null ||
              _effectivePersonalSlug!.isEmpty)) {
        throw StateError('PERSONAL_SLUG_REQUIRED');
      }
      logAuthHttpCall(
        'login/apple',
        path: '/api/auth/apple',
        method: 'POST',
        isAluno: _isAluno,
        hasPersonalSlug:
            _isAluno &&
            _effectivePersonalSlug != null &&
            _effectivePersonalSlug!.isNotEmpty,
        identityTokenLen: credential.identityToken.length,
      );
      final result = await ref
          .read(authProvider.notifier)
          .loginApple(
            identityToken: credential.identityToken,
            isAluno: _isAluno,
            fullName: credential.fullName,
            email: credential.email,
            personalSlug: _isAluno ? _effectivePersonalSlug : null,
          );
      if (!mounted) return;
      logAuthHttpOk('login/apple', path: '/api/auth/apple');
      if (!_isAluno && await _maybeOpenMfa(result, method: 'apple')) {
        return;
      }
      if (!mounted) return;
      _trackLogin(success: true, method: 'apple');
      if (_isAluno) {
        await _prefetchAlunoAfterLogin();
        if (!mounted) return;
        context.go(_postLoginRedirect(context, isAluno: true));
      } else {
        await _prefetchPersonalAfterLogin();
        if (!mounted) return;
        context.go(await _personalPostLoginDestination());
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      logAuthHttpError('login/apple', error, path: '/api/auth/apple');
      _trackLogin(
        success: false,
        method: 'apple',
        codigo: ApiError.from(error)?.codigo,
      );
      setState(() => _error = mapAppleSignInError(error, isAluno: _isAluno));
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
    try {
      final perfil = ref.read(perfilProvider).valueOrNull;
      if (perfil?.needsBrandPublicIdentity == true) {
        return '/perfil/link-publico';
      }
    } catch (_) {}
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
