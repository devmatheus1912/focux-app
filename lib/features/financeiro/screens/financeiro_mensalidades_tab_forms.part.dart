part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabForms on _FinanceiroMensalidadesTabState {
  /// [mesPedido]: "Lançar" num mês sem cobrança abre já com o vencimento nele.
  Future<void> _abrirFormularioNovaMensalidade({DateTime? mesPedido}) async {
    final formKey = GlobalKey<FormState>();
    final valorCtrl = TextEditingController();
    final hoje = DateTime.now();
    DateTime? vencimento;
    var ocupados = const <String, MesOcupado>{};
    final s = S.of(context);

    // Ao escolher o aluno: meses que ele já tem (bloqueados na folha), valor e
    // dia da última cobrança como sugestão. Nunca sobrescreve o digitado.
    Future<void> prepararAluno(int alunoId, void Function(void Function()) set) async {
      List<Mensalidade> doAluno = const [];
      try {
        final page = await FinanceiroRepository(
          ref.read(apiClientProvider),
        ).listarPagina(alunoId: alunoId, size: 50);
        doAluno = page.mensalidades;
      } catch (_) {}
      final occ = vencimentoMesesOcupados(doAluno);
      set(() {
        ocupados = occ;
        final dia = vencimentoDiaPreferido(doAluno);
        final pedido = mesPedido;
        vencimento =
            pedido != null &&
                    !(occ[vencimentoChaveMes(pedido)]?.bloqueia ?? false)
                ? vencimentoNoDia(pedido, dia)
                : vencimentoSugerido(hoje: hoje, ocupados: occ, dia: dia);
        if (valorCtrl.text.trim().isEmpty && doAluno.isNotEmpty) {
          valorCtrl.text = fxMoneyCampoTexto(doAluno.first.valor);
        }
      });
    }

    // Prefetch before sheet so the aluno picker never infinite-spins.
    List<Aluno> alunos = const [];
    try {
      alunos = await ref.read(alunosProvider.future);
    } catch (_) {
      alunos = ref.read(alunosProvider).value ?? const [];
    }

    int? alunoSelecionadoId = widget.initialAlunoId;
    String? alunoSelecionadoNome;
    if (alunoSelecionadoId != null) {
      for (final a in alunos) {
        if (a.id == alunoSelecionadoId) {
          alunoSelecionadoNome = fxTitleCaseName(a.nome);
          break;
        }
      }
      if (alunoSelecionadoNome == null) {
        try {
          final a = await ref.read(alunoProvider(alunoSelecionadoId).future);
          alunoSelecionadoNome = fxTitleCaseName(a.nome);
        } catch (_) {}
      }
    }
    var salvando = false;
    var escolhendoAluno = false;
    var preparado = alunoSelecionadoId == null;

    if (!mounted) {
      valorCtrl.dispose();
      return;
    }

    try {
      await showFxHomeSheet(
        context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primary = Theme.of(ctx).colorScheme.primary;
          return FxHomeSheetSurface(
            isDark: isDark,
            maxHeight:
                MediaQuery.sizeOf(ctx).height *
                FxHomeSheetChrome.maxHeightFactor,
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                if (!preparado) {
                  preparado = true;
                  prepararAluno(alunoSelecionadoId!, setModalState);
                }
                if (escolhendoAluno) {
                  return FinanceiroAlunoEtapa(
                    alunos: alunos,
                    selecionadoId: alunoSelecionadoId,
                    onVoltar:
                        () => setModalState(() => escolhendoAluno = false),
                    onPick: (a) {
                      setModalState(() {
                        alunoSelecionadoId = a.id;
                        alunoSelecionadoNome = fxTitleCaseName(a.nome);
                        escolhendoAluno = false;
                        vencimento = null;
                      });
                      prepararAluno(a.id, setModalState);
                    },
                  );
                }
                final venc = vencimento;
                return Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FxHomeSheetHandle(isDark: isDark),
                        SizedBox(height: TokensStrip.s4),
                        FxHomeSheetHeader(
                          isDark: isDark,
                          title: 'Nova mensalidade',
                          subtitle: 'Aluno, valor e vencimento.',
                          leading: Icon(
                            FxIcons.adicionarCartao,
                            color: primary,
                            size: 18,
                          ),
                        ),
                        SizedBox(height: TokensStrip.s3),
                        FxSettingsGroup(
                          children: [
                            FxSettingsTile(
                              icon: FxIcons.grupo,
                              label: 'Aluno',
                              value: financeiroAlunoPickerValue(
                                alunoSelecionadoNome,
                              ),
                              picker: true,
                              onTap:
                                  alunos.isEmpty
                                      ? null
                                      : () => setModalState(
                                        () => escolhendoAluno = true,
                                      ),
                            ),
                            AlunoInsetFormField(
                              controller: valorCtrl,
                              label: s.financeiroValorRotulo,
                              hint: 'R\$ 0,00',
                              icon: FxIcons.dinheiro,
                              rotuloVisivel: true,
                              // "Lançar" já fica desativado sem valor.
                              keyboardType: TextInputType.number,
                              inputFormatters: const [FxMoneyInputFormatter()],
                              validator: fxMoneyValidar,
                            ),
                            // Mês e dia numa escolha só; sem aluno não há
                            // como saber quais meses ele já tem.
                            FxSettingsTile(
                              icon: FxIcons.calendario,
                              label: s.financeiroVencimentoRotulo,
                              value:
                                  alunoSelecionadoId == null
                                      ? 'Escolha o aluno primeiro'
                                      : venc == null
                                      ? 'Escolher'
                                      : mensalidadeVencimentoRotulo(venc),
                              picker: true,
                              showDivider: false,
                              onTap:
                                  alunoSelecionadoId == null
                                      ? null
                                      : () async {
                                        final picked =
                                            await pickMensalidadeVencimento(
                                              ctx,
                                              atual: venc ?? hoje,
                                              ocupados: ocupados,
                                            );
                                        if (picked != null) {
                                          setModalState(
                                            () => vencimento = picked,
                                          );
                                        }
                                      },
                            ),
                          ],
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxLiquidPrimaryButton(
                          label: financeiroLancarMensalidadeTileLabel(),
                          loading: salvando,
                          loadingLabel: 'Lançando…',
                          onPressed:
                              salvando
                                  ? null
                                  : () async {
                                    if (alunoSelecionadoId == null) {
                                      FeedbackHelper.showError(
                                        ctx,
                                        'Selecione um aluno',
                                      );
                                      return;
                                    }
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final v = vencimento;
                                    if (v == null) {
                                      FeedbackHelper.showError(
                                        ctx,
                                        'Escolha o vencimento',
                                      );
                                      return;
                                    }
                                    final valor = fxMoneyDoCampo(valorCtrl.text)!;
                                    HapticFeedback.mediumImpact();
                                    final ok = await showFxConfirmSheet(
                                      ctx,
                                      title:
                                          financeiroLancarMensalidadeConfirmTitle(),
                                      message: mensalidadeConfirmacaoTexto(
                                        aluno: alunoSelecionadoNome ?? 'Aluno',
                                        valor: valor,
                                        vencimento: v,
                                      ),
                                      icon: FxIcons.pagamento,
                                      confirmLabel:
                                          financeiroLancarMensalidadeTileLabel(),
                                    );
                                    if (!ok) return;
                                    setModalState(() => salvando = true);
                                    try {
                                      await FinanceiroRepository(
                                        ref.read(apiClientProvider),
                                      ).criar(
                                        alunoSelecionadoId!,
                                        valor,
                                        vencimentoIso(DateTime(v.year, v.month, 1)),
                                        vencimento: vencimentoIso(v),
                                      );
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }
                                      _load(force: true);
                                      if (mounted) {
                                        HapticFeedback.heavyImpact();
                                        FeedbackHelper.showSuccess(
                                          context,
                                          'Mensalidade lançada!',
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => salvando = false);
                                      if (ctx.mounted) {
                                        FeedbackHelper.showError(
                                          ctx,
                                          friendlyError(e),
                                        );
                                      }
                                    }
                                  },
                        ),
                      ],
                    ),
                  );
              },
            ),
          );
        },
      );
    } finally {
      valorCtrl.dispose();
    }
  }
}
