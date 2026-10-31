part of 'notificacoes_screen.dart';

IconData _iconeDoTipo(String tipo) {
  final t = tipo.toUpperCase();
  if (t.startsWith('MENSALIDADE') || t == 'DUNNING' || t == 'TRIAL') {
    return Icons.payments_outlined;
  }
  if (t == 'FOCUX_SCORE' || t == 'RADAR' || t == 'ENGAJAMENTO') {
    return Icons.person_outline_rounded;
  }
  if (t == 'EVOLUCAO' || t == 'FICHA_VIGENCIA') {
    return Icons.fitness_center_rounded;
  }
  if (t == 'FEED' || t == 'BROADCAST' || t == 'DEPOIMENTO') {
    return Icons.campaign_outlined;
  }
  return Icons.notifications_none_rounded;
}

/// Dinheiro tem verbo visível na linha; o resto abre no toque, com a seta.
bool _temBotaoPagar(NotificacaoApp item) =>
    item.tipo.toUpperCase().startsWith('MENSALIDADE') &&
    (item.ctaLabel?.trim() ?? '').isNotEmpty;

/// Uma linha do dia. Não lida: ponto e título forte. Lida: título normal.
class _NotificacaoTile extends StatelessWidget {
  const _NotificacaoTile({
    required this.item,
    required this.temDestino,
    required this.onTap,
  });

