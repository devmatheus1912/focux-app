part of 'recorrencia_screen.dart';

extension on _RecorrenciaScreenState {
  Future<void> _criar() async {
    HapticFeedback.selectionClick();
    List<Aluno> alunos;
    try {
      final home = await ref.read(alunosHomeProvider.future);
      alunos = filterAlunoPickerAlunos(home.alunos, '');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
      return;
    }
    if (alunos.isEmpty) {
      if (!mounted) return;
      FeedbackHelper.showWarn(context, 'Cadastre um aluno primeiro.');
      return;
    }
    var alunoId = alunos.first.id;
    var alunoNome = alunos.first.nome;
    var dia = recorrenciaDiaPadrao(DateTime.now());
    final valorCtrl = TextEditingController(text: '199');
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova recorrência',
        icon: Icons.repeat_rounded,
        confirmLabel: 'Criar',
        child: StatefulBuilder(
          builder:
              (ctx, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FxInsetPickerRow(
                    icon: Icons.person_outline,
                    label: 'Aluno',
                    value: recorrenciaAlunoLabel(alunoNome),
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<int>(
                        ctx,
                        title: 'Aluno',
                        selected: alunoId,
                        items: [
                          for (final a in alunos)
                            FxInsetPickerSheetItem(
                              value: a.id,
                              label: recorrenciaAlunoLabel(a.nome),
                            ),
                        ],
                      );
                      if (picked == null) return;
                      final aluno =
                          alunos.where((a) => a.id == picked).firstOrNull;
                      if (aluno == null) return;
                      setDialogState(() {
                        alunoId = aluno.id;
                        alunoNome = aluno.nome;
                      });
                    },
                  ),
                  FxInsetPickerRow(
                    icon: Icons.event_outlined,
                    label: 'Vencimento',
                    value: recorrenciaDiaLabel(dia),
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<int>(
                        ctx,
                        title: 'Dia do vencimento',
                        selected: dia,
                        items: [
                          for (var d = 1; d <= recorrenciaDiaMaximo; d++)
                            FxInsetPickerSheetItem(
                              value: d,
                              label: recorrenciaDiaLabel(d),
                            ),
                        ],
                      );
                      if (picked == null) return;
                      setDialogState(() => dia = picked);
                    },
                  ),
                  AlunoInsetFormField(
                    controller: valorCtrl,
                    label: 'Valor mensal (R\$)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    showDivider: false,
                  ),
                ],
              ),
        ),
      );
      if (ok != true) return;

      await RecorrenciaRepository(ref.read(apiClientProvider)).criar(
        alunoId: alunoId,
        valor: FxMoney.fromInput(
          valorCtrl.text.trim().isEmpty ? '199' : valorCtrl.text,
        ),
        diaVencimento: dia,
      );
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, recorrenciaCriadaMensagem);
      created = true;
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
      if (ApiError.from(e)?.codigo == pixChaveAusenteCodigo) {
        context.push('/perfil/wallet');
      }
    } finally {
      valorCtrl.dispose();
    }
    if (created) await _load(reset: true);
  }

  Future<void> _abrirAcoes(RecorrenciaAssinatura item) async {
    final acoes = recorrenciaAcoesDisponiveis(item.status);
    if (acoes.isEmpty) return;
    final acao = await showFxInsetPickerSheet<RecorrenciaAcao>(
      context,
      title: recorrenciaAlunoLabel(item.alunoNome),
      items: [
        for (final a in acoes)
          FxInsetPickerSheetItem(value: a, label: recorrenciaAcaoLabel(a)),
      ],
    );
    if (acao == null || !mounted) return;
    if (acao == RecorrenciaAcao.cancelar) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Encerrar recorrência?',
        subtitle: recorrenciaAlunoLabel(item.alunoNome),
        message: 'Novas mensalidades param de ser lançadas. As já lançadas continuam.',
        confirmLabel: 'Encerrar',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    try {
      await RecorrenciaRepository(
        ref.read(apiClientProvider),
      ).acaoPersonal(item.id, recorrenciaAcaoPath(acao));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, recorrenciaAcaoFeito(acao));
      await _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}
