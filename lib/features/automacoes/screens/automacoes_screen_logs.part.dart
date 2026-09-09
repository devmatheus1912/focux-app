part of 'automacoes_screen.dart';

extension on _AutomacoesScreenState {
  Future<void> _iniciarParaAluno(AutomacaoFluxo fluxo) async {
    try {
      final home = await ref.read(alunosHomeProvider.future);
      if (!mounted) return;
      final alunos = filterAlunoPickerAlunos(home.alunos, '');
      if (alunos.isEmpty) {
        FeedbackHelper.showError(context, automacaoSemAlunos());
        return;
      }
      final alunoId = await showFxInsetPickerSheet<int>(
        context,
        title: automacaoIniciarPickerTitle(),
        items: [
          for (final a in alunos)
            FxInsetPickerSheetItem(
              value: a.id,
              label: a.nome,
              subtitle: a.email.trim().isEmpty ? null : a.email,
            ),
        ],
      );
      if (alunoId == null || !mounted) return;
      Aluno? picked;
      for (final a in alunos) {
        if (a.id == alunoId) {
          picked = a;
          break;
        }
      }
      final aluno = picked;
      if (aluno == null) return;
      final ok = await showFxConfirmSheet(
        context,
        title: automacaoIniciarConfirmTitle(aluno.nome),
        message: automacaoIniciarConfirmMessage(),
        icon: Icons.play_arrow_rounded,
        confirmLabel: 'Iniciar',
      );
      if (!ok || !mounted) return;
      await ref.read(_repo).iniciarFluxo(fluxoId: fluxo.id, alunoId: aluno.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      FeedbackHelper.showSuccess(context, automacaoIniciarSuccess());
      await _openLogs(fluxo);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}

Future<void> _showAutomacaoLogsSheet({
  required BuildContext context,
  required AutomacaoFluxo fluxo,
  required Pagina<AutomacaoLog> initial,
  required Future<Pagina<AutomacaoLog>> Function(int page) onLoadMore,
  required Future<void> Function() onIniciar,
}) {
  return showFxHomeSheet<void>(
    context,
    builder: (sheetContext) => _AutomacaoLogsSheet(
      fluxo: fluxo,
      initial: initial,
      onLoadMore: onLoadMore,
      onIniciar: onIniciar,
    ),
  );
}

class _AutomacaoLogsSheet extends StatefulWidget {
  const _AutomacaoLogsSheet({
    required this.fluxo,
    required this.initial,
    required this.onLoadMore,
    required this.onIniciar,
  });

  final AutomacaoFluxo fluxo;
  final Pagina<AutomacaoLog> initial;
  final Future<Pagina<AutomacaoLog>> Function(int page) onLoadMore;
  final Future<void> Function() onIniciar;

  @override
  State<_AutomacaoLogsSheet> createState() => _AutomacaoLogsSheetState();
}

class _AutomacaoLogsSheetState extends State<_AutomacaoLogsSheet> {
  late List<AutomacaoLog> _logs = List.of(widget.initial.content);
  late var _hasNext = widget.initial.hasNext;
  late var _page = widget.initial.page ?? 0;
  var _loadingMore = false;

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.onLoadMore(_page + 1);
      if (!mounted) return;
      setState(() {
        _logs = [..._logs, ...next.content];
        _hasNext = next.hasNext;
        _page = next.page ?? _page + 1;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final logs = _logs;
    return FxHomeSheetSurface(
      isDark: chrome.isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: chrome.isDark),
          FxHomeSheetHeader(
            isDark: chrome.isDark,
            leading: Icon(
              Icons.timeline_outlined,
              color: primary,
              size: 18,
            ),
            title: widget.fluxo.nome,
            subtitle: automacaoTriggerLabel(widget.fluxo.triggerTipo),
          ),
          SizedBox(
            height: 280,
            child: logs.isEmpty
                ? const FxEmptyState(
                    icon: 'zap',
                    title: 'Nenhuma execução ainda',
                    subtitle:
                        'Quando o gatilho disparar, o histórico aparece aqui.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      0,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    itemCount: logs.length + (_hasNext ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= logs.length) {
                        return FxSatelliteListTile(
                          title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                          onTap: _loadingMore ? null : _carregarMais,
                        );
                      }
                      final log = logs[i];
                      return FxSatelliteListTile(
                        title: automacaoLogStatusLabel(log.status),
                        subtitle: Text(
                          automacaoLogSubtitle(
                            status: log.status,
                            passoAtual: log.passoAtual,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              0,
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
            ),
            child: FxLiquidPrimaryButton(
              label: automacaoIniciarLabel(),
              onPressed: widget.onIniciar,
            ),
          ),
        ],
      ),
    );
  }
}
