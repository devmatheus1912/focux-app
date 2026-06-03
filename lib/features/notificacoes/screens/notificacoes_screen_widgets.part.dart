part of 'notificacoes_screen.dart';

class _SingleNotificationEntry extends _NotificationEntry {
  const _SingleNotificationEntry(this.item);

  final NotificacaoApp item;

  @override
  DateTime? get createdAt => item.criadaEm;
}

class _RadarNotificationEntry extends _NotificationEntry {
  const _RadarNotificationEntry(this.items);

  final List<NotificacaoApp> items;

  @override
  DateTime? get createdAt => items.isEmpty ? null : items.first.criadaEm;
}

List<_NotificationEntry> _buildNotificationEntries(
  List<NotificacaoApp> source,
) {
  final items = _dedupeNotifications(source);
  final radarByGroup = <String, List<NotificacaoApp>>{};
  for (final item in items) {
    if (_isRadar(item)) {
      radarByGroup.putIfAbsent(_groupLabel(item.criadaEm), () => []).add(item);
    }
  }

  final entries = <_NotificationEntry>[];
  final emittedRadarGroups = <String>{};
  for (final item in items) {
    if (_isRadar(item)) {
      final group = _groupLabel(item.criadaEm);
      if (emittedRadarGroups.add(group)) {
        entries.add(
          _RadarNotificationEntry(
            _dedupeRadarGroup(radarByGroup[group] ?? [item]),
          ),
        );
      }
    } else {
      entries.add(_SingleNotificationEntry(item));
    }
  }
  return entries;
}

List<NotificacaoApp> _dedupeNotifications(List<NotificacaoApp> items) {
  final byKey = <String, NotificacaoApp>{};
  for (final item in items) {
    final key = _dedupeKey(item);
    final current = byKey[key];
    byKey[key] = current == null ? item : _pickNotification(current, item);
  }

  final result = byKey.values.toList();
  result.sort(
    (a, b) => _dateValue(b.criadaEm).compareTo(_dateValue(a.criadaEm)),
  );
  return result;
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
    return 'radar|${_radarRowKey(item)}';
  }
  final message = normalizeNotificationText(item.mensagem);
  return '${item.tipo.toLowerCase()}|${normalizeNotificationText(item.titulo)}|$message|$route';
}

String _radarRowKey(NotificacaoApp item) => radarSignalDedupeKey(
  displayName: _radarName(item),
  summary: _radarSummary(item),
  route: item.route ?? '',
);

List<NotificacaoApp> _dedupeRadarGroup(List<NotificacaoApp> items) {
  final byKey = <String, NotificacaoApp>{};
  for (final item in items) {
    final key = _radarRowKey(item);
    final current = byKey[key];
    byKey[key] = current == null ? item : _pickNotification(current, item);
  }
  final result = byKey.values.toList();
  result.sort(
    (a, b) => _dateValue(b.criadaEm).compareTo(_dateValue(a.criadaEm)),
  );
  return result;
}

bool _isRadar(NotificacaoApp item) {
  final title = item.titulo.toLowerCase();
  final tipo = item.tipo.toLowerCase();
  return title.contains('radar focux') || tipo == 'radar';
}

String _radarName(NotificacaoApp item) {
  final title = item.titulo.trim();
  if (title.toLowerCase().startsWith('radar focux:')) {
    return formatDisplayName(title.split(':').skip(1).join(':').trim());
  }
  return formatDisplayName(
    _humanTitle(item).replaceAll(' precisa de ação', '').trim(),
  );
}

String _groupLabel(DateTime? date) {
  if (date == null) return 'Anteriores';
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Hoje';
  if (day == today.subtract(const Duration(days: 1))) return 'Ontem';
  return 'Anteriores';
}

