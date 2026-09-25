part of 'wallet_screen.dart';

class _WalletFormFields extends StatelessWidget {
  const _WalletFormFields({
    required this.tipoChavePix,
    required this.chavePixCtrl,
    required this.bancoCtrl,
    required this.agenciaCtrl,
    required this.contaCtrl,
    required this.carregando,
    required this.secao,
    required this.onSecao,
    required this.onSelecionarTipo,
    required this.onCopiarChave,
    this.resumoMensal,
  });

  final String? tipoChavePix;
  final TextEditingController chavePixCtrl;
  final TextEditingController bancoCtrl;
  final TextEditingController agenciaCtrl;
  final TextEditingController contaCtrl;
  final bool carregando;
  final String secao;
  final ValueChanged<String> onSecao;
  final VoidCallback onSelecionarTipo;
  final VoidCallback onCopiarChave;
  final ResumoMensal? resumoMensal;

  Future<void> _openMais(BuildContext context) async {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final temChave = chavePixCtrl.text.trim().isNotEmpty;
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: isDark,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                FxHomeSheetHeader(
                  leading: Icon(Icons.more_horiz_rounded, color: primary),
                  title: 'Mais',
                  subtitle: 'Atalhos e resumo do mês',
                  isDark: isDark,
                ),
                const SizedBox(height: TokensStrip.s3),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    FxActionChip(
                      label: 'Perfil',
                      accent: primary,
                      isDark: isDark,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        safePopOrGo(context, '/perfil');
                      },
                    ),
                    FxActionChip(
                      label: walletVerFinanceiroLabel(),
                      accent: primary,
                      isDark: isDark,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/financeiro');
                      },
                    ),
                    if (temChave)
                      FxActionChip(
                        label: walletCopiarTileLabel(),
                        accent: primary,
                        isDark: isDark,
                        enabled: !carregando,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onCopiarChave();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                _ResumoMensalCard(resumo: resumoMensal),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final masked = maskPixKeyForDisplay(tipoChavePix, chavePixCtrl.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxHubHeader(
          title: 'Recebimentos',
          subtitle: walletHubSubtitle(),
        ),
        const SizedBox(height: TokensStrip.s3),
        OperationalMetricTile(
          label: 'PIX',
          value: walletPixStatusValue(tipoChavePix, chavePixCtrl.text),
          hint: masked.isEmpty
              ? walletPixStatusHint(tipoChavePix, chavePixCtrl.text)
              : '${WalletPixValidation.labelForTipo(tipoChavePix ?? '')} · $masked',
          color: primary,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s3),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            FxActionChip(
              label: walletTipoChipLabel(tipoChavePix),
              accent: primary,
              isDark: isDark,
              enabled: !carregando,
              onPressed: onSelecionarTipo,
            ),
            FxActionChip(
              label: 'Mais',
              accent: primary,
              isDark: isDark,
              onPressed: () => _openMais(context),
            ),
          ],
        ),
        const SizedBox(height: TokensStrip.s4),
        AlunoSegmentedChoice(
          options: walletDetalheSecoes,
          selected: secao,
          isDark: isDark,
          onSelect: onSecao,
        ),
        const SizedBox(height: TokensStrip.s4),
        if (secao == walletDetalheSecaoPix) ...[
          DashboardSectionHeader(title: walletPixSectionTitle()),
          const SizedBox(height: TokensStrip.s2),
          AlunoInsetFormField(
            controller: chavePixCtrl,
            label: 'Chave PIX',
            icon: Icons.pix_rounded,
            hint: WalletPixValidation.hintForTipo(tipoChavePix),
            keyboardType: WalletPixValidation.keyboardForTipo(tipoChavePix),
            inputFormatters: [
              ...WalletPixValidation.formattersForTipo(tipoChavePix),
              LengthLimitingTextInputFormatter(walletChavePixMax),
            ],
            validator:
                (v) => WalletPixValidation.validateChave(tipoChavePix, v ?? ''),
            showDivider: false,
          ),
        ] else ...[
          DashboardSectionHeader(title: walletBancoSectionTitle()),
          const SizedBox(height: TokensStrip.s2),
          AlunoInsetFormField(
            controller: bancoCtrl,
            label: 'Banco',
            icon: Icons.account_balance_outlined,
            hint: 'Ex.: Nubank, Itaú, Bradesco',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              LengthLimitingTextInputFormatter(walletBancoMax),
            ],
          ),
          AlunoInsetFormField(
            controller: agenciaCtrl,
            label: 'Agência',
            icon: Icons.tag_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(walletAgenciaMax),
            ],
          ),
          AlunoInsetFormField(
            controller: contaCtrl,
            label: 'Conta',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.text,
            inputFormatters: WalletPixValidation.formattersForConta(),
            showDivider: false,
          ),
        ],
      ],
    );
  }
}

