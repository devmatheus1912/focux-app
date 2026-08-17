part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabActions on _FinanceiroMensalidadesTabState {
  InputDecoration _fxDeco(String label, {IconData? icon, String? hint}) {
    final chrome = ShellChrome.of(context);
    final line = chrome.line;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: mute,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: mute.withValues(alpha: 0.5), fontSize: 13.5),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: mute) : null,
      filled: true,
      fillColor: chrome.cardFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad),
      ),
      focusedErrorBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad, width: 1.6),
      ),
    );
  }

  Future<void> _editarMensalidade(Mensalidade m) async {
    const statuses = ['PENDENTE', 'PAGO', 'ATRASADO'];
    final valorCtrl = TextEditingController(text: m.valor.toStringAsFixed(2));
    final mesReferenciaCtrl = TextEditingController(
      text: m.mesReferencia.length >= 7 ? m.mesReferencia : m.mesReferencia,
    );
    String selectedStatus = m.status;
    bool salvando = false;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ShellSurface(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: StatefulBuilder(
                builder:
                    (ctx, setModalState) => Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Editar Mensalidade',
                                  style: AppTypography.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: TokensStrip.s4),
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
                                final mes = picked.month.toString().padLeft(
                                  2,
                                  '0',
                                );
                                mesReferenciaCtrl.text =
                                    '${picked.year}-$mes-01';
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
                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            decoration: _fxDeco('Status', icon: Icons.flag),
                            items:
                                statuses
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setModalState(
                                  () => selectedStatus = v ?? selectedStatus,
                                ),
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
            ),
          ),
    );
  }

  Future<void> _atualizarAtrasos() async {
    try {
      await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).atualizarAtrasos();
      _load(force: true);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Mensalidades atualizadas!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _registrarContato(Mensalidade m) async {
    const tipos = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
    String? tipoSelecionado = tipos.first;
    final obsCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, set) => AlertDialog(
                  title: const Text('Registrar Contato'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: tipoSelecionado,
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items:
                            tipos
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => set(() => tipoSelecionado = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: obsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Observação (opcional)',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FxLiquidPrimaryButton(
                      label: 'Registrar',
                      expand: false,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
          ),
    );
    if (confirm != true || tipoSelecionado == null) return;
    try {
      await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).registrarContato(m.id, tipoSelecionado!, obsCtrl.text.trim());
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Contato registrado!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _cobrarViaChat(Mensalidade m) async {
    AnalyticsService.instance.track(
      ProductEvents.financeiroCobrarViaChat,
      props: {
        'feature': 'financeiro',
        'mensalidade_id': m.id,
        'aluno_id': m.alunoId,
      },
    );
    try {
      final msg = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).cobrarViaChat(m.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, msg);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _pagar(int id) async {
    try {
      await FinanceiroRepository(ref.read(apiClientProvider)).pagar(id);
      _load(force: true);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _mostrarPix(int id) async {
    PixData? pix;
    bool carregando = true;
    String? erro;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              if (carregando && pix == null && erro == null) {
                FinanceiroRepository(ref.read(apiClientProvider))
                    .gerarPix(id)
                    .then((p) {
                      setDialogState(() {
                        pix = p;
                        carregando = false;
                      });
                    })
                    .catchError((e) {
                      setDialogState(() {
                        erro = friendlyError(e);
                        carregando = false;
                      });
                    });
              }

              return AlertDialog(
                title: const Text('PIX - Escaneie ou copie'),
                content:
                    carregando
                        ? const SizedBox(height: 80, child: FxLoading())
                        : erro != null
                        ? Text(erro!)
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.memory(
                              base64Decode(pix!.qrCodeBase64),
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            TextButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('Copiar codigo PIX'),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: pix!.pixCopiaECola),
                                );
                                FeedbackHelper.showSuccess(
                                  context,
                                  'Código PIX copiado!',
                                );
                              },
                            ),
                          ],
                        ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _abrirFormularioNovaMensalidade() {
    final formKey = GlobalKey<FormState>();
    final valorCtrl = TextEditingController();
    final mesReferenciaCtrl = TextEditingController();
    int? alunoSelecionadoId;
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ShellSurface(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: StatefulBuilder(
                builder:
                    (ctx, setModalState) => Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Nova Mensalidade',
                                  style: AppTypography.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          ref
                              .watch(alunosProvider)
                              .when(
                                loading: () => const LinearProgressIndicator(),
                                error:
                                    (e, _) => Text(
                                      'Nao foi possivel carregar alunos.',
                                      style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error,
                                      ),
                                    ),
                                data:
                                    (alunos) => DropdownButtonFormField<int>(
                                      initialValue: alunoSelecionadoId,
                                      decoration: _fxDeco(
                                        'Aluno',
                                        icon: Icons.person,
                                      ),
                                      items:
                                          alunos
                                              .map(
                                                (a) => DropdownMenuItem<int>(
                                                  value: a.id,
                                                  child: Text(a.nome),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (value) => setModalState(
                                            () => alunoSelecionadoId = value,
                                          ),
                                      validator:
                                          (value) =>
                                              value == null
                                                  ? 'Selecione um aluno'
                                                  : null,
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
                                initialEntryMode:
                                    DatePickerEntryMode.calendarOnly,
                                selectableDayPredicate: (day) => day.day == 1,
                              );
                              if (picked != null) {
                                final mes = picked.month.toString().padLeft(
                                  2,
                                  '0',
                                );
                                mesReferenciaCtrl.text =
                                    '${picked.year}-$mes-01';
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Selecione o mes de referencia';
                              }
                              if (!RegExp(
                                r'^\d{4}-\d{2}-01$',
                              ).hasMatch(v.trim())) {
                                return 'Formato invalido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: TokensStrip.s5),
                          FxLiquidPrimaryButton(
                            label:
                                salvando ? 'Salvando...' : 'Lancar Mensalidade',
                            icon: Icons.check,
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
            ),
          ),
    );
  }
}
