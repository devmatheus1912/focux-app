part of 'lead_detail_screen.dart';

class _LeadDetailContent extends StatelessWidget {
  const _LeadDetailContent({
    required this.lead,
    required this.loadingInteracoes,
    required this.interacoes,
    required this.isDark,
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
    final visiveis = historico.take(3).toList();
    final danger = leadStatusDanger(lead.status);
    final followHint = [
      if (objetivo != null && objetivo.isNotEmpty) objetivo,
      if (origem != null && origem.isNotEmpty) origem,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
        FxSettingsLayout.pageInset,
        32,
      ),
      children: [
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
        const SizedBox(height: TokensStrip.s4),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
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
        else ...[
          for (final item in visiveis)
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
          if (historico.length > visiveis.length)
            Align(
              alignment: Alignment.centerLeft,
              child: DashboardHomeActionChip(
                label: 'Ver todas · ${historico.length}',
                accent: primary,
                isDark: isDark,
                onPressed: () => _abrirHistorico(context, historico),
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
      ],
    );
  }

  Future<void> _abrirHistorico(
    BuildContext context,
    List<LeadInteracao> historico,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Interações',
                subtitle: '${historico.length} registros',
                leading: const Icon(Icons.forum_outlined, size: 18),
              ),
              const SizedBox(height: TokensStrip.s3),
              for (final item in historico)
                FxSettingsTile(
                  fxIcon: leadInteracaoFxIcon(item.tipo),
                  label: leadInteracaoTipoLabel(item.tipo),
                  subtitle: item.descricao,
                  value: leadFollowUpValue(item.dataInteracao),
                ),
            ],
          ),
        );
      },
    );
  }
}
