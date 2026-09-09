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
                      Aluno? match;
                      for (final a in alunos) {
                        if (a.id == picked) {
                          match = a;
                          break;
                        }
                      }
                      final aluno = match;
                      if (aluno == null) return;
                      setDialogState(() {
                        alunoId = aluno.id;
                        alunoNome = aluno.nome;
                      });
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

      final r = await RecorrenciaRepository(ref.read(apiClientProvider)).criar(
        alunoId: alunoId,
        valor: FxMoney.fromInput(
          valorCtrl.text.trim().isEmpty ? '199' : valorCtrl.text,
        ),
      );
      final link = r.initPoint?.trim();
      if (link != null && link.isNotEmpty) {
        await copySensitiveToClipboard(link);
        if (!mounted) return;
        FeedbackHelper.showSuccess(
          context,
          'Link de assinatura copiado — envie ao aluno.',
        );
      }
      created = true;
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      valorCtrl.dispose();
    }
    if (created) await _load(reset: true);
  }
}