  final NotificacaoApp item;
  final bool temDestino;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final unread = !item.lida;
    final cta = item.ctaLabel?.trim() ?? '';
    final titulo = notificationHumanTitle(item);
    final apoio = [
      notificationSubtitle(item),
      notificationTimeLabel(item.criadaEm),
    ].where((t) => t.isNotEmpty).join(' · ');
    return Semantics(
      button: true,
      label: [
        if (unread) ptS.notificacoesNaoLida,
        titulo,
        apoio,
        if (temDestino && cta.isNotEmpty) cta,
      ].join(', '),
      excludeSemantics: !(temDestino && _temBotaoPagar(item)),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s3,
              vertical: TokensStrip.s2,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primary.withValues(alpha: 0.10),
                  child: Icon(_iconeDoTipo(item.tipo), size: 18, color: primary),
                ),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.body(color: chrome.ink).copyWith(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (apoio.isNotEmpty)
                        Text(
                          apoio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                        ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: TokensStrip.s2),
                  Container(
                    key: const ValueKey('notificacao-nao-lida'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                if (temDestino && _temBotaoPagar(item)) ...[
                  const SizedBox(width: TokensStrip.s2),
                  FxTonalButton(label: cta, compact: true, onPressed: onTap),
                ] else if (temDestino) ...[
                  const SizedBox(width: TokensStrip.s1),
                  Icon(Icons.chevron_right_rounded, color: chrome.mute),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApagarFundo extends StatelessWidget {
  const _ApagarFundo();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: TokensStrip.s4),
      decoration: BoxDecoration(
        color: EagleTokens.bad,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ptS.notificacoesApagar,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: TokensStrip.s2),
          Icon(Icons.delete_outline_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

/// Uma linha na tela. [iguais] são os registros que ela representa: abrir ou
/// apagar a linha vale para todos, senão o contador nunca zera.
class _HubRow {
  const _HubRow({
    required this.item,
    required this.dayGroup,
    required this.iguais,
  });

  final NotificacaoApp item;
  final String dayGroup;
  final List<NotificacaoApp> iguais;

  bool get temNaoLida => iguais.any((n) => !n.lida);
  Iterable<int> get idsNaoLidos => iguais.where((n) => !n.lida).map((n) => n.id);
}

List<_HubRow> _buildNotificationRows(List<NotificacaoApp> source) {
  final grupos = <String, List<NotificacaoApp>>{};
  for (final item in source) {
    grupos.putIfAbsent(_dedupeKey(item), () => []).add(item);
  }
  final rows = [
    for (final iguais in grupos.values)
      () {
        final item = iguais.reduce(_pickNotification);
        return _HubRow(
          item: item,
          dayGroup: notificationGroupLabel(item.criadaEm),
          iguais: iguais,
        );
      }(),
  ];
  rows.sort(
    (a, b) => _dateValue(b.item.criadaEm).compareTo(_dateValue(a.item.criadaEm)),
  );
  return rows;
}

NotificacaoApp _pickNotification(NotificacaoApp a, NotificacaoApp b) {
  if (!a.lida && b.lida) return a;
  if (a.lida && !b.lida) return b;
  return _dateValue(b.criadaEm).isAfter(_dateValue(a.criadaEm)) ? b : a;
}

DateTime _dateValue(DateTime? date) =>
    date ?? DateTime.fromMillisecondsSinceEpoch(0);

String _dedupeKey(NotificacaoApp item) {
  final route = item.route?.trim().toLowerCase() ?? '';
  if (_isRadar(item)) {
    return 'radar|${radarSignalDedupeKey(
      displayName: _radarName(item),
      summary: _radarSummary(item),
      route: item.route ?? '',
    )}';
  }
  final message = normalizeNotificationText(item.mensagem);
  return '${item.tipo.toLowerCase()}|${normalizeNotificationText(item.titulo)}|$message|$route';
}

bool _isRadar(NotificacaoApp item) {
  final title = item.titulo.toLowerCase();
  final tipo = item.tipo.toLowerCase();
  return title.contains('radar focux') || tipo == 'radar' || tipo == 'focux_score';
}

String _radarName(NotificacaoApp item) {
  final title = item.titulo.trim();
  if (title.toLowerCase().startsWith(ptS.notificacoesRadarFocux)) {
    return notificacaoNomeLimpo(title.split(':').skip(1).join(':'));
  }
  return notificacaoNomeLimpo(title);
}

String _radarSummary(NotificacaoApp item) {
  final msg = item.mensagem.trim();
  final nextAction = RegExp(
    r'Pr[oó]xima a[cç][aã]o:\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(msg);
  if (nextAction != null) return nextAction.group(1)!.trim();

  final humanAction = msg.replaceFirst(
    RegExp(
      r'^.*precisa de uma a[cç][aã]o humana hoje:\s*',
      caseSensitive: false,
    ),
    '',
  );
  final texto = humanAction.trim().isEmpty ? msg : humanAction.trim();
  // O backend manda "Julio · mapa corporal": o nome já vai na segunda linha.
  final ponto = texto.indexOf(' · ');
  return ponto < 0 ? texto : texto.substring(ponto + 3).trim();
}

/// A ação do Radar como título: diz o que fazer, não só "precisa de ação".
String _radarTitulo(NotificacaoApp item) {
  final acao = _radarSummary(item);
  if (acao.isEmpty) return ptS.notificacoesAlunoPrecisaDeAtencao;
  final frase = '${acao[0].toUpperCase()}${acao.substring(1)}';
  return acao.toLowerCase() == 'mapa corporal' ? '$frase pendente' : frase;
}

String notificationGroupLabel(DateTime? date) {
  if (date == null) return ptS.agendaAlunoAnteriores;
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return ptS.dockHoje;
  if (day == today.subtract(const Duration(days: 1))) return ptS.treinosDiaOntem;
  if (today.difference(day).inDays < 7) return ptS.alunoSemanaFaixaTitulo;
  return ptS.agendaAlunoAnteriores;
}

String notificationTimeLabel(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final local = date.toLocal();
  final diff = now.difference(local);
  if (DateUtils.isSameDay(now, local)) {
    if (diff.inMinutes < 60) {
      return ptS.notificacoesHaMin(diff.inMinutes <= 0 ? 1 : diff.inMinutes);
    }
    return ptS.notificacoesHaH(diff.inHours);
  }
  if (DateUtils.isSameDay(local, now.subtract(const Duration(days: 1)))) {
    return 'ontem';
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

String notificationHumanTitle(NotificacaoApp item) {
  final title = item.titulo.trim();
  final msg = item.mensagem.trim();
  if (_isRadar(item)) return _radarTitulo(item);
  if (title.isNotEmpty) return title;
  if (msg.isNotEmpty) return msg;
  return ptS.notificacoesNovaNotificacao;
}

String notificationSubtitle(NotificacaoApp item) {
  if (_isRadar(item)) return _radarName(item);
  return item.mensagem.trim();
}
