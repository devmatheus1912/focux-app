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
      if (_isAluno) {
        final slug = _effectivePersonalSlug;
        if (slug == null || slug.isEmpty) {
          setState(() {
            _error = loginSlugMissingError();
            _loading = false;
          });
          return;
        }
        await ref
            .read(authProvider.notifier)
            .loginAluno(
              _emailController.text.trim(),
              _passwordController.text,
              personalSlug: slug,
            );
        if (!mounted) return;
        _trackLogin(success: true, method: 'password');
        final requiresChange =
            ref.read(authProvider.notifier).requiresPasswordChange;
        context.go(
          requiresChange
              ? '/aluno/definir-senha'
              : _postLoginRedirect(context, isAluno: true),
        );
      } else {
        await ref
            .read(authProvider.notifier)
            .login(_emailController.text.trim(), _passwordController.text);
        if (!mounted) return;
        _trackLogin(success: true, method: 'password');
        context.go(await _postPersonalLoginRedirect(context));
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
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

  Future<void> _submitGoogle() async {
    if (_loading || _loadingGoogle || _loadingApple) return;
    setState(() {
      _loadingGoogle = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final result = await GoogleSignInService().signInForIdToken();
      if (result == null) return;
      final idToken = result.idToken;
      if (_isAluno &&
          (_effectivePersonalSlug == null ||
              _effectivePersonalSlug!.isEmpty)) {
        throw StateError('PERSONAL_SLUG_REQUIRED');
      }
      await ref
          .read(authProvider.notifier)
          .loginGoogle(
            idToken: idToken,
            isAluno: _isAluno,
            personalSlug: _isAluno ? _effectivePersonalSlug : null,
          );
      if (!mounted) return;
      _trackLogin(success: true, method: 'google');
      if (_isAluno) {
        context.go(_postLoginRedirect(context, isAluno: true));
      } else {
        context.go(await _postPersonalLoginRedirect(context));
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
      final credential = await const AppleSignInService().signIn();
      if (credential == null) return;
      if (_isAluno &&
          (_effectivePersonalSlug == null ||
              _effectivePersonalSlug!.isEmpty)) {
        throw StateError('PERSONAL_SLUG_REQUIRED');
      }
      await ref
          .read(authProvider.notifier)
          .loginApple(
            identityToken: credential.identityToken,
            isAluno: _isAluno,
            fullName: credential.fullName,
            email: credential.email,
            personalSlug: _isAluno ? _effectivePersonalSlug : null,
          );
      if (!mounted) return;
      _trackLogin(success: true, method: 'apple');
      if (_isAluno) {
        context.go(_postLoginRedirect(context, isAluno: true));
      } else {
        context.go(await _postPersonalLoginRedirect(context));
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
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

  Future<String> _postPersonalLoginRedirect(BuildContext context) async {
    final fallback = _postLoginRedirect(context, isAluno: false);
    try {
      invalidateSessionUserCaches(ref);
      ref.invalidate(perfilProvider);
      prefetchPersonalDashboardHome(ref);
      prefetchAlunosHome(ref);
      await ref.read(perfilProvider.future);
    } catch (_) {
      // Prefetch best-effort — Home ainda é o destino.
    }
    return fallback;
  }
}
