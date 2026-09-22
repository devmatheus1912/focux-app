part of 'anamnese_screen.dart';

class _AnamneseBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final a = anamnese;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: TokensStrip.s4),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            DashboardHomeActionChip(
              label: 'Lista',
              accent: primary,
              isDark: isDark,
              onPressed: () => safePopOrGo(context, '/alunos/$alunoId'),
            ),
            DashboardHomeActionChip(
              label: 'Evolução',
              accent: primary,
              isDark: isDark,
              onPressed: () => context.push('/alunos/$alunoId/evolucao'),
            ),
            DashboardHomeActionChip(
              label: 'Chat',
              accent: primary,
              isDark: isDark,
              onPressed: () => context.push('/alunos/$alunoId/chat'),
            ),
            if (!a.isNaoIniciada && !a.isSolicitada)
              DashboardHomeActionChip(
                label: 'Pedir atestado',
                accent: primary,
                isDark: isDark,
                enabled: !acting,
                onPressed:
                    () => onRevisar(
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
                    () => onRevisar(
                      status: AnamneseStatus.solicitada,
                      title: 'Pedir atualização',
                      subtitle:
                          'O aluno será notificado para atualizar a ficha.',
                      confirmLabel: 'Pedir atualização',
                    ),
              ),
          ],
        ),
        if (a.alertas.isNotEmpty) ...[
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              for (final alerta in a.alertas)
                _AlertaChip(label: alerta, isDark: isDark, warn: true),
              if (a.parqPositivo == true)
                _AlertaChip(
                  label: 'PAR-Q+ positivo',
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
          ),
        ] else if (a.isSolicitada && !a.personalPodeRevisar) ...[
          const SizedBox(height: TokensStrip.s5),
          const FxEmptyState(
            icon: 'calendar',
            title: 'Aguardando preenchimento',
            subtitle:
                'O aluno foi notificado. Quando enviar, você revisa aqui.',
          ),
        ] else if (a.personalPodeRevisar) ...[
          const SizedBox(height: TokensStrip.s4),
          AlunoSegmentedChoice(
            options: anamneseDetalheSecoes,
            selected: secao,
            isDark: isDark,
            onSelect: onSecao,
          ),
          const SizedBox(height: TokensStrip.s3),
          _AnamneseFicha(anamnese: a, secao: secao),
        ],
      ],
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
      children: [
        for (final row in rows)
          FxSatelliteListTile(
            title: row.$1,
            titleCase: false,
            subtitle: Text(row.$2),
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
