part of 'suporte_screen.dart';

class _MeusTicketsTab extends ConsumerStatefulWidget {
  const _MeusTicketsTab();

  @override
  ConsumerState<_MeusTicketsTab> createState() => _MeusTicketsTabState();
}

class _MeusTicketsTabState extends ConsumerState<_MeusTicketsTab> {
  List<SuporteTicket> _tickets = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = SuporteRepository(ref.read(apiClientProvider));
      final tickets = await repo.meusTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight:
          MediaQuery.sizeOf(context).height *
          FxHomeSheetChrome.expandHeightFactor,
      child: Column(
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Meus tickets',
            subtitle: 'Acompanhe o que você já abriu com o suporte.',
            leading: FxIcon(name: 'article', color: primary, size: 18),
          ),
          SizedBox(height: TokensStrip.s3),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) return const SkeletonList(count: 5);
    if (_erro != null) {
      return FxErrorState(
        chromeOnDark: Theme.of(context).brightness == Brightness.dark,
        primary: Theme.of(context).colorScheme.primary,
        title: 'Não foi possível carregar seus tickets',
        message: _erro!,
        onRetry: _load,
      );
    }
    if (_tickets.isEmpty) {
      return const FxEmptyState(
        icon: 'help',
        title: 'Nenhum ticket aberto',
        subtitle: 'Abra um ticket quando precisar falar com o suporte Focux.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: _tickets.length,
        itemBuilder: (_, i) => _TicketCard(ticket: _tickets[i]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SuporteTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, ticket.status);
    final sevColor =
        _severidadeColors[ticket.severidade] ?? TokensStrip.textSecondary;
    final resolvido = ticket.status == 'RESOLVIDO';
    final temResposta = resolvido && ticket.respostaAdmin != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: fxListTileCardShell(
        context: context,
        accent: statusColor,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child:
              temResposta
                  ? ExpansionTile(
                    backgroundColor: Colors.transparent,
                    collapsedBackgroundColor: Colors.transparent,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      12,
                    ),
                    title: _TicketTileContent(
                      ticket: ticket,
                      statusColor: statusColor,
                      sevColor: sevColor,
                    ),
                    children: [
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.support_agent,
                            size: 18,
                            color: EagleTokens.good,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resposta do suporte',
                                  style: FocuxHubTypography.bodyMuted(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.respostaAdmin!,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  : ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: _TicketTileContent(
                      ticket: ticket,
                      statusColor: statusColor,
                      sevColor: sevColor,
                    ),
                  ),
        ),
      ),
    );
  }
}

class _TicketTileContent extends StatelessWidget {
  final SuporteTicket ticket;
  final Color statusColor;
  final Color sevColor;

  const _TicketTileContent({
    required this.ticket,
    required this.statusColor,
    required this.sevColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                ticket.severidade,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: sevColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: sevColor),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Chip(
              label: Text(
                ticket.status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: statusColor),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (ticket.criadoEm != null) ...[
          const SizedBox(height: 4),
          Text(
            'Aberto em ${fxTimeAgo(DateTime.parse(ticket.criadoEm!))}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: TokensStrip.textSecondary),
          ),
        ],
      ],
    );
  }
}
