part of 'notificacoes_screen.dart';

/// Não lida: ponto + título forte + borda da marca. Lida: título leve, borda neutra.
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
    final subtitle = notificationSubtitle(item);
    return Semantics(
      label: unread ? 'Não lida' : null,
      child: FxSatelliteListTile(
        title: notificationHumanTitle(item),
        titleCase: false,
        muted: !unread,
        isThreeLine: temDestino && cta.isNotEmpty,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle),
            if (temDestino && cta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: TokensStrip.s1),
                child: Text(
                  '$cta ›',
                  style: FocuxHubTypography.bodyMuted(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notificationTimeLabel(item.criadaEm),
              style: FocuxHubTypography.bodyMuted(
                color: chrome.mute,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (unread) ...[
              const SizedBox(height: TokensStrip.s1),
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
          ],
        ),
        accent: unread ? primary : chrome.mute,
        onTap: onTap,
      ),
    );
  }
}

class _HubRow {
  const _HubRow({required this.item, required this.dayGroup});

  final NotificacaoApp item;
  final String dayGroup;
}

List<_HubRow> _buildNotificationRows(List<NotificacaoApp> source) {
  return _dedupeNotifications(source)
      .map(
        (item) => _HubRow(item: item, dayGroup: notificationGroupLabel(item.criadaEm)),
      )
      .toList();
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
  return title.contains('radar focux') || tipo == 'radar';
}

String _radarName(NotificacaoApp item) {
  final title = item.titulo.trim();
  if (title.toLowerCase().startsWith('radar focux:')) {
    return formatDisplayName(title.split(':').skip(1).join(':').trim());
  }
  return formatDisplayName(
    notificationHumanTitle(item).replaceAll(' precisa de ação', '').trim(),
  );
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

String notificationGroupLabel(DateTime? date) {
  if (date == null) return 'Anteriores';
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Hoje';
  if (day == today.subtract(const Duration(days: 1))) return 'Ontem';
  return 'Anteriores';
}

String notificationTimeLabel(DateTime? date) {
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

String notificationHumanTitle(NotificacaoApp item) {
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

String notificationSubtitle(NotificacaoApp item) {
  if (_isRadar(item)) return _radarSummary(item);
  return item.mensagem.trim();
}
