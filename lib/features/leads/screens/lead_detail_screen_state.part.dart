part of 'lead_detail_screen.dart';

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen>
    with InteressadoContatoMixin<LeadDetailScreen> {
  Lead? _lead;
  List<LeadInteracao> _interacoes = const [];
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  LeadRepository get repoInteressados =>
      LeadRepository(ref.read(apiClientProvider));

  @override
  Future<void> aoAnotarContato() => _carregar();

  void _leave() => safePopOrGo(context, '/leads');

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _carregar();
  }

  /// O detalhe traz os e-mails automáticos; a lista não.
  Future<void> _carregar() async {
    final id = _lead?.id ?? widget.leadId;
    if (id == null) return;
    setState(() {
      _loading = _lead == null;
      _erro = null;
    });
    try {
      final lead = await repoInteressados.buscar(id);
      final interacoes = await repoInteressados.listarInteracoes(id);
      if (!mounted) return;
      setState(() {
        _lead = lead;
        _interacoes = interacoes;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_lead == null) _erro = friendlyError(e);
      });
      if (_lead != null) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _mudarEtapa(String status) async {
    final lead = _lead;
    if (lead == null || lead.status == status) return;
    try {
      final atualizado = await repoInteressados.atualizar(lead.id, {
        'status': status,
      });
      invalidateLeadsCaches(ref);
      if (!mounted) return;
      setState(() => _lead = atualizado);
      FeedbackHelper.showSuccess(
        context,
        'Agora em ${interessadoEtapaLabel(status)}.',
      );
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _escolherEtapa() async {
    final lead = _lead;
    if (lead == null || interessadoVirouAluno(lead.status)) return;
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Etapa',
      selected: lead.status.toUpperCase(),
      items: [
        for (final s in interessadoEtapasManuais)
          FxInsetPickerSheetItem(value: s, label: interessadoEtapaLabel(s)),
      ],
    );
    if (picked != null && mounted) await _mudarEtapa(picked);
  }

  Future<void> _definirProximo() async {
    final lead = _lead;
    if (lead == null) return;
    final agora = DateTime.now();
    final picked =
        (await showFxCalendarioSheet(
          context,
          titulo: 'Próximo contato',
          subtitulo:
              'Quando você fala de novo com ${lead.nome.split(' ').first}.',
          inicial: DateTime.tryParse(lead.proximoContato ?? ''),
          primeiro: agora,
          ultimo: agora.add(const Duration(days: 365)),
        ))?.data;
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      final atualizado = await repoInteressados.atualizarProximoContato(
        lead.id,
        iso,
      );
      if (!mounted) return;
      setState(() => _lead = atualizado);
      FeedbackHelper.showSuccess(
        context,
        'Próximo contato em ${dataCurta(picked)}.',
      );
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _anotarContato() async {
    final lead = _lead;
    if (lead == null) return;
    var tipo = 'WHATSAPP';
    final descCtrl = TextEditingController();
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Anotar contato',
        subtitle: 'Fica no histórico de ${lead.nome.split(' ').first}.',
        icon: FxIcons.notas,
        confirmLabel: 'Anotar',
        aoConfirmar: () async {
          try {
            await repoInteressados.adicionarInteracao(
              lead.id,
              tipo,
              descCtrl.text.trim(),
            );
            final proxima = interessadoEtapaDepoisDoContato(lead.status);
            if (proxima != null) {
              await repoInteressados.atualizar(lead.id, {'status': proxima});
            }
            return null;
          } catch (e) {
            return friendlyError(e);
          }
        },
        child: StatefulBuilder(
          builder:
              (ctx, setSheet) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FxInsetPickerRow(
                    icon: FxIcons.chat,
                    label: 'Como foi',
                    value: interessadoInteracaoLabel(tipo),
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<String>(
                        ctx,
                        title: 'Como foi',
                        selected: tipo,
                        items: [
                          for (final t in leadInteracaoTipoValues)
                            FxInsetPickerSheetItem(
                              value: t,
                              label: interessadoInteracaoLabel(t),
                            ),
                        ],
                      );
                      if (picked != null) setSheet(() => tipo = picked);
                    },
                  ),
                  AlunoInsetFormField(
                    controller: descCtrl,
                    label: 'O que combinaram (opcional)',
                    icon: FxIcons.notas,
                    maxLines: 3,
                    showDivider: false,
                  ),
                ],
              ),
        ),
      );
      if (ok && mounted) await _carregar();
    } finally {
      descCtrl.dispose();
    }
  }

  Future<void> _cadastrarComoAluno() async {
    final lead = _lead;
    if (lead == null) return;
    final criado = await context.push<bool>(
      leadConverterRoute(
        leadId: lead.id,
        nome: lead.nome,
        email: lead.email,
        telefone: lead.telefone,
        objetivo: lead.objetivo,
      ),
    );
    if (criado != true || !mounted) return;
    invalidateLeadsCaches(ref);
    await _carregar();
  }

  Future<void> _maisOpcoes() async {
    final lead = _lead;
    if (lead == null) return;
    final semInteresse = lead.status.toUpperCase() == 'CANCELADO';
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: lead.nome,
      grupos: [
        FxActionGroup<String>(null, [
          const FxActionItem(
            valor: 'editar',
            rotulo: 'Editar dados',
            icone: FxIcons.editar,
          ),
          if (!interessadoVirouAluno(lead.status))
            FxActionItem(
              valor: semInteresse ? 'voltar' : 'sem',
              rotulo:
                  semInteresse
                      ? 'Voltar para Para responder'
                      : 'Marcar sem interesse',
              icone: semInteresse ? FxIcons.desfazer : FxIcons.arquivar,
            ),
        ]),
      ],
      destrutiva:
          interessadoPodeExcluir(status: lead.status, alunoId: lead.alunoId)
              ? const FxActionItem(
                valor: 'excluir',
                rotulo: 'Excluir',
                icone: FxIcons.excluir,
              )
              : null,
      confirmarTitulo: interessadoExcluirTitulo(lead.nome),
      confirmarMensagem: interessadoExcluirMensagem,
    );
    if (acao == null || !mounted) return;
    switch (acao) {
      case 'editar':
        final salvo = await showInteressadoSheet(
          context,
          repo: repoInteressados,
          lead: lead,
        );
        if (salvo != null && mounted) await _carregar();
      case 'sem':
        await _mudarEtapa('CANCELADO');
      case 'voltar':
        await _mudarEtapa('LEAD');
      case 'excluir':
        try {
          await repoInteressados.excluir(lead.id);
          invalidateLeadsCaches(ref);
          if (!mounted) return;
          FeedbackHelper.showSuccess(context, 'Interessado excluído');
          _leave();
        } catch (e) {
          if (mounted) FeedbackHelper.showError(context, friendlyError(e));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final lead = _lead;
    return fxScreenA11yScope(
      label: lead?.nome ?? 'Interessado',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: FxShellScaffold(
          comFundo: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Interessado',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar a ficha',
                onTap:
                    () => showFxHelpSheet(
                      context,
                      title: 'Ficha',
                      subtitle: 'Tudo o que você conversou com esta pessoa.',
                      tips: const [
                        FxHelpTip(
                          'Etapa',
                          'Toque na etapa para mudar. Depois de anotar um contato, ela vai para Em conversa sozinha.',
                        ),
                        FxHelpTip(
                          'Próximo contato',
                          'No dia, ela aparece com "Retornar hoje" na lista e na Hoje.',
                        ),
                      ],
                    ),
              ),
              if (lead != null)
                IconButton(
                  tooltip: 'Mais opções',
                  onPressed: _maisOpcoes,
                  icon: const Icon(FxIcons.mais),
                ),
            ],
          ),
          body:
              _loading && lead == null
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 5),
                  )
                  : lead == null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: primary,
                    message: _erro ?? 'Interessado não encontrado.',
                    onRetry: _carregar,
                  )
                  : _corpo(lead, chrome, primary),
        ),
      ),
    );
  }

  Widget _corpo(Lead lead, ShellPalette chrome, Color primary) {
    final sobre = fxPaletaSobreMarca(context, accent: primary);
    final temTel = (lead.telefone ?? '').trim().isNotEmpty;
    final temEmail = (lead.email ?? '').trim().isNotEmpty;
    final virou = interessadoVirouAluno(lead.status);
    final semInteresse = lead.status.toUpperCase() == 'CANCELADO';
    final criado = DateTime.tryParse(lead.criadoEm);
    final proximo = DateTime.tryParse(lead.proximoContato ?? '');
    final historico = interessadoHistorico(lead, _interacoes);
    final linha = [
      interessadoLinha(lead),
      if (criado != null) 'desde ${dataCurta(criado)}',
    ].where((p) => p.isNotEmpty).join(' · ');

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: primary,
            onRefresh: _carregar,
            child: FxContentWidthLimiter(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s6,
                ),
                children: [
                  FxStripCard(
                    marca: true,
                    accent: primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.nome,
                          style: FocuxHubTypography.cardTitle(color: sobre.ink),
                        ),
                        if (linha.isNotEmpty) ...[
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            linha,
                            style: FocuxHubTypography.bodyMuted(
                              color: sobre.mute,
                            ),
                          ),
                        ],
                        const SizedBox(height: TokensStrip.s3),
                        Semantics(
                          button: !virou,
                          label: 'Etapa: ${interessadoEtapaLabel(lead.status)}',
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: virou ? null : _escolherEtapa,
                            borderRadius: BorderRadius.circular(
                              TokensStrip.rPill,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TokensStrip.s3,
                                vertical: TokensStrip.s1,
                              ),
                              decoration: BoxDecoration(
                                color: sobre.ink.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  TokensStrip.rPill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    interessadoEtapaLabel(lead.status),
                                    style: FocuxHubTypography.rotulo(
                                      color: sobre.ink,
                                    ),
                                  ),
                                  if (!virou) ...[
                                    const SizedBox(width: TokensStrip.s1),
                                    Icon(
                                      FxIcons.chevronBaixo,
                                      size: 18,
                                      color: sobre.ink,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (temTel || temEmail) ...[
                    const SizedBox(height: TokensStrip.s3),
                    Wrap(
                      spacing: TokensStrip.s2,
                      runSpacing: TokensStrip.s2,
                      children: [
                        if (temTel)
                          FxTonalButton(
                            label: 'WhatsApp',
                            icon: FxIcons.chat,
                            compact: true,
                            onPressed:
                                () => contatarInteressado(lead, 'WHATSAPP'),
                          ),
                        if (temTel)
                          FxTonalButton(
                            label: 'Ligar',
                            icon: FxIcons.telefone,
                            compact: true,
                            onPressed:
                                () => contatarInteressado(lead, 'LIGACAO'),
                          ),
                        if (temEmail)
                          FxTonalButton(
                            label: 'E-mail',
                            icon: FxIcons.email,
                            compact: true,
                            onPressed:
                                () => launchUrl(
                                  Uri(
                                    scheme: 'mailto',
                                    path: lead.email!.trim(),
                                  ),
                                ),
                          ),
                      ],
                    ),
                  ],
                  if (!virou && !semInteresse) ...[
                    const SizedBox(height: TokensStrip.s3),
                    FxSettingsGroup(
                      children: [
                        FxSettingsTile(
                          icon: FxIcons.calendario,
                          label:
                              proximo == null
                                  ? 'Definir quando retornar'
                                  : 'Retornar em ${dataCurta(proximo)}',
                          value: '',
                          showDivider: false,
                          onTap: _definirProximo,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: TokensStrip.s5),
                  Row(
                    children: [
                      const Expanded(
                        child: DashboardSectionHeader(title: 'Histórico'),
                      ),
                      FxTonalButton(
                        label: 'Anotar contato',
                        icon: FxIcons.adicionar,
                        compact: true,
                        onPressed: _anotarContato,
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  if (historico.isEmpty)
                    Text(
                      'Nenhum contato anotado ainda.',
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    )
                  else
                    for (final e in historico)
                      Padding(
                        padding: const EdgeInsets.only(bottom: TokensStrip.s3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.titulo} · ${dataCurta(e.quando)}',
                              style: FocuxHubTypography.rotulo(
                                color: chrome.ink,
                              ),
                            ),
                            if (e.texto != null)
                              Text(
                                e.texto!,
                                style: FocuxHubTypography.bodyMuted(
                                  color: chrome.mute,
                                ),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
            ),
            child: FxLiquidPrimaryButton(
              label:
                  virou
                      ? 'Ver aluno'
                      : semInteresse
                      ? 'Voltar para Para responder'
                      : 'Cadastrar como aluno',
              onPressed:
                  virou
                      ? (lead.alunoId == null
                          ? null
                          : () => context.push('/alunos/${lead.alunoId}'))
                      : semInteresse
                      ? () => _mudarEtapa('LEAD')
                      : _cadastrarComoAluno,
            ),
          ),
        ),
      ],
    );
  }
}
