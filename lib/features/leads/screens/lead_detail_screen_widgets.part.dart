part of 'lead_detail_screen.dart';

class _LeadDetailContent extends StatelessWidget {
  const _LeadDetailContent({
    required this.lead,
    required this.loadingInteracoes,
    required this.interacoes,
    required this.isDark,
    required this.freshnessLabel,
    required this.sticky,
    required this.secao,
    required this.onSecao,
    required this.onDefinirFollowUp,
    required this.onLigar,
    required this.onWhatsapp,
    required this.onArquivar,
    required this.onNovaInteracao,
  });

  final Lead lead;
  final bool loadingInteracoes;
  final List<LeadInteracao> interacoes;
  final bool isDark;
  final String? freshnessLabel;
  final LeadStickyAction sticky;
  final String secao;
  final ValueChanged<String> onSecao;
  final VoidCallback onDefinirFollowUp;
  final VoidCallback onLigar;
  final VoidCallback onWhatsapp;
  final VoidCallback onArquivar;
  final VoidCallback onNovaInteracao;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final telefone = lead.telefone?.trim();
    final temTelefone = telefone != null && telefone.isNotEmpty;
    final observacoes = lead.observacoes?.trim();
    final objetivo = lead.objetivo?.trim();
    final origem = lead.origem?.trim();
    final historico = interacoes.reversed.toList();
    final danger = leadStatusDanger(lead.status);
    final followHint = [
      if (objetivo != null && objetivo.isNotEmpty) objetivo,
      if (origem != null && origem.isNotEmpty) origem,
    ].join(' · ');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
        FxSettingsLayout.pageInset,
        32,
      ),
      children: [
        FxHubHeader(
          title: lead.nome,
          subtitle: leadHubSubtitle(
            status: lead.status,
            freshness: freshnessLabel,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        OperationalMetricTile(
          label: leadStatusLabel(lead.status),
          value: leadFollowUpValue(lead.proximoContato),
          hint: followHint.isEmpty ? 'Próximo contato' : followHint,
          color: danger ? EagleTokens.bad : primary,
          isDark: isDark,
          emphasis:
              danger
                  ? OperationalMetricEmphasis.alert
                  : OperationalMetricEmphasis.normal,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'Contatos',
          value: leadInteracoesMetricValue(interacoes.length),
          hint: leadInteracoesMetricHint(interacoes.length),
          color: primary,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'No funil',
          value: leadDiasNoFunilValue(lead.criadoEm),
          hint: leadDiasNoFunilHint(lead.criadoEm),
          color: primary,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'Origem',
          value: leadOrigemLabel(origem),
          hint: objetivo == null || objetivo.isEmpty ? 'Canal de entrada' : objetivo,
          color: primary,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s4),
        AlunoSegmentedChoice(
          options: leadDetailSecoes,
          selected: secao,
          isDark: isDark,
          onSelect: onSecao,
        ),
        const SizedBox(height: TokensStrip.s4),
        if (secao == leadDetailSecaoInteracoes)
          ..._interacoesSection(context, historico)
        else
          ..._resumoSection(
            context,
            primary,
            temTelefone: temTelefone,
            observacoes: observacoes,
          ),
      ],
    );
  }

  List<Widget> _resumoSection(
    BuildContext context,
    Color primary, {
    required bool temTelefone,
    required String? observacoes,
  }) {
    return [
      Wrap(
        spacing: TokensStrip.s2,
        runSpacing: TokensStrip.s2,
        children: [
          DashboardHomeActionChip(
            label: 'Lista',
            accent: primary,
            isDark: isDark,
            onPressed: () => safePopOrGo(context, '/leads'),
          ),
          if (sticky != LeadStickyAction.followUp)
            DashboardHomeActionChip(
              label: 'Follow-up',
              accent: primary,
              isDark: isDark,
              onPressed: onDefinirFollowUp,
            ),
          if (temTelefone) ...[
            DashboardHomeActionChip(
              label: 'Ligar',
              accent: primary,
              isDark: isDark,
              onPressed: onLigar,
            ),
            if (sticky != LeadStickyAction.whatsapp)
              DashboardHomeActionChip(
                label: 'WhatsApp',
                accent: primary,
                isDark: isDark,
                onPressed: onWhatsapp,
              ),
          ],
        ],
      ),
      if (observacoes != null && observacoes.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s4),
        Text(
          observacoes,
          style: FocuxHubTypography.bodyMuted(
            color: fxScreenMute(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      const SizedBox(height: TokensStrip.s5),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onArquivar,
          style: TextButton.styleFrom(foregroundColor: EagleTokens.bad),
          child: const Text('Arquivar lead'),
        ),
      ),
    ];
  }

  List<Widget> _interacoesSection(
    BuildContext context,
    List<LeadInteracao> historico,
  ) {
    return [
      DashboardSectionHeader(
        title: 'Interações',
        actionLabel: 'Nova',
        onAction: onNovaInteracao,
      ),
      const SizedBox(height: TokensStrip.s3),
      if (loadingInteracoes)
        const SkeletonList(count: 3)
      else if (interacoes.isEmpty)
        FxEmptyState(
          icon: 'chat',
          title: 'Nenhuma interação registrada',
          subtitle:
              'Registre ligações, mensagens e visitas para não perder o histórico.',
          action: FxEmptyAction(
            label: 'Nova interação',
            onTap: onNovaInteracao,
          ),
        )
      else
        for (final item in historico)
          FxSatelliteListTile(
            title: leadInteracaoTipoLabel(item.tipo),
            subtitle: Text(item.descricao),
            trailing: Text(
              leadFollowUpValue(item.dataInteracao),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
    ];
  }
}
