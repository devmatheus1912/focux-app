part of 'paywall_components.dart';

// ─── ROI calculator ─────────────────────────────────────────────────────────

class PaywallRoiCalculator extends StatefulWidget {
  final List<Plano> paidPlans;
  final Color ink;
  final Color mute;
  final Color line;
  final ValueChanged<SubscriptionPlan>? onSuggestPlan;

  const PaywallRoiCalculator({
    super.key,
    required this.paidPlans,
    required this.ink,
    required this.mute,
    required this.line,
    this.onSuggestPlan,
  });

  @override
  State<PaywallRoiCalculator> createState() => _PaywallRoiCalculatorState();
}

class _PaywallRoiCalculatorState extends State<PaywallRoiCalculator> {
  bool _expanded = false;
  int _students = 12;
  double _monthlyFee = 400;
  late final TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _feeController = TextEditingController(text: _monthlyFee.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mrr = _students * _monthlyFee;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: widget.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'Calculadora de ROI, ${_expanded ? 'recolher' : 'expandir'}',
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.calculate_outlined, size: 26, color: PaywallCatalog.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calcule seu ROI', style: TokensStrip.h2(color: widget.ink).copyWith(fontSize: 17)),
                          Text(
                            'Veja qual plano faz sentido agora',
                            style: TokensStrip.bodyMuted(color: widget.mute),
                          ),
                        ],
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: widget.mute),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alunos ativos hoje', style: TokensStrip.bodyMuted(color: widget.mute)),
                  Slider(
                    value: _students.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    label: '$_students',
                    onChanged: (v) => setState(() => _students = v.round()),
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mensalidade média (R\$)',
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: _feeController,
                    onChanged: (v) {
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n != null) {
                        setState(() => _monthlyFee = n.clamp(50, 5000));
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seu MRR atual', style: TokensStrip.bodyMuted(color: widget.mute)),
                        Text(
                          'R\$ ${mrr.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: widget.ink,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.paidPlans.map((p) {
                    final plan = subscriptionPlanFromApi(p.nome);
                    final price = p.precoMensal;
                    final pct = mrr > 0 ? (price / mrr * 100) : 0.0;
                    final payback = price > 0 ? (price / _monthlyFee).ceil() : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${PaywallCatalog.displayPlanName(plan)} · R\$ ${price.toStringAsFixed(2)}/mês',
                              style: TokensStrip.body(color: widget.ink),
                            ),
                          ),
                          Text(
                            mrr > 0 ? '${pct.toStringAsFixed(1)}% MRR' : '—',
                            style: TextStyle(
                              color: PaywallCatalog.accentForPlan(plan),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            payback <= 1 ? '1 aluno paga' : '$payback alunos',
                            style: TokensStrip.bodyMuted(color: widget.mute).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (mrr > 0 && widget.paidPlans.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Premium = ${(widget.paidPlans.first.precoMensal / mrr * 100).toStringAsFixed(2)}% do faturamento'
                      '${widget.paidPlans.first.precoMensal / mrr < 0.01 ? ' — menos de 1%, ROI imediato' : ''}',
                      style: TokensStrip.bodyMuted(color: widget.mute),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Comparison table ─────────────────────────────────────────────────────────

class PaywallComparisonTable extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallComparisonTable({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  static const double _featureColWidth = 168;
  static const double _tierColWidth = 64;

  TextStyle _cellStyle({bool header = false, bool feature = false}) => TextStyle(
    color: header ? ink : (feature ? ink : mute),
    fontSize: header ? 12 : 12,
    fontWeight: header || feature ? FontWeight.w700 : FontWeight.w500,
    height: 1.25,
  );

  Widget _cell(
    String text, {
    bool header = false,
    bool feature = false,
    double? width,
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Text(
          text,
          textAlign: align,
          style: _cellStyle(header: header, feature: feature),
          maxLines: header ? 2 : 4,
          softWrap: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = isDark ? EagleTokens.darkCardHi : EagleTokens.paper;
    final rowDivider = line.withValues(alpha: 0.5);
    final tableWidth = _featureColWidth + _tierColWidth * 4;

    return Semantics(
      label: 'Tabela de comparação de planos, 4 tiers, ${PaywallCatalog.comparisonRows.length} recursos',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: tableWidth,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(_featureColWidth),
              1: const FixedColumnWidth(_tierColWidth),
              2: const FixedColumnWidth(_tierColWidth),
              3: const FixedColumnWidth(_tierColWidth),
              4: const FixedColumnWidth(_tierColWidth),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: rowDivider, width: 1),
              bottom: BorderSide(color: rowDivider),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: headerBg),
                children: [
                  _cell('Recurso', header: true, width: _featureColWidth),
                  _cell('FREE', header: true, width: _tierColWidth, align: TextAlign.center),
                  _cell('PREM.', header: true, width: _tierColWidth, align: TextAlign.center),
                  _cell('ENT.', header: true, width: _tierColWidth, align: TextAlign.center),
                  _cell('PRO', header: true, width: _tierColWidth, align: TextAlign.center),
                ],
              ),
              ...PaywallCatalog.comparisonRows.map(
                (r) => TableRow(
                  children: [
                    _cell(r.feature, feature: true, width: _featureColWidth),
                    _cell(r.free, width: _tierColWidth, align: TextAlign.center),
                    _cell(r.premium, width: _tierColWidth, align: TextAlign.center),
                    _cell(r.enterprise, width: _tierColWidth, align: TextAlign.center),
                    _cell(r.enterprisePro, width: _tierColWidth, align: TextAlign.center),
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

class PaywallFeaturesGrid extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallFeaturesGrid({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final border = isDark ? EagleTokens.darkLine : line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in PaywallCatalog.topFeatures)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PaywallCatalog.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f.icon, color: PaywallCatalog.brand, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${f.rank} ${f.title}',
                        style: TokensStrip.h2(color: ink).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      _PlanChip(label: f.badge, color: f.badgeColor),
                      const SizedBox(height: 8),
                      Text(
                        f.description,
                        style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      _RoiMoneyTag(text: f.roiMoney),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: f.planChips
                            .map((p) => _PlanChip(label: p, color: paywallChipColorForLabel(p)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PaywallRoiRowsList extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallRoiRowsList({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final border = isDark ? EagleTokens.darkLine : line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...PaywallCatalog.roiRows.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final stacked = c.maxWidth < 340;
                final value = Text(
                  r.value,
                  style: TextStyle(
                    color: PaywallCatalog.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                );
                final chip = _PlanChip(label: r.planChip, color: r.color);
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.label, style: TokensStrip.body(color: ink)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: value),
                          chip,
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(r.label, style: TokensStrip.body(color: ink)),
                    ),
                    Expanded(flex: 2, child: value),
                    const SizedBox(width: 8),
                    chip,
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Rodapé legal compacto no fluxo de upgrade — detalhes em bottom sheet.
class PaywallUpgradeLegalCompact extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final bool showStoreBillingNote;
  final bool restoring;
  final VoidCallback? onRestore;

  const PaywallUpgradeLegalCompact({
    super.key,
    required this.ink,
    required this.mute,
    required this.primary,
    this.showStoreBillingNote = true,
    this.restoring = false,
    this.onRestore,
  });

  static Future<void> showBillingSheet(
    BuildContext context, {
    required Color ink,
    required Color mute,
    required Color primary,
    required bool showStoreBillingNote,
    required bool restoring,
    VoidCallback? onRestore,
  }) {
    final chrome = ShellChrome.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
          child: DecoratedBox(
            decoration: chrome.bottomSheet(radius: PaywallSurface.cardRadius),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Termos e cobrança',
                      style: TokensStrip.h2(color: ink).copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    PaywallTrustFooter(mute: mute, primary: primary),
                    const SizedBox(height: 16),
                    PaywallBillingLegalPanel(
                      ink: ink,
                      mute: mute,
                      showStoreBillingNote: showStoreBillingNote,
                      restoring: restoring,
                      onRestore: onRestore,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    return PaywallGlassCard(
      accent: primary,
      blur: false,
      glow: false,
      elevationLevel: 4,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Text(
            'Sem fidelidade · Cancele quando quiser',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: secondary).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Abrir termos, privacidade e informações de cobrança',
            child: TextButton.icon(
              onPressed: () => showBillingSheet(
                context,
                ink: ink,
                mute: mute,
                primary: primary,
                showStoreBillingNote: showStoreBillingNote,
                restoring: restoring,
                onRestore: onRestore,
              ),
              icon: Icon(Icons.policy_outlined, size: 18, color: primary),
              label: Text(
                'Termos, privacidade e cobrança',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painel de cobrança / restaurar (sheet ou inline).
class PaywallBillingLegalPanel extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool showStoreBillingNote;
  final bool restoring;
  final VoidCallback? onRestore;

  const PaywallBillingLegalPanel({
    super.key,
    required this.ink,
    required this.mute,
    this.showStoreBillingNote = true,
    this.restoring = false,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);

    return Column(
      children: [
        if (onRestore != null)
          TextButton(
            onPressed: restoring ? null : onRestore,
            child: Text(
              restoring ? 'Restaurando compras…' : 'Restaurar compras',
              style: TextStyle(
                fontSize: 14,
                color: ink.withValues(alpha: 0.82),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (showStoreBillingNote)
          Text(
            'Cobrança e renovação automática pela ${subscriptionChannelLabel()}. '
            'Cancele quando quiser nas configurações do dispositivo.',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: secondary),
          ),
      ],
    );
  }
}

class PaywallTrustFooter extends StatelessWidget {
  final Color mute;
  final Color primary;

  const PaywallTrustFooter({super.key, required this.mute, required this.primary});

  @override
  Widget build(BuildContext context) {
    TextStyle link() => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: primary,
      decoration: TextDecoration.underline,
    );
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return Column(
      children: [
        Text(
          'Sem fidelidade · Cancele quando quiser nas configurações do app',
          textAlign: TextAlign.center,
          style: TokensStrip.bodyMuted(color: mute),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 0,
          children: [
            Semantics(
              button: true,
              label: 'Abrir política de privacidade',
              child: TextButton(
                onPressed: () => FocuxLegal.openPrivacy(),
                style: linkStyle,
                child: Text('Privacidade (LGPD)', style: link()),
              ),
            ),
            Semantics(
              button: true,
              label: 'Abrir termos de uso',
              child: TextButton(
                onPressed: () => FocuxLegal.openTerms(),
                style: linkStyle,
                child: Text('Termos de uso', style: link()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class PaywallLoadingSkeleton extends StatelessWidget {
  const PaywallLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : EagleTokens.lineSoft;
    final highlight = isDark ? EagleTokens.darkCardHi : EagleTokens.line;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 56, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(PaywallSurface.cardRadius),
              ),
            ),
        ],
      ),
    );
  }
}

String formatPaywallPriceBrl(double value) {
  if (value == 0) return 'R\$ 0';
  final whole = value == value.roundToDouble();
  return whole
      ? 'R\$ ${value.toStringAsFixed(0)}'
      : 'R\$ ${value.toStringAsFixed(2)}';
}

String paywallMonthlyFromPlano(Plano plano) => formatPaywallPriceBrl(plano.precoMensal);

String paywallAnnualMonthlyEquiv(Plano plano) {
  final annual = plano.precoAnual ?? SubscriptionProducts.referenceAnnualPrice(plano.precoMensal);
  return formatPaywallPriceBrl(annual / 12);
}
