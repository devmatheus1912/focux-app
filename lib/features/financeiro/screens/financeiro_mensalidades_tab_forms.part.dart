part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabForms on _FinanceiroMensalidadesTabState {
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
                                final picked = await pickMensalidadeMesReferencia(
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
