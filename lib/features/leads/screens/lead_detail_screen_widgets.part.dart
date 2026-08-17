part of 'lead_detail_screen.dart';

class _LeadDetailContent extends StatelessWidget {
  const _LeadDetailContent({
    required this.lead,
    required this.color,
    required this.podeConverter,
    required this.loadingInteracoes,
    required this.interacoes,
    required this.onDefinirFollowUp,
    required this.onLigar,
    required this.onWhatsapp,
    required this.onConverter,
    required this.onArquivar,
  });

  final Lead lead;
  final Color color;
  final bool podeConverter;
  final bool loadingInteracoes;
  final List<LeadInteracao> interacoes;
  final VoidCallback onDefinirFollowUp;
  final VoidCallback onLigar;
  final VoidCallback onWhatsapp;
  final VoidCallback onConverter;
  final VoidCallback onArquivar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s4,
        TokensStrip.s4,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status chip
          Center(
            child: Chip(
              label: Text(
                _statusLabels[lead.status] ?? lead.status,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
              backgroundColor: color.withValues(alpha: 0.12),
              avatar: Icon(Icons.circle, size: 10, color: color),
            ),
          ),
          const SizedBox(height: TokensStrip.s4),

          // Info card
          Container(
            decoration: fxListCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(TokensStrip.s4),
              child: Column(
                children: [
                  _InfoRow(label: 'Nome', value: lead.nome),
                  if (lead.telefone != null)
                    _InfoRow(label: 'Telefone', value: lead.telefone!),
                  if (lead.origem != null)
                    _InfoRow(label: 'Origem', value: lead.origem!),
                  if (lead.objetivo != null)
                    _InfoRow(label: 'Objetivo', value: lead.objetivo!),
                  _InfoRow(label: 'Cadastrado em', value: lead.criadoEm),
                  if (lead.convertidoEm != null)
                    _InfoRow(
                      label: 'Convertido em',
                      value: lead.convertidoEm!,
                    ),
                ],
              ),
            ),
          ),

          // Próximo Contato / Follow-up
          const SizedBox(height: 12),
          Container(
            decoration: fxListCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensStrip.s4,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: EagleTokens.purpleAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo Contato',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: TokensStrip.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lead.proximoContato ?? 'Não definido',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color:
                                lead.proximoContato != null
                                    ? EagleTokens.purpleAccent
                                    : TokensStrip.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDefinirFollowUp,
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Definir follow-up'),
                  ),
                ],
              ),
            ),
          ),

          if (lead.observacoes != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: fxListCardDecoration(context),
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Observações',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: TokensStrip.textSecondary),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    Text(lead.observacoes!),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: TokensStrip.s5),
          const Divider(),
          const SizedBox(height: 8),

          // Ações rápidas
          if (lead.telefone != null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onLigar,
                    icon: const Icon(Icons.phone),
                    label: const Text('Ligar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWhatsapp,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EagleTokens.good,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (podeConverter) ...[
            FilledButton.tonal(
              onPressed: onConverter,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add),
                  SizedBox(width: 8),
                  Text('Converter em Aluno'),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          OutlinedButton.icon(
            onPressed: onArquivar,
            icon: const Icon(Icons.archive),
            label: const Text('Arquivar Lead'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TokensStrip.textSecondary,
            ),
          ),

          // Interações
          const SizedBox(height: TokensStrip.s5),
          Row(
            children: [
              const Icon(Icons.timeline, size: 20),
              const SizedBox(width: 8),
              Text(
                'Interações',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (!loadingInteracoes)
                Text(
                  '${interacoes.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TokensStrip.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (loadingInteracoes)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s4),
                child: FxLoading(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else if (interacoes.isEmpty)
            Container(
              decoration: fxListCardDecoration(context),
              child: const FxEmptyState(
                icon: 'chat',
                title: 'Nenhuma interação registrada',
                subtitle:
                    'Registre ligações, mensagens e visitas para não perder o histórico.',
              ),
            )
          else
            ...interacoes.reversed.map((i) => _InteracaoTile(interacao: i)),
        ],
      ),
    );
  }
}

class _InteracaoTile extends StatelessWidget {
  final LeadInteracao interacao;
  const _InteracaoTile({required this.interacao});

  @override
  Widget build(BuildContext context) {
    final icon = _tipoIcons[interacao.tipo] ?? Icons.note;
    final dataStr =
        interacao.dataInteracao != null
            ? fxDateShort(DateTime.parse(interacao.dataInteracao!))
            : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Container(
              width: 2,
              height: 24,
              color: Theme.of(context).dividerColor,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      interacao.tipo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (dataStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        dataStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: TokensStrip.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(interacao.descricao, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TokensStrip.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
