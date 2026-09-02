part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabForms on _FinanceiroMensalidadesTabState {
  Future<String?> _pickMesReferencia(
    BuildContext ctx, {
    required String atual,
  }) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(atual) ?? DateTime(now.year, now.month, 1);
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'Selecione o mês de referência',
      fieldLabelText: 'Mês/Ano',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (day) => day.day == 1,
    );
    if (picked == null) return null;
    final mes = picked.month.toString().padLeft(2, '0');
    return '${picked.year}-$mes-01';
  }

  Future<void> _editarMensalidade(Mensalidade m) async {
    const statuses = ['PENDENTE', 'PAGO', 'ATRASADO'];
    final valorCtrl = TextEditingController(text: m.valor.toStringAsFixed(2));
    var mesReferencia = m.mesReferencia.length >= 7
        ? m.mesReferencia
        : m.mesReferencia;
    var selectedStatus = m.status;
    var salvando = false;
    final formKey = GlobalKey<FormState>();

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
                          title: 'Editar mensalidade',
                          subtitle: 'Atualize valor, mês e status.',
                          leading: Icon(
                            Icons.edit_outlined,
                            color: primary,
                            size: 18,
                          ),
                        ),
                        SizedBox(height: TokensStrip.s3),
                        FxSettingsGroup(
                          children: [
                            AlunoInsetFormField(
                              controller: valorCtrl,
                              label: 'Valor (R\$)',
                              hint: '0,00',
                              icon: Icons.attach_money,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                            FxSettingsTile(
                              fxIcon: 'calendar',
                              label: 'Mês de referência',
                              value: financeiroMesPickerValue(mesReferencia),
                              onTap: () async {
                                final picked = await _pickMesReferencia(
                                  ctx,
                                  atual: mesReferencia,
                                );
                                if (picked != null) {
                                  setModalState(() => mesReferencia = picked);
                                }
                              },
                            ),
                            FxSettingsTile(
                              fxIcon: selectedStatus == 'ATRASADO'
                                  ? 'alert-triangle'
                                  : selectedStatus == 'PAGO'
                                      ? 'circle-check'
                                      : 'coin',
                              label: 'Status',
                              value: financeiroMensalidadeStatusLabel(
                                selectedStatus,
                              ),
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
                                        label:
                                            financeiroMensalidadeStatusLabel(s),
                                      ),
                                  ],
                                );
                                if (picked != null) {
                                  setModalState(() => selectedStatus = picked);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxSettingsGroup(
                          children: [
                            FxSettingsTile(
                              fxIcon: 'circle-check',
                              label: financeiroSalvarMensalidadeTileLabel(),
                              value: salvando ? 'Salvando…' : 'Confirmar',
                              showDivider: false,
                              onTap: salvando
                                  ? () {}
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      if (mesReferencia.trim().isEmpty) {
                                        FeedbackHelper.showError(
                                          ctx,
                                          'Selecione o mês de referência',
                                        );
                                        return;
                                      }
                                      HapticFeedback.mediumImpact();
                                      final ok = await showFxConfirmSheet(
                                        ctx,
                                        title:
                                            financeiroSalvarMensalidadeConfirmTitle(),
                                        message:
                                            financeiroSalvarMensalidadeConfirmMessage(),
                                        icon: Icons.payments_outlined,
                                        confirmLabel:
                                            financeiroSalvarMensalidadeTileLabel(),
                                      );
                                      if (!ok) return;
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
                                          mesReferencia: mesReferencia.trim(),
                                          status: selectedStatus,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        _load(force: true);
                                        if (mounted) {
                                          HapticFeedback.heavyImpact();
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
                      ],
                    ),
                  ),
            ),
          );
        },
      );
    } finally {
      valorCtrl.dispose();
    }
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
    try {
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
    } finally {
      obsCtrl.dispose();
    }
  }

  Future<void> _abrirFormularioNovaMensalidade() async {
    final formKey = GlobalKey<FormState>();
    final valorCtrl = TextEditingController();
    var mesReferencia = '';
    int? alunoSelecionadoId;
    String? alunoSelecionadoNome;
    var salvando = false;

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
                          title: 'Nova mensalidade',
                          subtitle: 'Lance valor e mês de referência.',
                          leading: Icon(
                            Icons.add_card_outlined,
                            color: primary,
                            size: 18,
                          ),
                        ),
                        SizedBox(height: TokensStrip.s3),
                        FxSettingsGroup(
                          children: [
                            ref.watch(alunosProvider).when(
                              loading: () => const SizedBox(
                                height: 48,
                                child: FxLoading(),
                              ),
                              error:
                                  (e, _) => Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Não foi possível carregar alunos.',
                                      style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error,
                                      ),
                                    ),
                                  ),
                              data:
                                  (alunos) => FxSettingsTile(
                                    fxIcon: 'users',
                                    label: 'Aluno',
                                    value: financeiroAlunoPickerValue(
                                      alunoSelecionadoNome,
                                    ),
                                    onTap: alunos.isEmpty
                                        ? () {}
                                        : () async {
                                            final picked =
                                                await showFxInsetPickerSheet<
                                                  int
                                                >(
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
                            AlunoInsetFormField(
                              controller: valorCtrl,
                              label: 'Valor (R\$)',
                              hint: '0,00',
                              icon: Icons.attach_money,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                            FxSettingsTile(
                              fxIcon: 'calendar',
                              label: 'Mês de referência',
                              value: financeiroMesPickerValue(mesReferencia),
                              showDivider: false,
                              onTap: () async {
                                final picked = await _pickMesReferencia(
                                  ctx,
                                  atual: mesReferencia,
                                );
                                if (picked != null) {
                                  setModalState(() => mesReferencia = picked);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxSettingsGroup(
                          children: [
                            FxSettingsTile(
                              fxIcon: 'circle-check',
                              label: financeiroLancarMensalidadeTileLabel(),
                              value: salvando ? 'Lançando…' : 'Confirmar',
                              showDivider: false,
                              onTap: salvando
                                  ? () {}
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
                                      if (!RegExp(
                                        r'^\d{4}-\d{2}-01$',
                                      ).hasMatch(mesReferencia.trim())) {
                                        FeedbackHelper.showError(
                                          ctx,
                                          'Selecione o mês de referência',
                                        );
                                        return;
                                      }
                                      HapticFeedback.mediumImpact();
                                      final ok = await showFxConfirmSheet(
                                        ctx,
                                        title:
                                            financeiroLancarMensalidadeConfirmTitle(),
                                        message:
                                            financeiroLancarMensalidadeConfirmMessage(),
                                        icon: Icons.payments_outlined,
                                        confirmLabel:
                                            financeiroLancarMensalidadeTileLabel(),
                                      );
                                      if (!ok) return;
                                      setModalState(() => salvando = true);
                                      try {
                                        final alunoId = alunoSelecionadoId!;
                                        final valor = double.parse(
                                          valorCtrl.text.trim().replaceAll(
                                            ',',
                                            '.',
                                          ),
                                        );
                                        await FinanceiroRepository(
                                          ref.read(apiClientProvider),
                                        ).criar(
                                          alunoId,
                                          valor,
                                          mesReferencia.trim(),
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
                      ],
                    ),
                  ),
            ),
          );
        },
      );
    } finally {
      valorCtrl.dispose();
    }
  }
}
