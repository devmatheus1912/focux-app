part of 'aluno_dashboard_screen.dart';

class _AlunoAppBarProfileMenu extends StatelessWidget {
  final Aluno aluno;
  final bool isDark;
  final VoidCallback onProfile;
  final Future<void> Function() onLogout;

  const _AlunoAppBarProfileMenu({
    required this.aluno,
    required this.isDark,
    required this.onProfile,
    required this.onLogout,
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
      child: PopupMenuButton<_AlunoHeaderAction>(
        tooltip: 'Perfil do aluno',
        offset: const Offset(0, 42),
        onSelected: (action) async {
          switch (action) {
            case _AlunoHeaderAction.profile:
              onProfile();
              break;
            case _AlunoHeaderAction.logout:
              await onLogout();
              break;
          }
        },
        itemBuilder:
            (context) => const [
              PopupMenuItem(
                value: _AlunoHeaderAction.profile,
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 10),
                    Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AlunoHeaderAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
        child: CircleAvatar(
          radius: 17,
          backgroundColor: BrandPalette.soft(primary, dark: isDark),
          backgroundImage: hasFoto ? NetworkImage(aluno.fotoUrl!.trim()) : null,
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
                brand.logoUrl != null ? NetworkImage(brand.logoUrl!) : null,
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
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final softText = onPrimary.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, BrandPalette.deep(primary)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.16 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  action.eyebrow,
                  style: TextStyle(
                    color: softText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.verified_outlined, color: softText, size: 18),
              const SizedBox(width: 6),
              Text(
                'Focux ${score.value}',
                style: TextStyle(
                  color: softText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            action.title,
            style: TextStyle(
              color: onPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 7),
          Text(
            action.description,
            style: TextStyle(color: softText, fontSize: 12.5, height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed:
                      () =>
                          context.push(action.route, extra: action.routeExtra),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    action.cta,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _WorkoutMetricPill(
                value: '${score.value}',
                label: 'score',
                onPrimary: onPrimary,
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
                onPrimary: onPrimary,
              ),
              _WorkoutInsightPill(
                icon: Icons.person_pin_circle_outlined,
                label: score.riskLabel,
                onPrimary: onPrimary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _HomeNarrativeRail(
            items: experience.narratives,
            onPrimary: onPrimary,
          ),
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

class _WorkoutMetricPill extends StatelessWidget {
  final String value;
  final String label;
  final Color onPrimary;

  const _WorkoutMetricPill({
    required this.value,
    required this.label,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: onPrimary.withValues(alpha: 0.68),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
        color: Colors.white.withValues(alpha: 0.10),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, height: 1.15),
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
  final bool isDark;

  const _PerformanceEvolutionCard({
    required this.historicoAsync,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: fxListCardDecoration(context, accent: primary),
      child: historicoAsync.when(
        loading: () => const SizedBox(height: 96, child: FxLoading()),
        error:
            (_, __) => Text(
              'Sua evolução de performance vai aparecer aqui assim que o histórico carregar.',
              style: TextStyle(color: mute, height: 1.45),
            ),
        data: (historico) {
          final treinosConcluidos =
              historico
                  .where((treino) => treino.status == 'CONCLUIDO')
                  .toList();
          final ultimaEvolucao = _ultimaEvolucao(treinosConcluidos);
          final volumeSemana = _volumePeriodo(
            treinosConcluidos,
            _inicioSemana(),
          );
          final volumeMes = _volumePeriodo(treinosConcluidos, _inicioMes());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.emoji_events_outlined, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evolução real',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ultimaEvolucao == null
                              ? 'Registre as séries para o app enxergar carga, repetições e volume.'
                              : ultimaEvolucao.mensagem,
                          style: TextStyle(color: mute, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Último PR',
                      value:
                          ultimaEvolucao == null
                              ? '--'
                              : _labelEvolucao(ultimaEvolucao.tipo),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Volume semana',
                      value: _fmtVolume(volumeSemana),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Volume mês',
                      value: _fmtVolume(volumeMes),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (ultimaEvolucao != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : BrandPalette.softer(primary),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${ultimaEvolucao.exercicioNome}: ${_fmtValor(ultimaEvolucao.valorAnterior, ultimaEvolucao.unidade)} -> ${_fmtValor(ultimaEvolucao.valorAtual, ultimaEvolucao.unidade)}'
                    '${ultimaEvolucao.percentual == null ? '' : ' (+${ultimaEvolucao.percentual}%)'}',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  EvolucaoPerformance? _ultimaEvolucao(List<ExecucaoTreino> historico) {
    for (final treino in historico) {
      if (treino.evolucoesPerformance.isNotEmpty) {
        return treino.evolucoesPerformance.first;
      }
      if (treino.evolucoesCarga.isNotEmpty) {
        final item = treino.evolucoesCarga.first;
        return EvolucaoPerformance(
          tipo: 'CARGA',
          exercicioId: item.exercicioId,
          exercicioNome: item.exercicioNome,
          valorAnterior: item.cargaAnteriorKg,
          valorAtual: item.cargaAtualKg,
          diferenca: item.diferencaKg,
          percentual: item.percentual,
          unidade: 'kg',
          mensagem: item.mensagem,
        );
      }
    }
    return null;
  }

  double _volumePeriodo(List<ExecucaoTreino> historico, DateTime inicio) {
    return historico
        .where((treino) {
          final data = _dataTreino(treino);
          return data != null && !data.isBefore(inicio);
        })
        .fold<double>(0, (total, treino) => total + _volumeTreino(treino));
  }

  double _volumeTreino(ExecucaoTreino treino) {
    var total = 0.0;
    for (final exercicio in treino.exercicios) {
      for (final serie in exercicio.seriesDetalhes) {
        final reps = _primeiroNumero(serie.repeticoes);
        final carga = serie.cargaKg;
        if (reps != null && carga != null) {
          total += carga * reps;
        }
      }
    }
    return total;
  }

  DateTime? _dataTreino(ExecucaoTreino treino) {
    return DateTime.tryParse(treino.concluidoEm ?? treino.iniciadoEm ?? '');
  }

  DateTime _inicioSemana() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  DateTime _inicioMes() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  int? _primeiroNumero(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  String _labelEvolucao(String tipo) {
    switch (tipo) {
      case 'REPETICOES':
        return 'Repetições';
      case 'VOLUME':
        return 'Volume';
      default:
        return 'Carga';
    }
  }

  String _fmtVolume(double value) {
    if (value <= 0) return '--';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}t';
    return '${value.toStringAsFixed(0)}kg';
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
