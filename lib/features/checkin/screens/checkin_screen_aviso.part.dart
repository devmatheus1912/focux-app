part of 'checkin_screen.dart';

/// Fim do descanso com a tela bloqueada (SPEC-notificacoes, 20/11): o relógio
/// diz quando o fim muda; aqui vira aviso agendado ou cancelado.
extension CheckinScreenAviso on _CheckinScreenState {
  void _agendarAvisoDescanso(DateTime? fim) {
    final aviso = _avisoDescanso;
    if (fim == null) {
      unawaited(aviso.cancelar());
      return;
    }
    final aluno = widget.presencialAlunoId;
    final rota =
        aluno == null
            ? checkinExecutarPath(widget.treinoId)
            : '/alunos/$aluno/treinar?treinoId=${widget.treinoId}';
    unawaited(
      aviso.agendar(
        fim: fim,
        corpo: _proximaSerieLinha() ?? 'Volte para a próxima série.',
        rota: rota,
      ),
    );
  }

  bool _appEmPrimeiroPlano() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  /// Notificações negadas: no primeiro descanso, uma linha discreta pede para
  /// ativar. Uma vez por instalação.
  Future<void> _conferirDicaDePermissao() async {
    if (_dicaPermissaoConferida) return;
    _dicaPermissaoConferida = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(PreferenciasDoDescanso.chaveDicaPermissao) ?? false) {
        return;
      }
      if (!await FcmService.permissaoNegada()) return;
      await prefs.setBool(PreferenciasDoDescanso.chaveDicaPermissao, true);
      if (mounted) setState(() => _dicaPermissao = true);
    } catch (_) {}
  }
}