String _timeLabel(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final local = date.toLocal();
  final diff = now.difference(local);
  if (DateUtils.isSameDay(now, local)) {
    if (diff.inMinutes < 60) {
      return 'há ${diff.inMinutes <= 0 ? 1 : diff.inMinutes}min';
    }
    return 'há ${diff.inHours}h';
  }
  if (DateUtils.isSameDay(local, now.subtract(const Duration(days: 1)))) {
    return 'ontem';
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
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
  return humanAction.trim().isEmpty ? msg : humanAction.trim();
}

Color _notifColor(String tipo, Color primary) {
  switch (tipo.toLowerCase()) {
    case 'risco':
    case 'alerta':
      return EagleTokens.bad;
    case 'pag':
    case 'pagamento':
      return EagleTokens.good;
    case 'ai':
    case 'ia':
    case 'radar':
      return primary;
    case 'feed':
      return EagleTokens.warn;
    default:
      return primary;
  }
}

String _humanTitle(NotificacaoApp item) {
  final title = item.titulo.trim();
  final msg = item.mensagem.trim();
  if (title.toLowerCase().startsWith('radar focux:')) {
    final name = formatDisplayName(title.split(':').skip(1).join(':').trim());
    return name.isEmpty ? 'Aluno precisa de ação' : '$name precisa de ação';
  }
  if (title.isNotEmpty) return title;
  if (msg.isNotEmpty) return msg;
  return 'Nova notificação';
}

String _badgeLabel(NotificacaoApp item) {
  final title = item.titulo.toLowerCase();
  if (title.contains('radar focux') || item.tipo.toLowerCase() == 'radar') {
    return 'Radar Focux';
  }
  switch (item.tipo.toLowerCase()) {
    case 'risco':
    case 'alerta':
      return 'Alerta';
    case 'pag':
    case 'pagamento':
      return 'Financeiro';
    case 'ia':
    case 'ai':
      return 'IA';
    default:
      return item.tipo.isEmpty ? 'Info' : item.tipo;
  }
}

class _RadarNotificationGroup extends StatelessWidget {
  const _RadarNotificationGroup({
    required this.items,
    required this.isDark,
    required this.primary,
    required this.actionInk,
    required this.onOpen,
  });

  final List<NotificacaoApp> items;
  final bool isDark;
  final Color primary;
  final Color actionInk;
  final Future<void> Function(NotificacaoApp item) onOpen;

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final unread = items.any((item) => !item.lida);
    final time = _timeLabel(items.first.criadaEm);
    final label = items.length == 1 ? 'sinal' : 'sinais';

    return Semantics(
      container: true,
      label:
          '${items.length} $label Radar Focux. Alunos com próxima ação pendente.',
      child: AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: unread ? 1 : 0.78,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: fxListCardDecoration(
          context,
          accent: unread ? primary : null,
          radius: 22,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: FxIcon(name: 'spark', color: primary, size: 18),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${items.length} $label Radar Focux',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Alunos com próxima ação pendente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mute,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (time.isNotEmpty)
                  _TinyBadge(label: time, color: primary, isDark: isDark),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < items.length; i++) ...[
              _RadarRow(
                item: items[i],
                isDark: isDark,
                primary: primary,
                actionInk: actionInk,
                onOpen: onOpen,
              ),
              if (i != items.length - 1)
                Divider(height: 14, thickness: 1, color: line),
            ],
            if (items.length > 1) ...[
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: 'Abrir sinais do Radar Focux',
                child: InkWell(
                  onTap:
                      () => onOpen(
                        items.firstWhere(
                          (item) => !item.lida,
                          orElse: () => items.first,
                        ),
                      ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: isDark ? 0.14 : 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Abrir sinais',
                          style: TextStyle(
                            color: actionInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: actionInk,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _RadarRow extends StatelessWidget {
  const _RadarRow({
    required this.item,
    required this.isDark,
    required this.primary,
    required this.actionInk,
    required this.onOpen,
  });

  final NotificacaoApp item;
  final bool isDark;
  final Color primary;
  final Color actionInk;
  final Future<void> Function(NotificacaoApp item) onOpen;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final name = _radarName(item);
    final summary = _radarSummary(item);
    final displayName = name.isEmpty ? 'Aluno' : name;

    return Semantics(
      button: true,
      label: '$displayName. $summary',
      child: InkWell(
      onTap: () => onOpen(item),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Aluno' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 13.2,
                      fontWeight: item.lida ? FontWeight.w700 : FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mute,
                      fontSize: 11.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: actionInk, size: 20),
          ],
        ),
      ),
    ),
    );
  }
}

class _QuietFooter extends StatelessWidget {
  const _QuietFooter({
    required this.isDark,
    required this.primary,
    required this.actionInk,
  });

  final bool isDark;
  final Color primary;
  final Color actionInk;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      container: true,
      label:
          'Inbox sob controle. Fora destes sinais, nada crítico pendente agora.',
      child: Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context, radius: 20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: EagleTokens.good.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: EagleTokens.good,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inbox sob controle',
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Fora destes sinais, nada crítico pendente agora.',
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _TinyBadge(label: 'ok', color: actionInk, isDark: isDark),
        ],
      ),
    ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificacaoApp item;
  final bool isDark;
  final Color primary;
  final Color actionInk;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.isDark,
    required this.primary,
    required this.actionInk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final tipoColor = _notifColor(item.tipo, primary);
    final unread = !item.lida;
    final time = _timeLabel(item.criadaEm);
    final hasRoute = item.route?.startsWith('/') == true;
    final title = _humanTitle(item);
    final a11yLabel =
        unread
            ? 'Não lida. $title. ${item.mensagem}'
            : '$title. ${item.mensagem}';

    return Semantics(
      button: true,
      label: a11yLabel,
      child: AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: item.lida ? 0.76 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: fxListCardDecoration(
            context,
            accent: unread ? tipoColor : null,
            radius: 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tipoColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _iconFor(item.tipo, item.titulo),
                      color: tipoColor,
                      size: 18,
                    ),
                  ),
                  if (unread)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: tipoColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ShellChrome.of(context).cardFill,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              color: mute,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.mensagem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.1,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _TinyBadge(
                          label: _badgeLabel(item),
                          color: tipoColor,
                          isDark: isDark,
                        ),
                        const Spacer(),
                        if (hasRoute)
                          Icon(
                            Icons.chevron_right_rounded,
                            color: actionInk,
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  IconData _iconFor(String tipo, String titulo) {
    final lowTipo = tipo.toLowerCase();
    final lowTitle = titulo.toLowerCase();
    if (lowTitle.contains('radar')) return Icons.track_changes_rounded;
    switch (lowTipo) {
      case 'evolucao':
        return Icons.trending_up_rounded;
      case 'alerta':
      case 'risco':
        return Icons.priority_high_rounded;
      case 'pagamento':
      case 'pag':
        return Icons.attach_money_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotificationsStateCard extends StatelessWidget {
  const _NotificationsStateCard({
    required this.isDark,
    required this.primary,
    required this.actionInk,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool isDark;
  final Color primary;
  final Color actionInk;
  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 24, 16, 120),
      children: [
        Semantics(
          container: true,
          label: '$title. $subtitle',
          child: Container(
          padding: const EdgeInsets.all(18),
          decoration: fxListCardDecoration(
            context,
            accent: actionInk,
            radius: 22,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: FxIcon(name: icon, color: primary)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle, style: TextStyle(color: mute, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }
}
