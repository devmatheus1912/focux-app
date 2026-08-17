part of 'lead_detail_screen.dart';

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  Lead? _lead;
  List<LeadInteracao> _interacoes = [];
  bool _loadingLead = false;
  bool _loadingInteracoes = true;
  String? _erroLead;

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
          'Status atualizado para ${_statusLabels[novoStatus]}',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _converter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Converter em Aluno?'),
            content: Text(
              '${_activeLead.nome} será criado como aluno na sua lista.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FxLiquidPrimaryButton(
                expand: false,
                label: 'Converter',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      await LeadRepository(
        ref.read(apiClientProvider),
      ).converter(_activeLead.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Lead convertido!');
        safePopOrGo(context, '/leads');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _arquivar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Arquivar lead?'),
            content: const Text('O lead será marcado como Cancelado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FxLiquidPrimaryButton(
                expand: false,
                label: 'Arquivar',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirm != true) return;
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
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Selecione a data de follow-up',
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

  Future<void> _novaInteracao() async {
    String tipo = 'WHATSAPP';
    final descCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nova Interação',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      DropdownButtonFormField<String>(
                        initialValue: tipo,
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items:
                            _tiposInteracao
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _tipoIcons[t] ?? Icons.note,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(t),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) setS(() => tipo = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          labelText: 'Descrição *',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      SizedBox(
                        width: double.infinity,
                        child: FxLiquidPrimaryButton(
                          icon: Icons.save,
                          label: 'Salvar',
                          onPressed: () async {
                            final desc = descCtrl.text.trim();
                            if (desc.isEmpty) {
                              FeedbackHelper.showError(
                                ctx,
                                'Informe a descrição',
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              await LeadRepository(
                                ref.read(apiClientProvider),
                              ).adicionarInteracao(_activeLead.id, tipo, desc);
                              await _carregarInteracoes();
                              if (mounted) {
                                FeedbackHelper.showSuccess(
                                  context,
                                  'Interação registrada!',
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                FeedbackHelper.showError(
                                  context,
                                  friendlyError(e),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLead || _lead == null) {
      return fxScreenA11yScope(
        label: 'Lead',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Lead',
            onBack: () => safePopOrGo(context, '/leads'),
          ),
          body:
              _loadingLead
                  ? const SkeletonList(count: 5)
                  : FxErrorState(
                    chromeOnDark:
                        Theme.of(context).brightness == Brightness.dark,
                    primary: Theme.of(context).colorScheme.primary,
                    message:
                        _erroLead ?? 'Não encontramos os dados deste lead.',
                    onRetry: _carregarLead,
                  ),
        ),
      );
    }

    final lead = _lead!;
    final color = _statusColor(
      lead.status,
      Theme.of(context).colorScheme.primary,
    );
    final podeConverter = lead.status != 'CONVERTIDO' && lead.status != 'ATIVO';

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: lead.nome,
        onBack: () => safePopOrGo(context, '/leads'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _mudarStatus,
            itemBuilder:
                (_) =>
                    _statusOpcoes
                        .map(
                          (s) => PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _statusColor(
                                    s,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_statusLabels[s] ?? s),
                              ],
                            ),
                          ),
                        )
                        .toList(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaInteracao,
        icon: const Icon(Icons.add_comment),
        label: const Text('Nova Interação'),
      ),
      body: _LeadDetailContent(
        lead: lead,
        color: color,
        podeConverter: podeConverter,
        loadingInteracoes: _loadingInteracoes,
        interacoes: _interacoes,
        onDefinirFollowUp: _definirFollowUp,
        onLigar: _ligar,
        onWhatsapp: _whatsapp,
        onConverter: _converter,
        onArquivar: _arquivar,
      ),
    );
  }
}
