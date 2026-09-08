part of 'lead_detail_screen.dart';

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  Lead? _lead;
  List<LeadInteracao> _interacoes = [];
  bool _loadingLead = false;
  bool _loadingInteracoes = true;
  String? _erroLead;
  DateTime? _fetchedAt;
  var _secao = leadDetailSecaoResumo;

  void _leave() => safePopOrGo(context, '/leads');

  Lead get _activeLead {
    final lead = _lead;
    if (lead == null) {
      throw StateError('Lead ainda não carregado');
    }
    return lead;
  }

  @override
  void initState() {
    super.initState();
    if (widget.lead != null) {
      _lead = widget.lead;
      _fetchedAt = DateTime.now();
      _carregarInteracoes();
    } else {
      _carregarLead();
    }
  }

  Future<void> _carregarLead() async {
    setState(() {
      _loadingLead = true;
      _erroLead = null;
    });
    try {
      final lead = await LeadRepository(
        ref.read(apiClientProvider),
      ).buscar(widget.leadId!);
      if (mounted) {
        setState(() {
          _lead = lead;
          _loadingLead = false;
          _fetchedAt = DateTime.now();
        });
        _carregarInteracoes();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLead = false;
          _erroLead = friendlyError(e);
        });
      }
    }
  }

  Future<void> _carregarInteracoes() async {
    final lead = _lead;
    if (lead == null) return;
    setState(() => _loadingInteracoes = true);
    try {
      final repo = LeadRepository(ref.read(apiClientProvider));
      final lista = await repo.listarInteracoes(lead.id);
      if (mounted) {
        setState(() {
          _interacoes = lista;
          _loadingInteracoes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingInteracoes = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _refresh() async {
    final id = _lead?.id ?? widget.leadId;
    if (id == null) return;
    try {
      final lead = await LeadRepository(ref.read(apiClientProvider)).buscar(id);
      if (!mounted) return;
      setState(() {
        _lead = lead;
        _fetchedAt = DateTime.now();
      });
      await _carregarInteracoes();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _ligar() async {
    if (_activeLead.telefone == null) return;
    final uri = Uri.parse('tel:${_activeLead.telefone}');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri);
    }
  }

  Future<void> _whatsapp() async {
    if (_activeLead.telefone == null) return;
    final tel = _activeLead.telefone!.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/55$tel');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _mudarStatus(String novoStatus) async {
    try {
      final updated = await LeadRepository(
        ref.read(apiClientProvider),
      ).atualizar(_activeLead.id, {'status': novoStatus});
      setState(() => _lead = updated);
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Status atualizado para ${leadStatusLabel(novoStatus)}',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _converter() async {
    final confirm = await showFxConfirmSheet(
      context,
      title: 'Converter em Aluno?',
      message: '${_activeLead.nome} será criado como aluno na sua lista.',
      icon: Icons.person_add_alt_1_rounded,
      confirmLabel: 'Converter',
    );
    if (!confirm) return;
    try {
      await LeadRepository(
        ref.read(apiClientProvider),
      ).converter(_activeLead.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Lead convertido!');
        safePopOrGo(context, '/leads');
      }
    } catch (e) {
      if (!mounted) return;
      final surfaced = await UpgradePromptSheet.showFromError(
        context,
        e,
        fallbackFeatureName: 'Alunos',
        fallbackCapability: 'alunos',
        source: 'lead_converter',
      );
      if (surfaced || !mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _arquivar() async {
    final confirm = await showFxConfirmSheet(
      context,
      title: 'Arquivar lead?',
      message: 'O lead será marcado como Cancelado.',
      icon: Icons.archive_outlined,
      confirmLabel: 'Arquivar',
      destructive: true,
    );
    if (!confirm) return;
    try {
      await LeadRepository(
        ref.read(apiClientProvider),
      ).arquivar(_activeLead.id);
      if (mounted) safePopOrGo(context, '/leads');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _definirFollowUp() async {
    final now = DateTime.now();
    DateTime? inicial;
    if (_activeLead.proximoContato != null) {
      try {
        inicial = DateTime.parse(_activeLead.proximoContato!);
      } catch (_) {}
    }
    final options = alunoFollowUpDateOptions(now);
    final picked = await showFxInsetPickerSheet<DateTime>(
      context,
      title: 'Follow-up',
      subtitle: 'Quando você fala de novo com este lead.',
      headerIcon: Icons.event_outlined,
      selected: alunoFollowUpDateSelected(
        options: options,
        current: inicial,
      ),
      sameValue:
          (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
      items: [
        for (final option in options)
          FxInsetPickerSheetItem(
            value: option.date,
            label: option.label,
            subtitle: option.subtitle,
            icon: Icons.event_outlined,
          ),
      ],
    );
    if (picked == null) return;
    final dataStr =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      final updated = await LeadRepository(
        ref.read(apiClientProvider),
      ).atualizarProximoContato(_activeLead.id, dataStr);
      setState(() => _lead = updated);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Follow-up definido para $dataStr');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _abrirStatus() async {
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Status',
      selected: _activeLead.status,
      items: [
        for (final s in leadStatusValues)
          FxInsetPickerSheetItem(value: s, label: leadStatusLabel(s)),
      ],
    );
    if (!mounted || picked == null || picked == _activeLead.status) return;
    await _mudarStatus(picked);
  }

  Future<void> _onSticky(LeadStickyAction action) {
    return switch (action) {
      LeadStickyAction.converter => _converter(),
      LeadStickyAction.whatsapp => _whatsapp(),
      LeadStickyAction.followUp => _definirFollowUp(),
    };
  }

  Future<void> _novaInteracao() async {
    var tipo = 'WHATSAPP';
    final descCtrl = TextEditingController();
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Nova interação',
        subtitle: 'Registre o contato com este lead.',
        icon: Icons.chat_bubble_outline_rounded,
        confirmLabel: 'Salvar',
        child: StatefulBuilder(
          builder:
              (ctx, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FxInsetPickerRow(
                    icon: Icons.category_outlined,
                    label: 'Tipo',
                    value: leadInteracaoTipoLabel(tipo),
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<String>(
                        ctx,
                        title: 'Tipo',
                        selected: tipo,
                        items: [
                          for (final t in leadInteracaoTipoValues)
                            FxInsetPickerSheetItem(
                              value: t,
                              label: leadInteracaoTipoLabel(t),
                            ),
                        ],
                      );
                      if (picked == null) return;
                      setDialogState(() => tipo = picked);
                    },
                  ),
                  AlunoInsetFormField(
                    controller: descCtrl,
                    label: 'Descrição',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    showDivider: false,
                  ),
                ],
              ),
        ),
      );
      final desc = descCtrl.text.trim();
      if (ok != true || desc.isEmpty) {
        if (ok == true && mounted) {
          FeedbackHelper.showError(context, 'Informe a descrição');
        }
        return;
      }
      await LeadRepository(
        ref.read(apiClientProvider),
      ).adicionarInteracao(_activeLead.id, tipo, desc);
      await _carregarInteracoes();
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Interação registrada!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      descCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLead || _lead == null) {
    return fxScreenA11yScope(
      label: 'Lead',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _leave();
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Lead',
          onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar este lead',
                onTap: () => showLeadDetailHelpSheet(context),
              ),
            ],
          ),
          body:
              _loadingLead
                  ? const SkeletonList(count: 5)
                  : FxErrorState(
                    chromeOnDark:
                        Theme.of(context).brightness == Brightness.dark,
                    primary: Theme.of(context).colorScheme.primary,
                    title: 'Não conseguimos carregar o lead',
                    message:
                        _erroLead ?? 'Não encontramos os dados deste lead.',
                    onRetry: _carregarLead,
                  ),
        ),
      ),
    );
    }

    final lead = _lead!;
    final temTelefone = lead.telefone?.trim().isNotEmpty == true;
    final sticky = leadStickyAction(
      status: lead.status,
      temTelefone: temTelefone,
    );

    return fxScreenA11yScope(
      label: 'Lead ${lead.nome}',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _leave();
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Lead',
          onBack: _leave,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar este lead',
              onTap: () => showLeadDetailHelpSheet(context),
            ),
            ShellHeaderIconButton(
              icon: 'trend',
              tooltip: 'Mudar status',
              onTap: _abrirStatus,
            ),
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Nova interação',
              onTap: _novaInteracao,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FxContentWidthLimiter(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _LeadDetailContent(
                  lead: lead,
                  loadingInteracoes: _loadingInteracoes,
                  interacoes: _interacoes,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  freshnessLabel: FxHubFreshness.fromFetchedAt(_fetchedAt),
                  sticky: sticky,
                  secao: _secao,
                  onSecao: (value) => setState(() => _secao = value),
                  onDefinirFollowUp: _definirFollowUp,
                  onLigar: _ligar,
                  onWhatsapp: _whatsapp,
                  onArquivar: _arquivar,
                  onNovaInteracao: _novaInteracao,
                ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: FxLiquidPrimaryButton(
                  label: leadStickyP0Label(sticky),
                  onPressed: () => _onSticky(sticky),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
