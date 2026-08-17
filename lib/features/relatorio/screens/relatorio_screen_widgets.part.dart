part of 'relatorio_screen.dart';

class _SeletorPeriodo extends StatelessWidget {
  final int diasSelecionado;
  final DateTimeRange? rangeCustom;
  final ValueChanged<int> onChanged;
  final VoidCallback onCustom;

  const _SeletorPeriodo({
    required this.diasSelecionado,
    required this.rangeCustom,
    required this.onChanged,
    required this.onCustom,
  });

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isCustom = rangeCustom != null;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: primary),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de análise',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: TokensStrip.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _PeriodPill(
                  label: '7d',
                  active: !isCustom && diasSelecionado == 7,
                  onTap: () => onChanged(7),
                ),
                _PeriodPill(
                  label: '30d',
                  active: !isCustom && diasSelecionado == 30,
                  onTap: () => onChanged(30),
                ),
                _PeriodPill(
                  label: '3m',
                  active: !isCustom && diasSelecionado == 90,
                  onTap: () => onChanged(90),
                ),
                _PeriodPill(
                  label: '6m',
                  active: !isCustom && diasSelecionado == 180,
                  onTap: () => onChanged(180),
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    isCustom
                        ? '${_fmtDate(rangeCustom!.start)} – ${_fmtDate(rangeCustom!.end)}'
                        : 'Personalizado',
                  ),
                  backgroundColor:
                      isCustom
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                  onPressed: onCustom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              active
                  ? primary
                  : (isDark
                      ? EagleTokens.darkCardHi
                      : TokensStrip.borderDefault),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                active
                    ? primary
                    : (isDark
                        ? EagleTokens.darkLine
                        : TokensStrip.borderDefault),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : ink,
          ),
        ),
      ),
    );
  }
}

class _CardAderencia extends StatelessWidget {
  final AderenciaData dados;
  final int alunoId;
  final String alunoNome;

  const _CardAderencia({
    required this.dados,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final taxa = dados.taxaAderenciaPercent.clamp(0.0, 100.0);
    final showCheckinCta = taxa < 50;
    final firstName = satelliteFirstName(alunoNome, fallback: 'aluno');
    final cor =
        taxa >= 75
            ? EagleTokens.good
            : taxa >= 50
            ? EagleTokens.warn
            : theme.colorScheme.error;

    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: cor),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s5),
        child: Column(
          children: [
            Text('Taxa de Aderência', style: theme.textTheme.titleMedium),
            const SizedBox(height: TokensStrip.s5),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _AderenciaRingPainter(
                      fraction: taxa / 100,
                      color: cor,
                      trackColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? EagleTokens.darkLine
                              : TokensStrip.borderDefault,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${taxa.toInt()}%',
                        style: AppTypography.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: cor,
                        ),
                      ),
                      Text(
                        _labelAderencia(taxa),
                        style: theme.textTheme.bodySmall?.copyWith(color: cor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showCheckinCta) ...[
              const SizedBox(height: TokensStrip.s4),
              Text(
                taxa <= 0
                    ? 'Nenhum check-in no período — vale retomar contato com $firstName.'
                    : 'Aderência abaixo do ideal — reforce o hábito de check-in.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      () => showAlunoCheckinMessageSheet(
                        context,
                        alunoId: alunoId,
                        alunoNome: alunoNome,
                      ),
                  icon: const Icon(Icons.message_outlined, size: 16),
                  label: const Text('Pedir check-in'),
                  style: Aluno360Layout.operacaoOutlinedButtonStyle(
                    context,
                    primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _labelAderencia(double taxa) {
    if (taxa >= 75) return 'Excelente';
    if (taxa >= 50) return 'Regular';
    return 'Baixa';
  }
}

class _AderenciaRingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  const _AderenciaRingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const r = 54.0;
    const sw = 14.0;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = trackColor
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AderenciaRingPainter old) =>
      old.fraction != fraction || old.trackColor != trackColor;
}

class _CardInfo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final Color cor;

  const _CardInfo({
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: cor),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: TokensStrip.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardComparativo extends StatelessWidget {
  final ComparativoPeriodo comparativo;

  const _CardComparativo({required this.comparativo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = comparativo.deltaPercent;
    final isPositivo = delta >= 0;
    final deltaColor = isPositivo ? EagleTokens.good : EagleTokens.bad;
    final deltaIcon = isPositivo ? Icons.arrow_upward : Icons.arrow_downward;
    final deltaText =
        isPositivo
            ? '+${delta.toStringAsFixed(1)}%'
            : '${delta.toStringAsFixed(1)}%';

    final primaryAccent = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: fxListCardDecoration(context, accent: primaryAccent),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'vs. período anterior',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Este período',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comparativo.aderenciaAtual.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${comparativo.checkInsAtual} check-ins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(deltaIcon, color: deltaColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        deltaText,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Anterior',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comparativo.aderenciaAnterior.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                    Text(
                      '${comparativo.checkInsAnterior} check-ins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
