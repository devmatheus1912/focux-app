part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabForms on _FinanceiroMensalidadesTabState {
  Future<void> _editarMensalidade(Mensalidade m) async {
    const statuses = ['PENDENTE', 'PAGO', 'ATRASADO'];
    final valorCtrl = TextEditingController(text: m.valor.toStringAsFixed(2));
    final mesReferenciaCtrl = TextEditingController(
      text: m.mesReferencia.length >= 7 ? m.mesReferencia : m.mesReferencia,
    );
    String selectedStatus = m.status;
    bool salvando = false;
    final formKey = GlobalKey<FormState>();

    await showFxHomeSheet(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor,
          child: StatefulBuilder(
            builder:
                (ctx, setModalState) => Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FxHomeSheetHandle(isDark: isDark),
                      SizedBox(height: TokensStrip.s4),
                      FxHomeSheetHeader(
                        isDark: isDark,
                        title: 'Editar Mensalidade',
                        subtitle: 'Atualize valor, mês e status.',
                        leading: Icon(
                          Icons.edit_outlined,
                          color: primary,
                          size: 18,
                        ),
                      ),
                      SizedBox(height: TokensStrip.s3),
                      TextFormField(
                        controller: valorCtrl,
                        decoration: _fxDeco(
                          'Valor (R\$)',
                          icon: Icons.attach_money,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o valor';
                          }
                          final parsed = double.tryParse(
                            v.trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mesReferenciaCtrl,
                        decoration: _fxDeco(
                          'Mês Referência',
                          icon: Icons.calendar_month,
                          hint: '2026-04-01',
                        ),
                        readOnly: true,
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate:
                                DateTime.tryParse(mesReferenciaCtrl.text) ??
                                DateTime(now.year, now.month, 1),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(now.year + 5),
                            selectableDayPredicate: (day) => day.day == 1,
                          );
                          if (picked != null) {
                            final mes = picked.month.toString().padLeft(2, '0');
                            mesReferenciaCtrl.text = '${picked.year}-$mes-01';
                          }
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Selecione o mês de referência';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      FxSettingsTile(
                        fxIcon: selectedStatus == 'ATRASADO'
                            ? 'alert-triangle'
                            : selectedStatus == 'PAGO'
                                ? 'circle-check'
                                : 'coin',
                        label: 'Status',
                        value: financeiroMensalidadeStatusLabel(selectedStatus),
                        showDivider: false,
                        onTap: () async {
                          final picked =
                              await showFxInsetPickerSheet<String>(
                            ctx,
                            title: 'Status',
                            selected: selectedStatus,
                            items: [
                              for (final s in statuses)
                                FxInsetPickerSheetItem(
                                  value: s,
                                  label: financeiroMensalidadeStatusLabel(s),
                                ),
                            ],
                          );
                          if (picked != null) {
                            setModalState(() => selectedStatus = picked);
                          }
                        },
                      ),
                      const SizedBox(height: TokensStrip.s5),
                      FxLiquidPrimaryButton(
                        label: salvando ? 'Salvando...' : 'Salvar',
                        icon: Icons.save,
                        loading: salvando,
                        onPressed:
                            salvando
                                ? null
                                : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setModalState(() => salvando = true);
                                  try {
                                    final valor = double.parse(
                                      valorCtrl.text.trim().replaceAll(
                                        ',',
                                        '.',
                                      ),
                                    );
                                    await FinanceiroRepository(
                                      ref.read(apiClientProvider),
                                    ).editarMensalidade(
                                      m.id,
                                      valor: valor,
                                      mesReferencia:
                                          mesReferenciaCtrl.text.trim(),
                                      status: selectedStatus,
                                    );
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                    _load(force: true);
                                    if (mounted) {
                                      FeedbackHelper.showSuccess(
                                        context,
                                        'Mensalidade atualizada!',
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
                ),
          ),
        );
      },
    );
  }

  Future<void> _registrarContato(Mensalidade m) async {
    const tipos = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
    final tipo = await showFxInsetPickerSheet<String>(
      context,
      title: 'Tipo de contato',
      items: [
        for (final t in tipos)
          FxInsetPickerSheetItem(
            value: t,
            label: financeiroContatoTipoLabel(t),
          ),
      ],
    );
    if (!mounted || tipo == null) return;
    final obsCtrl = TextEditingController();
    final confirm = await showFxFormSheet(
      context,
      title: 'Registrar contato',
      subtitle: financeiroContatoTipoLabel(tipo),
      confirmLabel: 'Registrar',
      child: TextField(
        controller: obsCtrl,
        decoration: InputDecoration(
          labelText: 'Observação (opcional)',
          border: FxInputDeco.outlineBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        maxLines: 2,
      ),
    );
    if (confirm != true) return;
    try {
      await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).registrarContato(m.id, tipo, obsCtrl.text.trim());
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Contato registrado!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _abrirFormularioNovaMensalidade() {
    final formKey = GlobalKey<FormState>();
    final valorCtrl = TextEditingController();
    final mesReferenciaCtrl = TextEditingController();
    int? alunoSelecionadoId;
    String? alunoSelecionadoNome;
    bool salvando = false;

    showFxHomeSheet(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor,
          child: StatefulBuilder(
            builder:
                (ctx, setModalState) => Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FxHomeSheetHandle(isDark: isDark),
                      SizedBox(height: TokensStrip.s4),
                      FxHomeSheetHeader(
                        isDark: isDark,
                        title: 'Nova Mensalidade',
                        subtitle: 'Lance valor e mês de referência.',
                        leading: Icon(
                          Icons.add_card_outlined,
                          color: primary,
                          size: 18,
                        ),
                      ),
                      SizedBox(height: TokensStrip.s3),
                      ref
                          .watch(alunosProvider)
                          .when(
                            loading: () => const SizedBox(
                              height: 48,
                              child: FxLoading(),
                            ),
                            error:
                                (e, _) => Text(
                                  'Não foi possível carregar alunos.',
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                ),
                            data:
                                (alunos) => FxSettingsTile(
                                  fxIcon: 'users',
                                  label: alunoSelecionadoNome ?? 'Selecionar aluno',
                                  value: '',
                                  showDivider: false,
                                  onTap: alunos.isEmpty
                                      ? () {}
                                      : () async {
                                          final picked =
                                              await showFxInsetPickerSheet<int>(
                                            ctx,
                                            title: 'Aluno',
                                            selected: alunoSelecionadoId,
                                            items: [
                                              for (final a in alunos)
                                                FxInsetPickerSheetItem(
                                                  value: a.id,
                                                  label: a.nome,
                                                ),
                                            ],
                                          );
                                          if (picked == null) return;
                                          String? nome;
                                          for (final a in alunos) {
                                            if (a.id == picked) {
                                              nome = a.nome;
                                              break;
                                            }
                                          }
                                          setModalState(() {
                                            alunoSelecionadoId = picked;
                                            alunoSelecionadoNome = nome;
                                          });
                                        },
                                ),
                          ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: valorCtrl,
                        decoration: _fxDeco(
                          'Valor (R\$)',
                          icon: Icons.attach_money,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o valor';
                          }
                          final parsed = double.tryParse(
                            v.trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Valor invalido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mesReferenciaCtrl,
                        decoration: _fxDeco(
                          'Mês Referência',
                          icon: Icons.calendar_month,
                          hint: '2026-04-01',
                        ),
                        readOnly: true,
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime(now.year, now.month, 1),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(now.year + 5),
                            helpText: 'Selecione o mes de referencia',
                            fieldLabelText: 'Mes/Ano',
                            initialEntryMode: DatePickerEntryMode.calendarOnly,
                            selectableDayPredicate: (day) => day.day == 1,
                          );
                          if (picked != null) {
                            final mes = picked.month.toString().padLeft(2, '0');
                            mesReferenciaCtrl.text = '${picked.year}-$mes-01';
                          }
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Selecione o mes de referencia';
                          }
                          if (!RegExp(r'^\d{4}-\d{2}-01$').hasMatch(v.trim())) {
                            return 'Formato invalido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: TokensStrip.s5),
                      FxLiquidPrimaryButton(
                        label: salvando ? 'Salvando...' : 'Lancar Mensalidade',
                        icon: Icons.check,
                        loading: salvando,
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
                                  setModalState(() => salvando = true);
                                  try {
                                    final alunoId = alunoSelecionadoId!;
                                    final valor = double.parse(
                                      valorCtrl.text.trim().replaceAll(
                                        ',',
                                        '.',
                                      ),
                                    );
                                    final mesReferencia =
                                        mesReferenciaCtrl.text.trim();
                                    await FinanceiroRepository(
                                      ref.read(apiClientProvider),
                                    ).criar(alunoId, valor, mesReferencia);
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                    _load(force: true);
                                    if (mounted) {
                                      FeedbackHelper.showSuccess(
                                        context,
                                        'Mensalidade lançada com sucesso!',
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
                ),
          ),
        );
      },
    );
  }
}
