part of 'wallet_screen.dart';

class _WalletSectionCard extends StatelessWidget {
  const _WalletSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      container: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.inter(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: mute, fontSize: 11.5, height: 1.35),
              ),
            ],
            const SizedBox(height: TokensStrip.s3),
            child,
          ],
        ),
      ),
    );
  }
}

class _PixTipoBottomSheet extends StatelessWidget {
  const _PixTipoBottomSheet({required this.tipos, required this.selected});

  final List<String> tipos;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final surface = isDark ? EagleTokens.darkCard : TokensStrip.cardBg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, TokensStrip.s4, 16),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: surface,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, color: primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Tipo de chave PIX',
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
                ...tipos.map(
                  (tipo) => ListTile(
                    title: Text(
                      WalletPixValidation.labelForTipo(tipo),
                      style: TextStyle(
                        color: ink,
                        fontWeight:
                            selected == tipo
                                ? FontWeight.w700
                                : FontWeight.w500,
                      ),
                    ),
                    trailing:
                        selected == tipo
                            ? Icon(Icons.check_circle_rounded, color: primary)
                            : null,
                    onTap: () => Navigator.pop(context, tipo),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
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
    if (_loading) return const _ResumoMensalSkeleton();
    if (_error != null) {
      return _ResumoMensalError(message: _error!, onRetry: _load);
    }
    if (_resumo == null) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final resumo = _resumo!;
    final inadimplentes = resumo.inadimplentes;
    final percentRecebido =
        resumo.totalPrevisto <= 0
            ? 0.0
            : (resumo.totalRecebido / resumo.totalPrevisto).clamp(0.0, 1.0);
    final periodoLabel = monthYearLabelPtBr(_periodo);

    return Semantics(
      button: true,
      label:
          'Resumo financeiro de $periodoLabel. '
          'Recebido ${formatBrlCurrency(resumo.totalRecebido)}. '
          'Previsto ${formatBrlCurrency(resumo.totalPrevisto)}. '
          '$inadimplentes inadimplentes.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          onTap: () => context.push('/financeiro'),
          child: Container(
            padding: const EdgeInsets.all(TokensStrip.s4),
            decoration: fxListCardDecoration(context, accent: primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Resumo · $periodoLabel',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: mute, size: 22),
                  ],
                ),
                const SizedBox(height: TokensStrip.s3),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Recebido',
                        valor: formatBrlCurrency(resumo.totalRecebido),
                        color: EagleTokens.good,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Previsto',
                        valor: formatBrlCurrency(resumo.totalPrevisto),
                        color: primary,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Inadimplentes',
                        valor: '$inadimplentes',
                        color: inadimplentes > 0 ? EagleTokens.bad : mute,
                      ),
                    ),
                  ],
                ),
                if (resumo.totalPrevisto > 0) ...[
                  const SizedBox(height: TokensStrip.s3),
                  Semantics(
                    label:
                        '${(percentRecebido * 100).round()} por cento do previsto recebido',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: percentRecebido,
                        minHeight: 6,
                        backgroundColor: line,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(percentRecebido * 100).round()}% do previsto recebido',
                    style: TextStyle(fontSize: 12, color: mute),
                  ),
                ],
                const SizedBox(height: TokensStrip.s2),
                Text(
                  'Ver financeiro completo',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumoMensalSkeleton extends StatelessWidget {
  const _ResumoMensalSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 16, width: 160, borderRadius: 8),
          SizedBox(height: TokensStrip.s3),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 42, borderRadius: 10)),
              SizedBox(width: TokensStrip.s3),
              Expanded(child: SkeletonLoader(height: 42, borderRadius: 10)),
              SizedBox(width: TokensStrip.s3),
              Expanded(child: SkeletonLoader(height: 42, borderRadius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumoMensalError extends StatelessWidget {
  const _ResumoMensalError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mute =
        Theme.of(context).brightness == Brightness.dark
            ? EagleTokens.darkInkMute
            : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do mês',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: mute, height: 1.4)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _Stat({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: TokensStrip.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
