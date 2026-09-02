part of 'login_screen.dart';

extension on _LoginScreenState {
  void _trackLogin({required bool success, required String method}) {
    unawaited(
      AnalyticsService.instance.track(
        success ? ProductEvents.loginSuccess : ProductEvents.loginFailure,
        props: {
          'role': loginRoleQuery(isAluno: _isAluno),
          'method': method,
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
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      if (_isAluno) {
        if (_personalSlug == null || _personalSlug!.trim().isEmpty) {
          setState(() {
            _error =
                'Abra o link do seu personal (?p=slug) para entrar como aluno.';
            _loading = false;
          });
          return;
        }
        await ref.read(authProvider.notifier).loginAluno(
          _emailController.text.trim(),
          _passwordController.text,
          personalSlug: _personalSlug,
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
      _trackLogin(success: false, method: 'password');
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
      if (_isAluno &&
          (_personalSlug == null || _personalSlug!.trim().isEmpty)) {
        throw StateError('PERSONAL_SLUG_REQUIRED');
      }
      await ref.read(authProvider.notifier).loginGoogle(
        idToken: idToken,
        isAluno: _isAluno,
        personalSlug: _isAluno ? _personalSlug : null,
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
      _trackLogin(success: false, method: 'google');
      setState(() => _error = mapGoogleSignInError(error, isAluno: _isAluno));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
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

class _AuthDivider extends StatelessWidget {
  final String label;

  const _AuthDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: heroTealSurface(0.2), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: FocuxHubTypography.bodyMuted(
              color: heroTealSurface(0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: heroTealSurface(0.2), height: 1)),
      ],
    );
  }
}
