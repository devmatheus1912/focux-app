part of 'anamnese_screen.dart';

class _AnamneseBody extends StatefulWidget {
  const _AnamneseBody({
    required this.anamnese,
    required this.acting,
    required this.isDark,
    required this.primary,
    required this.alunoId,
    required this.secao,
    required this.onSecao,
    required this.onRevisar,
  });

  final Anamnese anamnese;
  final bool acting;
  final bool isDark;
  final Color primary;
  final int alunoId;
  final String secao;
  final ValueChanged<String> onSecao;
  final Future<void> Function({
    required String status,
    required String title,
    required String confirmLabel,
    String? subtitle,
    bool pedirAtestado,
  })
  onRevisar;

  @override
  State<_AnamneseBody> createState() => _AnamneseBodyState();
}

class _AnamneseBodyState extends State<_AnamneseBody> {
  var _fichaExpanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.anamnese;
    final isDark = widget.isDark;
    final primary = widget.primary;
    final acting = widget.acting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: TokensStrip.s3),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            if (!a.isNaoIniciada && !a.isSolicitada)
              DashboardHomeActionChip(
                label: 'Pedir atestado',
                accent: primary,
                isDark: isDark,
                enabled: !acting,
                onPressed:
                    () => widget.onRevisar(
                      status: AnamneseStatus.precisaAtestado,
                      title: 'Pedir atestado',
                      subtitle:
                          'Oriente o aluno sobre o que o atestado deve cobrir.',
                      confirmLabel: 'Pedir atestado',
                      pedirAtestado: true,
                    ),
              ),
            if (a.isPreenchida || a.isPrecisaAtestado)
              DashboardHomeActionChip(
                label: 'Pedir atualização',
                accent: primary,
                isDark: isDark,
                enabled: !acting,
                onPressed:
                    () => widget.onRevisar(
                      status: AnamneseStatus.solicitada,
                      title: 'Pedir atualização',
                      subtitle:
                          'O aluno será notificado para atualizar a ficha.',
                      confirmLabel: 'Pedir atualização',
                    ),
              ),
            DashboardHomeActionChip(
              label: 'Chat',
              accent: primary,
              isDark: isDark,
              onPressed: () => context.push('/alunos/${widget.alunoId}/chat'),
            ),
          ],
        ),
        if (a.alertas.isNotEmpty || a.parqPositivo == true) ...[
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              if (a.parqPositivo == true)
                _AlertaChip(
                  label: 'PAR-Q+ positivo',
                  isDark: isDark,
                  warn: true,
                ),
              if (a.alertas.length == 1)
                _AlertaChip(
                  label: a.alertas.first,
                  isDark: isDark,
                  warn: true,
                )
              else if (a.alertas.length > 1)
                _AlertaChip(
                  label: '${a.alertas.length} alertas clínicos',
                  isDark: isDark,
                  warn: true,
                ),
            ],
          ),
        ],
        if (a.isNaoIniciada) ...[
          const SizedBox(height: TokensStrip.s5),
          // CTA único no sticky S3 — empty sem action (§11 / §13).
          const FxEmptyState(
            icon: 'article',
            title: 'Nenhuma ficha ainda',
            subtitle: 'O aluno preenche a anamnese. Você solicita e revisa.',
            quiet: true,
          ),
        ] else if (a.isSolicitada && !a.personalPodeRevisar) ...[
          const SizedBox(height: TokensStrip.s5),
          const FxEmptyState(
            icon: 'calendar',
            title: 'Aguardando preenchimento',
            subtitle:
                'O aluno foi notificado. Quando enviar, você revisa aqui.',
            quiet: true,
          ),
        ] else if (a.personalPodeRevisar) ...[
          const SizedBox(height: TokensStrip.s3),
          _FichaDisclosureToggle(
            expanded: _fichaExpanded,
            primary: primary,
            onToggle: () => setState(() => _fichaExpanded = !_fichaExpanded),
          ),
          if (_fichaExpanded) ...[
            const SizedBox(height: TokensStrip.s3),
            AlunoSegmentedChoice(
              options: anamneseDetalheSecoes,
              selected: widget.secao,
              isDark: isDark,
              onSelect: widget.onSecao,
            ),
            const SizedBox(height: TokensStrip.s3),
            _AnamneseFicha(anamnese: a, secao: widget.secao),
          ],
        ],
      ],
    );
  }
}

class _FichaDisclosureToggle extends StatelessWidget {
  const _FichaDisclosureToggle({
    required this.expanded,
    required this.primary,
    required this.onToggle,
  });