class _ResumoMensalCard extends ConsumerStatefulWidget {
  const _ResumoMensalCard({this.resumo});

  final ResumoMensal? resumo;

  @override
  ConsumerState<_ResumoMensalCard> createState() => _ResumoMensalCardState();
}

class _ResumoMensalCardState extends ConsumerState<_ResumoMensalCard> {
  ResumoMensal? _resumo;
  bool _loading = true;
  String? _error;
  late final DateTime _periodo = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.resumo != null) {
      _resumo = widget.resumo;
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant _ResumoMensalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resumo != null && widget.resumo != oldWidget.resumo) {
      _resumo = widget.resumo;
      _loading = false;
      _error = null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = FinanceiroRepository(ref.read(apiClientProvider));
      final res = await repo.resumoMensal(_periodo.year, _periodo.month);
      if (mounted) {
        setState(() {
          _resumo = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SkeletonLoader(height: 72, borderRadius: 12);
    }
    if (_error != null) {
      return FxErrorState(
        chromeOnDark: ShellChrome.of(context).isDark,
        primary: Theme.of(context).colorScheme.primary,
        message: _error!,
        onRetry: _load,
        title: 'Não conseguimos carregar o resumo',
      );
    }
    final resumo = _resumo;
    if (resumo == null) {
      return FxEmptyState(
        icon: 'pix',
        title: 'Nenhum movimento neste mês',
        subtitle: 'Quando houver cobranças, o resumo aparece aqui.',
        action: FxEmptyAction(
          label: walletVerFinanceiroLabel(),
          onTap: () => context.push('/financeiro'),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inadimplentes = resumo.inadimplentes;
    final semMovimento =
        resumo.totalPrevisto.isZero &&
        resumo.totalRecebido.isZero &&
        inadimplentes == 0;
    final percentRecebido =
        resumo.totalPrevisto.isZero
            ? 0
            : (resumo.totalRecebido.ratioOf(resumo.totalPrevisto).clamp(0.0, 1.0) *
                    100)
                .round();
    final periodoLabel = monthYearLabelPtBr(_periodo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OperationalMetricTile(
          label: 'Recebido · $periodoLabel',
          value: resumo.totalRecebido.format(),
          hint:
              semMovimento
                  ? 'Nenhuma cobrança neste mês'
                  : walletRecebidoHint(
                    previsto: resumo.totalPrevisto.format(),
                    percent: percentRecebido,
                  ),
          color: semMovimento ? primary : EagleTokens.good,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'Previsto',
          value: resumo.totalPrevisto.format(),
          hint:
              semMovimento
                  ? 'Nenhuma cobrança neste mês'
                  : 'Cobranças do mês',
          color: primary,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'Inadimplentes',
          value: '$inadimplentes',
          hint:
              inadimplentes == 0
                  ? 'Nenhuma cobrança em atraso'
                  : 'Cobranças em atraso neste mês',
          color: inadimplentes == 0 ? primary : EagleTokens.bad,
          isDark: isDark,
          emphasis:
              inadimplentes == 0
                  ? OperationalMetricEmphasis.normal
                  : OperationalMetricEmphasis.alert,
        ),
      ],
    );
  }
}
