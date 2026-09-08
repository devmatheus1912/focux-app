part of 'anamnese_screen.dart';

class _AnamneseBody extends StatelessWidget {
  const _AnamneseBody({
    required this.anamnese,
    required this.acting,
    required this.isDark,
    required this.primary,
    required this.alunoId,
    required this.onSolicitar,
    required this.onRevisar,
  });

  final Anamnese anamnese;
  final bool acting;
  final bool isDark;
  final Color primary;
  final int alunoId;
  final VoidCallback onSolicitar;
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
        if (a.alertas.isNotEmpty) ...[
          const SizedBox(height: TokensStrip.s4),
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
          FxEmptyState(
            icon: 'article',
            title: 'Nenhuma ficha ainda',
            subtitle: 'O aluno preenche a anamnese. Você solicita e revisa.',
            action: FxEmptyAction(
              label: 'Solicitar anamnese',
              onTap: acting ? () {} : onSolicitar,
            ),
          ),
        ] else if (a.isSolicitada && !a.personalPodeRevisar) ...[
          const SizedBox(height: TokensStrip.s5),
          const FxEmptyState(
            icon: 'calendar',
            title: 'Aguardando preenchimento',
            subtitle:
                'O aluno foi notificado. Quando enviar, você revisa aqui.',
          ),
        ] else ...[
          const SizedBox(height: TokensStrip.s4),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              DashboardHomeActionChip(
                label: 'Aluno',
                accent: primary,
                isDark: isDark,
                onPressed: () => context.push('/alunos/$alunoId'),
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
              if (!a.isNaoIniciada)
                DashboardHomeActionChip(
                  label: 'Solicitar de novo',
                  accent: primary,
                  isDark: isDark,
                  enabled: !acting,
                  onPressed: onSolicitar,
                ),
              DashboardHomeActionChip(
                label: 'Chat',
                accent: primary,
                isDark: isDark,
                onPressed: () => context.push('/alunos/$alunoId/chat'),
              ),
            ],
          ),
          if (a.personalPodeRevisar) _AnamneseFicha(anamnese: a),
        ],
        if (a.isNaoIniciada || (a.isSolicitada && !a.personalPodeRevisar)) ...[
          const SizedBox(height: TokensStrip.s4),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              DashboardHomeActionChip(
                label: 'Aluno',
                accent: primary,
                isDark: isDark,
                onPressed: () => context.push('/alunos/$alunoId'),
              ),
              DashboardHomeActionChip(
                label: 'Chat',
                accent: primary,
                isDark: isDark,
                onPressed: () => context.push('/alunos/$alunoId/chat'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AnamneseFicha extends StatelessWidget {
  const _AnamneseFicha({required this.anamnese});

  final Anamnese anamnese;

  @override
  Widget build(BuildContext context) {
    final a = anamnese;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'PAR-Q+',
          caption:
              a.parqCompleto == true
                  ? (a.parqPositivo == true
                      ? 'Respostas positivas — atenção.'
                      : 'Questionário completo.')
                  : 'Questionário incompleto ou não enviado.',
          children: [
            for (var i = 0; i < anamneseParqPerguntas.length; i++)
              FxSettingsTile(
                fxIcon: 'alert-triangle',
                label: anamneseParqPerguntas[i].label,
                value: anamneseBoolLabel(
                  anamneseParqValue(a, anamneseParqPerguntas[i].key),
                ),
                showDivider:
                    i < anamneseParqPerguntas.length - 1 ||
                    (a.parqOutraRazaoDetalhe ?? '').trim().isNotEmpty,
                danger:
                    anamneseParqValue(a, anamneseParqPerguntas[i].key) == true,
              ),
            if ((a.parqOutraRazaoDetalhe ?? '').trim().isNotEmpty)
              FxSettingsTile(
                fxIcon: 'help',
                label: 'Detalhe (outra razão)',
                value: a.parqOutraRazaoDetalhe!.trim(),
                showDivider: false,
              ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Saúde',
          caption: 'Preenchido pelo aluno — só leitura.',
          children: [
            _ro('Histórico médico', a.historicoMedico, 'article'),
            _ro('Cirurgias', a.cirurgias, 'alert-triangle'),
            _ro('Dores crônicas', a.doresCronicas, 'zap'),
            _ro('Lesões / limitações', a.lesoes, 'trend'),
            _ro('Medicamentos', a.medicamentos, 'spark'),
            _ro('Alergias', a.alergias, 'alert-triangle'),
            _ro('Gestação / pós-parto', a.gestacaoPosParto, 'users'),
            _ro('Histórico familiar CV', a.historicoFamiliarCv, 'users'),
            _ro('Sintomas CV', a.sintomasCv, 'flame', showDivider: false),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Hábitos',
          children: [
            FxSettingsTile(
              fxIcon: 'moon',
              label: 'Sono',
              value: anamneseSonoHorasLabel(a.sonoHoras),
            ),
            _ro('Qualidade do sono', a.qualidadeSono, 'moon'),
            _ro('Nível de estresse', a.nivelEstresse, 'zap'),
            _ro('Tabagismo', a.tabagismo, 'x'),
            _ro('Álcool', a.alcool, 'spark'),
            _ro('Observações', a.observacoes, 'article', showDivider: false),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Treino e objetivos',
          caption: 'Contexto de saúde — restrição alimentar não é dieta.',
          children: [
            _ro('Objetivo', a.objetivo, 'target'),
            _ro('Objetivo detalhado', a.objetivoDetalhado, 'target'),
            FxSettingsTile(
              fxIcon: 'calendar',
              label: 'Disponibilidade',
              value:
                  a.disponibilidadeSemanal == null
                      ? '—'
                      : anamneseDisponibilidadeLabel(a.disponibilidadeSemanal!),
            ),
            _ro('Preferências de treino', a.preferenciasTreino, 'dumbbell'),
            _ro('Restrições alimentares', a.restricoesAlimentares, 'spark'),
            _ro('Histórico de atividade', a.historicoAtividade, 'trend'),
            _ro('Motivo de interrupções', a.motivoInterrupcoes, 'x'),
            _ro('Motivação atual', a.motivacaoAtual, 'flame'),
            _ro('Algo mais', a.algoMais, 'message-circle', showDivider: false),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Notas do profissional',
          caption: 'Só você edita na revisão.',
          children: [
            _ro('Notas', a.notasProfissional, 'article'),
            _ro('Atestado', a.atestadoObs, 'circle-check', showDivider: false),
          ],
        ),
      ],
    );
  }
}

FxSettingsTile _ro(
  String label,
  String? value,
  String icon, {
  bool showDivider = true,
}) {
  return FxSettingsTile(
    fxIcon: icon,
    label: label,
    value: anamneseTextOrDash(value),
    showDivider: showDivider,
  );
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
