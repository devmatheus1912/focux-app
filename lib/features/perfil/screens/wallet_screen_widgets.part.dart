part of 'wallet_screen.dart';

class _WalletFormFields extends StatelessWidget {
  const _WalletFormFields({
    required this.tipoChavePix,
    required this.chavePixCtrl,
    required this.bancoCtrl,
    required this.agenciaCtrl,
    required this.contaCtrl,
    required this.carregando,
    required this.onSelecionarTipo,
    required this.onCopiarChave,
  });

  final String? tipoChavePix;
  final TextEditingController chavePixCtrl;
  final TextEditingController bancoCtrl;
  final TextEditingController agenciaCtrl;
  final TextEditingController contaCtrl;
  final bool carregando;
  final VoidCallback onSelecionarTipo;
  final VoidCallback onCopiarChave;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxHubHeader(
          title: 'Recebimentos',
          subtitle: walletHubSubtitle(),
        ),
        const SizedBox(height: TokensStrip.s4),
        const _ResumoMensalCard(),
        const SizedBox(height: TokensStrip.s4),
        DashboardSectionHeader(title: walletPixSectionTitle()),
        const SizedBox(height: TokensStrip.s2),
        FxSettingsTile(
          fxIcon: 'pix',
          label: 'Tipo de chave',
          value:
              tipoChavePix == null
                  ? 'Selecionar'
                  : WalletPixValidation.labelForTipo(tipoChavePix!),
          picker: true,
          onTap: carregando ? null : onSelecionarTipo,
        ),
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
        if (chavePixCtrl.text.trim().isNotEmpty)
          FxSatelliteListTile(
            title: walletCopiarTileLabel(),
            titleCase: false,
            onTap: carregando ? null : onCopiarChave,
            leading: FxIcon(name: 'pix', size: 18, color: primary),
          ),
        const SizedBox(height: TokensStrip.s4),
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
    );
  }
}

class _ResumoMensalCard extends ConsumerStatefulWidget {
  const _ResumoMensalCard();

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
    _load();
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
        if (inadimplentes > 0) ...[
          const SizedBox(height: TokensStrip.s3),
          OperationalMetricTile(
            label: 'Inadimplentes',
            value: '$inadimplentes',
            hint: 'Cobranças em atraso neste mês',
            color: EagleTokens.bad,
            isDark: isDark,
            emphasis: OperationalMetricEmphasis.alert,
          ),
        ],
        const SizedBox(height: TokensStrip.s2),
        FxSatelliteListTile(
          title: walletVerFinanceiroLabel(),
          titleCase: false,
          onTap: () => context.push('/financeiro'),
          leading: FxIcon(name: 'coin', size: 18, color: primary),
        ),
      ],
    );
  }
}
