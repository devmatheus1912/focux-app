part of 'aluno_dashboard_screen.dart';

class _AlunoAppBarProfileMenu extends StatelessWidget {
  final Aluno aluno;
  final bool isDark;
  final VoidCallback onProfile;

  const _AlunoAppBarProfileMenu({
    required this.aluno,
    required this.isDark,
    required this.onProfile,
  });

  String _initials(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1 || parts[1].isEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasFoto = aluno.fotoUrl != null && aluno.fotoUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        button: true,
        label: 'Perfil do aluno',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onProfile,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: BrandPalette.soft(primary, dark: isDark),
            backgroundImage:
                hasFoto
                    ? fxCachedNetworkImageProvider(
                      aluno.fotoUrl!.trim(),
                      maxWidth: 72,
                    )
                    : null,
            child:
                hasFoto
                    ? null
                    : Text(
                      _initials(aluno.nome),
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _AlunoHeroCard extends StatelessWidget {
  final Aluno aluno;
  final PersonalBrand brand;
  final bool isDark;

  const _AlunoHeroCard({
    required this.aluno,
    required this.brand,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final slogan =
        brand.slogan?.trim().isNotEmpty == true
            ? brand.slogan!
            : 'Seu treino organizado para hoje.';
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: BrandPalette.soft(primary, dark: isDark),
            backgroundImage:
                brand.logoUrl != null
                    ? fxCachedNetworkImageProvider(
                      brand.logoUrl!,
                      maxWidth: 72,
                    )
                    : null,
            child:
                brand.logoUrl == null
                    ? Text(
                      brand.nomePersonal.isNotEmpty
                          ? brand.nomePersonal[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.nomePersonal,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  slogan,
                  style: TextStyle(color: mute, fontSize: 11.4, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                if (aluno.objetivo?.trim().isNotEmpty == true)
                  _HeroPill(
                    icon: Icons.flag_outlined,
                    value: aluno.objetivo!,
                    isDark: isDark,
                  )
                else
                  _HeroPill(
                    icon: Icons.verified_outlined,
                    value: 'Ativo',
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _HeroPill({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: BrandPalette.soft(primary, dark: isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 14),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  final AlunoHomeExperience experience;
  final bool isDark;

  const _TodayFocusCard({required this.experience, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final action = experience.action;
    final score = experience.score;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return FxStripCard(
      emphasize: true,
      glowStrength: 0.08,
      semanticsLabel:
          '${action.title}. Score ${score.value}. ${action.description}. ${action.cta}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.eyebrow, style: FocuxHubTypography.chip(mute)),
                    const SizedBox(height: 8),
                    Text(
                      action.title,
                      style: FocuxHubTypography.pageTitle(context, color: ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.description,
                      style: FocuxHubTypography.bodyMuted(color: mute),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  RecoveryScoreRing(
                    score: score.value,
                    color: primary,
                    size: 72,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seu score',
                    style: FocuxHubTypography.chip(mute).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WorkoutInsightPill(
                icon: Icons.trending_up_rounded,
                label: score.rhythmLabel,
                onPrimary: mute,
              ),
              _WorkoutInsightPill(
                icon: Icons.person_pin_circle_outlined,
                label: score.riskLabel,
                onPrimary: mute,
              ),
              if (score.nextSignal.trim().isNotEmpty)
                _WorkoutInsightPill(
                  icon: Icons.bolt_rounded,
                  label: score.nextSignal,
                  onPrimary: primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          DashboardHomeActionChip(
            label: action.cta,
            accent: primary,
            isDark: isDark,
            onPressed:
                () => context.push(action.route, extra: action.routeExtra),
          ),
          const SizedBox(height: 10),
          _HomeNarrativeRail(items: experience.narratives, onPrimary: mute),
        ],
      ),
    );
  }
}

class _HomeNarrativeRail extends StatelessWidget {
  final List<String> items;
  final Color onPrimary;

  const _HomeNarrativeRail({required this.items, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final visibleItems = items.take(3).toList(growable: false);
    return Column(
      children: [
        for (var i = 0; i < visibleItems.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visibleItems[i],
                  style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.78),
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (i != visibleItems.length - 1) const SizedBox(height: 5),
        ],
      ],
    );
  }
}

class _WorkoutInsightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color onPrimary;

  const _WorkoutInsightPill({
    required this.icon,
    required this.label,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onPrimary.withValues(alpha: 0.82), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: onPrimary.withValues(alpha: 0.82),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: FocuxHubTypography.cardTitle(
              color: Theme.of(context).colorScheme.onSurface,
            ).copyWith(height: 1.05),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FocuxHubTypography.chip(
              Theme.of(context).colorScheme.onSurfaceVariant,
            ).copyWith(height: 1.15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PerformanceEvolutionCard extends StatelessWidget {
  final AsyncValue<List<ExecucaoTreino>> historicoAsync;
  final double volumeSemanaKg;
  final double volumeMesKg;
  final List<double> volumePorSemana;
  final List<double> forcaPorSemana;
  final List<RecordePessoal> recordes;
  final FocuxScore score;
  final bool isDark;

  const _PerformanceEvolutionCard({
    required this.historicoAsync,
    required this.volumeSemanaKg,
    required this.volumeMesKg,
    required this.volumePorSemana,
    required this.forcaPorSemana,
    required this.score,
    required this.isDark,
    this.recordes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: historicoAsync.when(
        loading: () => const SizedBox(height: 120, child: FxLoading()),
        error:
            (_, __) => Text(
              'Sua evolução de performance vai aparecer aqui assim que o histórico carregar.',
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
        data: (historico) {
          final ultimoRecorde = recordes.isEmpty ? null : recordes.first;
          final view = buildAlunoPerformanceEvolutionView(
            score: score,
            historico: historico,
            volumeSemanaKg: volumeSemanaKg,
            volumeMesKg: volumeMesKg,
            volumePorSemana: volumePorSemana,
            forcaPorSemana: forcaPorSemana,
            ultimoRecordeLabel:
                ultimoRecorde == null ? null : _fmtRecorde(ultimoRecorde),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecoveryScoreRing(
                    score: view.score,
                    color: primary,
                    size: 80,
                  ),
                  const SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seu score Focux',
                          style: FocuxHubTypography.chip(mute),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${view.score} · ${view.scoreLabel}',
                          style: FocuxHubTypography.cardTitle(color: ink)
                              .copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          view.insight,
                          style: FocuxHubTypography.bodyMuted(color: mute),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (score.nextSignal.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            score.nextSignal,
                            style: FocuxHubTypography.bodyMuted(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ).copyWith(fontSize: 12.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (view.hasChart) ...[
                const SizedBox(height: TokensStrip.s4),
                Text(
                  'Evolução do treino',
                  style: FocuxHubTypography.chip(mute),
                ),
                const SizedBox(height: TokensStrip.s2),
                _DualTrendChart(
                  volume: view.volumePorSemana,
                  forca: view.forcaPorSemana,
                  volumeColor: primary,
                  forcaColor: EagleTokens.good,
                ),
                const SizedBox(height: TokensStrip.s2),
                Row(
                  children: [
                    _LegendDot(color: primary, label: 'Volume'),
                    const SizedBox(width: TokensStrip.s3),
                    _LegendDot(color: EagleTokens.good, label: 'Força'),
                  ],
                ),
              ],
              const SizedBox(height: TokensStrip.s4),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Último PR',
                      value: view.ultimoPrLabel,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Volume semana',
                      value: formatAlunoVolumeKg(view.volumeSemanaKg),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Volume mês',
                      value: formatAlunoVolumeKg(view.volumeMesKg),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (view.ultimaEvolucao != null) ...[
                const SizedBox(height: TokensStrip.s3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TokensStrip.s3),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : BrandPalette.softer(primary),
                    borderRadius: BorderRadius.circular(TokensStrip.rMd),
                  ),
                  child: Text(
                    '${view.ultimaEvolucao!.exercicioNome}: '
                    '${_fmtValor(view.ultimaEvolucao!.valorAnterior, view.ultimaEvolucao!.unidade)}'
                    ' → ${_fmtValor(view.ultimaEvolucao!.valorAtual, view.ultimaEvolucao!.unidade)}'
                    '${view.ultimaEvolucao!.percentual == null ? '' : ' (+${view.ultimaEvolucao!.percentual}%)'}',
                    style: FocuxHubTypography.body(
                      color: ink,
                    ).copyWith(fontWeight: FontWeight.w700, height: 1.35),
                  ),
                ),
              ],
              const SizedBox(height: TokensStrip.s3),
              Align(
                alignment: Alignment.centerLeft,
                child: DashboardHomeActionChip(
                  label: 'Treinar agora e subir o score',
                  accent: primary,
                  isDark: isDark,
                  onPressed: () => context.push('/checkin/treinos'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmtRecorde(RecordePessoal recorde) {
    final carga = recorde.cargaKg;
    if (carga == null || carga <= 0) return recorde.exercicioNome;
    final formatted =
        carga == carga.roundToDouble()
            ? carga.toStringAsFixed(0)
            : carga.toStringAsFixed(1);
    return '${formatted}kg';
  }

  String _fmtValor(double value, String unidade) {
    final formatted =
        value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1);
    if (unidade.isEmpty) return formatted;
    return '$formatted $unidade';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: FocuxHubTypography.chip(mute)),
      ],
    );
  }
}

class _DualTrendChart extends StatelessWidget {
  final List<double> volume;
  final List<double> forca;
  final Color volumeColor;
  final Color forcaColor;

  const _DualTrendChart({
    required this.volume,
    required this.forca,
    required this.volumeColor,
    required this.forcaColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      width: double.infinity,
      child: CustomPaint(
        painter: _DualTrendPainter(
          volume: volume,
          forca: forca,
          volumeColor: volumeColor,
          forcaColor: forcaColor,
        ),
      ),
    );
  }
}

class _DualTrendPainter extends CustomPainter {
  final List<double> volume;
  final List<double> forca;
  final Color volumeColor;
  final Color forcaColor;

  _DualTrendPainter({
    required this.volume,
    required this.forca,
    required this.volumeColor,
    required this.forcaColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintSeries(canvas, size, forca, forcaColor, strokeWidth: 2);
    _paintSeries(canvas, size, volume, volumeColor, strokeWidth: 2.4);
  }

  void _paintSeries(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color, {
    required double strokeWidth,
  }) {
    if (data.isEmpty || data.every((v) => v <= 0)) return;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final span = (maxVal - minVal).abs() < 0.001 ? 1.0 : (maxVal - minVal);
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : i * size.width / (data.length - 1);
      final norm = (data[i] - minVal) / span;
      final y = size.height - (norm * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DualTrendPainter oldDelegate) {
    return oldDelegate.volume != volume ||
        oldDelegate.forca != forca ||
        oldDelegate.volumeColor != volumeColor ||
        oldDelegate.forcaColor != forcaColor;
  }
}
