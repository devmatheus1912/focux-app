part of 'relatorio_global_screen.dart';

class _ReportContent extends StatelessWidget {
  final ResumoGlobal dados;
  final Future<void> Function() onRefresh;

  const _ReportContent({required this.dados, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final alunosUnicos =
        <int, ResumoAluno>{
          for (final aluno in [
            ...dados.maisComprometidos,
            ...dados.menosComprometidos,
          ])
            aluno.alunoId: aluno,
        }.values.toList();
    final totalPrescritos = alunosUnicos.fold<int>(
      0,
      (sum, aluno) => sum + aluno.totalTreinos,
    );
    final totalConcluidos = alunosUnicos.fold<int>(
      0,
      (sum, aluno) => sum + aluno.treinosConcluidos,
    );
    final alunosComTreino =
        alunosUnicos.where((aluno) => aluno.totalTreinos > 0).length;

    return FxContentWidthLimiter(
      maxWidth: 800,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 12, 16, 32),
          children: [
            _HeroCard(dados: dados),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Check-ins',
                    value: '$totalConcluidos',
                    tone: EagleTokens.good,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.fitness_center_rounded,
                    label: 'Prescritos',
                    value: '$totalPrescritos',
                    tone: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetricTile(
              icon: Icons.group_rounded,
              label: 'Alunos com treino ativo',
              value: '$alunosComTreino de ${dados.totalAlunos}',
              tone: EagleTokens.warn,
            ),
            const SizedBox(height: TokensStrip.s5),
            const _SectionHeader(
              icon: Icons.workspace_premium_rounded,
              title: 'Mais comprometidos',
              subtitle: 'Alunos com melhor aderencia registrada.',
              color: EagleTokens.good,
            ),
            const SizedBox(height: 10),
            if (dados.maisComprometidos.isEmpty)
              const FxEmptyState(
                icon: 'users',
                title: 'Ainda não há treinos concluídos',
                subtitle: 'O ranking aparece quando os alunos concluírem treinos.',
              )
            else
              ...dados.maisComprometidos
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) => _AlunoRankCard(
                      aluno: entry.value,
                      posicao: entry.key + 1,
                      tipo: _TipoRank.top,
                    ),
                  ),
            const SizedBox(height: TokensStrip.s5),
            const _SectionHeader(
              icon: Icons.report_problem_rounded,
              title: 'Precisam de atencao',
              subtitle: 'Priorize contato e ajuste de prescricao.',
              color: EagleTokens.bad,
            ),
            const SizedBox(height: 10),
            if (dados.menosComprometidos.isEmpty)
              const FxEmptyState(
                icon: 'activity',
                title: 'Nenhum aluno em risco',
                subtitle: 'Ninguém precisa de atenção extra neste recorte.',
              )
            else
              ...dados.menosComprometidos
                  .take(5)
                  .map(
                    (aluno) => _AlunoRankCard(
                      aluno: aluno,
                      posicao: -1,
                      tipo: _TipoRank.atencao,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final ResumoGlobal dados;

  const _HeroCard({required this.dados});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final aderencia = dados.aderenciaMediaGeral.clamp(0, 100).toDouble();
    final status =
        aderencia >= 75
            ? 'Base saudavel'
            : aderencia >= 50
            ? 'Acompanhar de perto'
            : 'Acao imediata';

    return Container(
      decoration: BoxDecoration(
        gradient: EagleTokens.heroGradient(dark: isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: dashboardHeroCaptionOnTeal().withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: dashboardHeroCaptionOnTeal(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance da base',
                      style: dashboardHeroMutedOnTealStyle(
                        fontWeight: FontWeight.w800,
                      ).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aderencia media geral',
                      style: dashboardHeroCaptionOnTealStyle().copyWith(
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              _HeroPill(text: status),
            ],
          ),
          const SizedBox(height: TokensStrip.s5),
          Text(
            '${aderencia.toStringAsFixed(1)}%',
            style: dashboardHeroMutedOnTealStyle(
              fontWeight: FontWeight.w900,
            ).copyWith(fontSize: 52, height: 0.95),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: aderencia / 100,
              minHeight: 8,
              backgroundColor: dashboardHeroCaptionOnTeal().withValues(
                alpha: 0.18,
              ),
              valueColor: AlwaysStoppedAnimation(dashboardHeroCaptionOnTeal()),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: dashboardHeroMutedOnTeal(),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${dados.totalAlunos} alunos monitorados',
                style: dashboardHeroCaptionOnTealStyle(
                  fontWeight: FontWeight.w700,
                ).copyWith(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String text;

  const _HeroPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dashboardHeroCaptionOnTeal().withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dashboardHeroCaptionOnTeal().withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        text,
        style: dashboardHeroCaptionOnTealStyle(
          fontWeight: FontWeight.w800,
        ).copyWith(fontSize: 11),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context, accent: tone, radius: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: tone, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chrome.mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chrome.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: chrome.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: chrome.mute,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TipoRank { top, atencao }

class _AlunoRankCard extends StatelessWidget {
  final ResumoAluno aluno;
  final int posicao;
  final _TipoRank tipo;

  const _AlunoRankCard({
    required this.aluno,
    required this.posicao,
    required this.tipo,
  });

  double get _aderencia {
    if (aluno.totalTreinos == 0) return 0;
    return (aluno.treinosConcluidos / aluno.totalTreinos) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final aderencia = _aderencia.clamp(0, 100).toDouble();
    final tone =
        tipo == _TipoRank.top
            ? EagleTokens.aderenciaColor(aderencia, isDark: isDark)
            : EagleTokens.bad;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context, accent: tone, radius: 18),
      child: Row(
        children: [
          _RankBadge(posicao: posicao, tipo: tipo, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        aluno.alunoNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chrome.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                    _PercentBadge(value: aderencia, tone: tone),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${aluno.treinosConcluidos} de ${aluno.totalTreinos} treinos concluidos',
                  style: TextStyle(
                    color: chrome.mute,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: aderencia / 100,
                    minHeight: 6,
                    backgroundColor: chrome.line,
                    valueColor: AlwaysStoppedAnimation(tone),
                  ),
                ),
                if (aluno.ultimoTreino != null &&
                    aluno.ultimoTreino!.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Ultimo: ${aluno.ultimoTreino}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chrome.mute,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int posicao;
  final _TipoRank tipo;
  final Color tone;

  const _RankBadge({
    required this.posicao,
    required this.tipo,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final icon =
        tipo == _TipoRank.atencao
            ? Icons.priority_high_rounded
            : Icons.military_tech_rounded;
    final text = tipo == _TipoRank.atencao ? null : '$posicao';
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: tone, size: 21),
          if (text != null)
            Positioned(
              right: 8,
              bottom: 6,
              child: Text(
                text,
                style: TextStyle(
                  color: tone,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final double value;
  final Color tone;

  const _PercentBadge({required this.value, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${value.toStringAsFixed(0)}%',
        style: TextStyle(
          color: tone,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
