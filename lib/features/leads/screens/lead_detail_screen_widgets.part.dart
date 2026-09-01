part of 'lead_detail_screen.dart';

class _LeadDetailContent extends StatelessWidget {
  const _LeadDetailContent({
    required this.lead,
    required this.loadingInteracoes,
    required this.interacoes,
    required this.onDefinirFollowUp,
    required this.onLigar,
    required this.onWhatsapp,
    required this.onConverter,
    required this.onArquivar,
    required this.onNovaInteracao,
  });

  final Lead lead;
  final bool loadingInteracoes;
  final List<LeadInteracao> interacoes;
  final VoidCallback onDefinirFollowUp;
  final VoidCallback onLigar;
  final VoidCallback onWhatsapp;
  final VoidCallback onConverter;
  final VoidCallback onArquivar;
  final VoidCallback onNovaInteracao;

  @override
  Widget build(BuildContext context) {
    final telefone = lead.telefone?.trim();
    final temTelefone = telefone != null && telefone.isNotEmpty;
    final observacoes = lead.observacoes?.trim();
    final objetivo = lead.objetivo?.trim();
    final origem = lead.origem?.trim();
    final historico = interacoes.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        32,
      ),
      children: [
        FxSettingsGroup(
          header: 'Prospect',
          caption: 'Toque no follow-up para remarcar o próximo contato.',
          children: [
            FxSettingsTile(
              fxIcon: 'users',
              label: 'Nome',
              value: lead.nome,
              onTap: () {},
            ),
            if (temTelefone)
              FxSettingsTile(
                fxIcon: 'message-circle',
                label: 'Telefone',
                value: telefone,
                onTap: onLigar,
              ),
            if (origem != null && origem.isNotEmpty)
              FxSettingsTile(
                fxIcon: 'spark',
                label: 'Origem',
                value: origem,
                onTap: () {},
              ),
            if (objetivo != null && objetivo.isNotEmpty)
              FxSettingsTile(
                fxIcon: 'target',
                label: 'Objetivo',
                value: objetivo,
                onTap: () {},
              ),
            FxSettingsTile(
              fxIcon: 'calendar',
              label: 'Cadastrado',
              value: lead.criadoEm,
              onTap: () {},
            ),
            if (lead.convertidoEm != null)
              FxSettingsTile(
                fxIcon: 'circle-check',
                label: 'Convertido',
                value: lead.convertidoEm!,
                onTap: () {},
              ),
            FxSettingsTile(
              fxIcon: 'calendar',
              label: 'Próximo contato',
              value: leadFollowUpValue(lead.proximoContato),
              picker: true,
              showDivider: observacoes != null && observacoes.isNotEmpty,
              onTap: onDefinirFollowUp,
            ),
            if (observacoes != null && observacoes.isNotEmpty)
              FxSettingsTile(
                fxIcon: 'article',
                label: 'Observações',
                value: observacoes,
                showDivider: false,
                onTap: () {},
              ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Ações',
          children: [
            if (temTelefone) ...[
              FxSettingsTile(
                fxIcon: 'message-circle',
                label: 'Ligar',
                value: telefone,
                onTap: onLigar,
              ),
              FxSettingsTile(
                fxIcon: 'chat',
                label: 'WhatsApp',
                value: telefone,
                onTap: onWhatsapp,
              ),
            ],
            if (leadPodeConverter(lead.status))
              FxSettingsTile(
                fxIcon: 'users',
                label: 'Converter em aluno',
                value: '',
                onTap: onConverter,
              ),
            FxSettingsTile(
              fxIcon: 'x',
              label: 'Arquivar lead',
              value: '',
              danger: true,
              showDivider: false,
              onTap: onArquivar,
            ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
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
          FxSettingsGroup(
            header: 'Interações',
            caption: '${historico.length} registro(s).',
            children: [
              for (var i = 0; i < historico.length; i++)
                FxSettingsTile(
                  fxIcon: leadInteracaoFxIcon(historico[i].tipo),
                  label: leadInteracaoTipoLabel(historico[i].tipo),
                  subtitle: historico[i].descricao,
                  value: leadFollowUpValue(historico[i].dataInteracao),
                  showDivider: i != historico.length - 1,
                  onTap: () {},
                ),
            ],
          ),
      ],
    );
  }
}
