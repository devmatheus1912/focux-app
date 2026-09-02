part of 'suporte_screen.dart';

class _NovoTicketSheet extends ConsumerStatefulWidget {
  const _NovoTicketSheet();

  @override
  ConsumerState<_NovoTicketSheet> createState() => _NovoTicketSheetState();
}

class _NovoTicketSheetState extends ConsumerState<_NovoTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _classeCtrl = TextEditingController();

  String _severidade = 'MEDIA';
  bool _enviando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _classeCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirSeveridade() async {
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Severidade',
      selected: _severidade,
      items: [
        for (final s in suporteSeveridadeValues)
          FxInsetPickerSheetItem(value: s, label: suporteSeveridadeLabel(s)),
      ],
    );
    if (picked == null) return;
    setState(() => _severidade = picked);
  }

  Future<void> _enviarTicket() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: suporteEnviarTicketConfirmTitle(),
      message: suporteEnviarTicketConfirmMessage(),
      icon: Icons.support_agent_rounded,
      confirmLabel: suporteEnviarTicketConfirmLabel(),
    );
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      final repo = SuporteRepository(ref.read(apiClientProvider));
      final ticket = await repo.criarTicket(
        titulo: _tituloCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        severidade: _severidade,
        classeAfetada:
            _classeCtrl.text.trim().isEmpty ? null : _classeCtrl.text.trim(),
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(ticket);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  0,
                ),
                child: FxHomeSheetHeader(
                  isDark: isDark,
                  title: 'Abrir ticket',
                  subtitle: 'Descreva o problema para o suporte Focux.',
                  leading: FxIcon(name: 'message-circle', color: primary, size: 18),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  MediaQuery.of(context).viewInsets.bottom + TokensStrip.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FxSettingsGroup(
                      children: [
                        AlunoInsetFormField(
                          controller: _tituloCtrl,
                          label: 'Título',
                          icon: Icons.title_outlined,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(suporteTituloMax),
                          ],
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Informe um título'
                                      : null,
                        ),
                        AlunoInsetFormField(
                          controller: _descricaoCtrl,
                          label: 'Descrição',
                          icon: Icons.notes_outlined,
                          maxLines: 4,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              suporteDescricaoMax,
                            ),
                          ],
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Descreva o problema'
                                      : null,
                        ),
                        FxSettingsTile(
                          fxIcon: 'alert-triangle',
                          label: 'Severidade',
                          value: suporteSeveridadeLabel(_severidade),
                          picker: true,
                          onTap: _enviando ? () {} : _abrirSeveridade,
                        ),
                        AlunoInsetFormField(
                          controller: _classeCtrl,
                          label: 'Classe afetada',
                          icon: Icons.code_outlined,
                          hint: 'Ex: TreinoService',
                          showDivider: false,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(suporteClasseMax),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    FxSettingsGroup(
                      children: [
                        FxSettingsTile(
                          fxIcon: 'circle-check',
                          label: suporteEnviarTicketLabel(),
                          value: _enviando ? 'Enviando…' : 'Confirmar',
                          showDivider: false,
                          onTap: _enviando ? () {} : _enviarTicket,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