  final bool expanded;
  final Color primary;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensStrip.s3,
            vertical: TokensStrip.s3,
          ),
          decoration: fxListCardDecoration(
            context,
            accent: primary,
            radius: TokensStrip.rCard,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expanded ? 'Ocultar detalhes' : 'Ver detalhes da ficha',
                      style: FocuxHubTypography.body(color: ink).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expanded
                          ? 'PAR-Q+, saúde, hábitos e treino'
                          : 'Resumo no fold · toque para abrir a ficha',
                      style: FocuxHubTypography.chip(mute),
                    ),
                  ],
                ),
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnamneseFicha extends StatelessWidget {
  const _AnamneseFicha({required this.anamnese, required this.secao});

  final Anamnese anamnese;
  final String secao;

  @override
  Widget build(BuildContext context) {
    final a = anamnese;
    final rows = switch (secao) {
      anamneseSecaoSaude => [
        ('Histórico médico', anamneseTextOrDash(a.historicoMedico)),
        ('Cirurgias', anamneseTextOrDash(a.cirurgias)),
        ('Dores crônicas', anamneseTextOrDash(a.doresCronicas)),
        ('Lesões / limitações', anamneseTextOrDash(a.lesoes)),
        ('Medicamentos', anamneseTextOrDash(a.medicamentos)),
        ('Alergias', anamneseTextOrDash(a.alergias)),
        ('Gestação / pós-parto', anamneseTextOrDash(a.gestacaoPosParto)),
        ('Histórico familiar CV', anamneseBoolLabel(a.historicoFamiliarCv)),
        ('Sintomas CV', anamneseTextOrDash(a.sintomasCv)),
      ],
      anamneseSecaoHabitos => [
        ('Sono', anamneseSonoHorasLabel(a.sonoHoras)),
        ('Qualidade do sono', anamneseTextOrDash(a.qualidadeSono)),
        ('Nível de estresse', anamneseTextOrDash(a.nivelEstresse)),
        ('Tabagismo', anamneseTextOrDash(a.tabagismo)),
        ('Álcool', anamneseTextOrDash(a.alcool)),
        ('Observações', anamneseTextOrDash(a.observacoes)),
        ('Notas', anamneseTextOrDash(a.notasProfissional)),
        ('Atestado', anamneseTextOrDash(a.atestadoObs)),
      ],
      anamneseSecaoTreino => [
        ('Objetivo', anamneseTextOrDash(a.objetivo)),
        ('Objetivo detalhado', anamneseTextOrDash(a.objetivoDetalhado)),
        (
          'Disponibilidade',
          a.disponibilidadeSemanal == null
              ? '—'
              : anamneseDisponibilidadeLabel(a.disponibilidadeSemanal!),
        ),
        ('Preferências de treino', anamneseTextOrDash(a.preferenciasTreino)),
        ('Restrições alimentares', anamneseTextOrDash(a.restricoesAlimentares)),
        ('Histórico de atividade', anamneseTextOrDash(a.historicoAtividade)),
        ('Motivo de interrupções', anamneseTextOrDash(a.motivoInterrupcoes)),
        ('Motivação atual', anamneseTextOrDash(a.motivacaoAtual)),
        ('Algo mais', anamneseTextOrDash(a.algoMais)),
      ],
      _ => [
        for (final q in anamneseParqPerguntas)
          (q.label, anamneseBoolLabel(anamneseParqValue(a, q.key))),
        if ((a.parqOutraRazaoDetalhe ?? '').trim().isNotEmpty)
          ('Detalhe (outra razão)', a.parqOutraRazaoDetalhe!.trim()),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          anamneseSecaoTitle(secao),
          style: FocuxHubTypography.sectionTitle(
            context,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: TokensStrip.s2),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: fxListCardDecoration(
            context,
            accent: Theme.of(context).colorScheme.primary,
            radius: TokensStrip.rCard,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == rows.length - 1 ? 0 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          rows[i].$1,
                          style: FocuxHubTypography.chip(
                            Theme.of(context).hintColor,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rows[i].$2,
                          style: FocuxHubTypography.body(
                            color: Theme.of(context).colorScheme.onSurface,
                          ).copyWith(fontWeight: FontWeight.w600, height: 1.3),
                        ),
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

class _AlertaChip extends StatelessWidget {
  const _AlertaChip({
    required this.label,
    required this.isDark,
    this.warn = false,
  });

  final String label;
  final bool isDark;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = warn ? EagleTokens.warn : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s3,
        vertical: TokensStrip.s2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
