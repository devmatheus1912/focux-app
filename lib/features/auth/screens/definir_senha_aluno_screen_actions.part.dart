part of 'definir_senha_aluno_screen.dart';

extension on _DefinirSenhaAlunoScreenState {
  Future<void> _sairSemDefinirSenha() async {
    if (_loading || _saindo) return;
    final ok = await showFxConfirmSheet(
      context,
      title: definirSenhaSairTitle(),
      message: definirSenhaSairMessage(),
      confirmLabel: definirSenhaSairConfirmLabel(),
      destructive: true,
    );
    if (!ok || !mounted) return;
    _saindo = true;
    try {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      authUnfocusAndGo(context, '/login?role=aluno');
    } finally {
      if (mounted) _saindo = false;
    }
  }

  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: definirSenhaHelpTitle(),
      subtitle: definirSenhaHelpSubtitle(),
      tips: [
        FxHelpTip('Provisória', definirSenhaHelpAtualBody(), icon: 'route'),
        FxHelpTip('Nova', definirSenhaHelpNovaBody(), icon: 'spark'),
      ],
    );
  }

  Future<void> _pedirSalvar() async {
    if (_loading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final ok = await showFxConfirmSheet(
      context,
      title: definirSenhaConfirmTitle(),
      message: definirSenhaConfirmMessage(),
      confirmLabel: definirSenhaSalvarLabel(),
    );
    if (!ok || !mounted) return;
    await _submit();
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
      await ref
          .read(authProvider.notifier)
          .definirSenhaDefinitivaAluno(
            _senhaAtualCtrl.text,
            _novaSenhaCtrl.text,
          );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.passwordDefined,
          props: {'role': 'aluno'},
        ),
      );
      context.go('/aluno/ativacao');
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() => _error = mapDefinirSenhaError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
