part of 'aluno_detail_screen.dart';

class _Aluno360TimelineCard extends StatelessWidget {
  final Aluno aluno;
  final AsyncValue<List<AlunoAutonomiaEvento>> eventosAsync;
  final AsyncValue<List<FocuxScoreSnapshotResumo>> snapshotsAsync;
  final AsyncValue<List<Timeline360Event>> timelineApiAsync;
  final bool isDark;

  const _Aluno360TimelineCard({
    required this.aluno,
    required this.eventosAsync,
    required this.snapshotsAsync,
    required this.timelineApiAsync,
    required this.isDark,
  });

  static _Timeline360Item _itemFromApi(
    Timeline360Event e, {
    required Color primary,
  }) {
    final at = DateTime.tryParse(e.ocorridoEm);
    final tipo = e.tipo;
    IconData icon;
    Color color;
    String kind;
    switch (tipo) {
      case 'RADAR':
        icon = Icons.radar_outlined;
        color = EagleTokens.warn;
        kind = 'Radar';
        break;
      case 'CHECKIN':
        icon = Icons.fitness_center_outlined;
        color = EagleTokens.good;
        kind = 'Check-in';
        break;
      case 'MEDIDA':
        icon = Icons.straighten_outlined;
        color = EagleTokens.purple;
        kind = 'Medida';
        break;
      case 'AUTONOMIA':
        icon = Icons.touch_app_outlined;
        color = EagleTokens.warn;
        kind = 'Autonomia';
        break;
      case 'FINANCEIRO':
        icon = Icons.payments_outlined;
        color = EagleTokens.bad;
        kind = 'Financeiro';
        break;
      default:
        if (tipo.startsWith('CHAT_')) {
          icon = Icons.chat_bubble_outline;
          color = primary;
          kind = 'Chat';
        } else {
          icon = Icons.bolt_outlined;
          color = TokensStrip.textSecondary;
          kind = tipo;
        }
    }
    final deep = e.deepLink.trim().isEmpty ? null : e.deepLink.trim();
    return _Timeline360Item(
      at: at,
      kind: kind,
      title: e.titulo,
      body: e.corpo.isEmpty ? e.meta : e.corpo,
      meta: e.meta,
      priority: e.prioridade,
      icon: icon,
      color: color,
      deepLink: deep,
    );
  }

  List<_Timeline360Item> _items(Color primary) {
    final api = timelineApiAsync.valueOrNull;
    if (api != null && api.isNotEmpty) {
      return api
          .take(7)
          .map((event) => _itemFromApi(event, primary: primary))
          .toList();
    }
    final items = <_Timeline360Item>[];
    for (final snapshot in snapshotsAsync.valueOrNull ?? const []) {
      final date = DateTime.tryParse(snapshot.dataReferencia);
      items.add(
        _Timeline360Item(
          at: date,
          kind: 'Radar',
          title: '${snapshot.score} pts · ${snapshot.ritmo}',
          body: snapshot.narrativa,
          meta: snapshot.proximaAcao,
          priority: snapshot.prioridade,
          icon: Icons.radar_outlined,
          color: snapshot.score >= 80 ? EagleTokens.good : EagleTokens.warn,
        ),
      );
    }
    for (final evento in eventosAsync.valueOrNull ?? const []) {
      items.add(
        _Timeline360Item(
          at: evento.criadoEm,
          kind: 'Autonomia',
          title: evento.taskTitle,
          body: _autonomyBody(evento),
          meta: evento.priority ?? 'Sinal do aluno',
          priority: evento.action,
          icon: _autonomyIcon(evento.action),
          color: _autonomyColor(evento.action),
        ),
      );
    }
    items.sort((a, b) {
      final left = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return items.take(7).toList();
  }

  static String _autonomyBody(AlunoAutonomiaEvento evento) {
    final action = switch (evento.action.toUpperCase()) {
      'VIEWED' => 'O aluno viu esta tarefa.',
      'CLICKED' => 'O aluno tentou avançar e clicou nesta tarefa.',
      'COMPLETED' => 'O aluno concluiu esta etapa.',
      _ => 'Sinal registrado no percurso do aluno.',
    };
    if (evento.profileCompletion != null) {
      return '$action Perfil em ${evento.profileCompletion}%.';
    }
    return action;
  }

  static IconData _autonomyIcon(String action) {
    return switch (action.toUpperCase()) {
      'VIEWED' => Icons.visibility_outlined,
      'CLICKED' => Icons.touch_app_outlined,
      'COMPLETED' => Icons.check_circle_outline,
      _ => Icons.bolt_outlined,
    };
  }

  static Color _autonomyColor(String action) {
    return switch (action.toUpperCase()) {
      'CLICKED' => EagleTokens.warn,
      'COMPLETED' => EagleTokens.good,
      _ => TokensStrip.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final line = ShellChrome.of(context).line;
    final loading =
        eventosAsync.isLoading ||
        snapshotsAsync.isLoading ||
        timelineApiAsync.isLoading;
    final items = _items(primary);
    final visibleItems = items.take(3).toList();
    final hasMore = items.length > visibleItems.length;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.timeline_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linha do tempo 360',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Últimos sinais consolidados do aluno.',
                      style: TextStyle(color: mute, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (loading) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (items.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '${aluno.nome} ainda não tem sinais suficientes para formar uma linha do tempo.',
              style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
            ),
          ] else ...[
            const SizedBox(height: 14),
            for (final item in visibleItems) ...[
              _Timeline360Tile(item: item, isDark: isDark),
              if (item != visibleItems.last) Divider(height: 18, color: line),
            ],
            if (hasMore) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showFullTimeline(context, items),
                  child: Text('Ver histórico completo · ${items.length}'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showFullTimeline(BuildContext context, List<_Timeline360Item> items) {
    final chrome = ShellChrome.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder:
                (context, controller) => Padding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 0),
                  child: ShellSurface(
                    radius: 28,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      24 + MediaQuery.of(ctx).padding.bottom,
                    ),
                    child: ListView.separated(
                  controller: controller,
                  itemCount: items.length + 1,
                  separatorBuilder: (_, index) {
                    if (index == 0) return const SizedBox(height: 12);
                    return Divider(
                      height: 18,
                      color: chrome.line,
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        'Histórico 360',
                        style: TextStyle(
                          color: fxScreenInk(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }
                    return _Timeline360Tile(
                      item: items[index - 1],
                      isDark: isDark,
                    );
                  },
                ),
                  ),
                ),
          ),
    );
  }
}

class _Timeline360Item {
  final DateTime? at;
  final String kind;
  final String title;
  final String body;
  final String meta;
  final String priority;
  final IconData icon;
  final Color color;
  final String? deepLink;

  const _Timeline360Item({
    required this.at,
    required this.kind,
    required this.title,
    required this.body,
    required this.meta,
    required this.priority,
    required this.icon,
    required this.color,
    this.deepLink,
  });
}

class _Timeline360Tile extends StatelessWidget {
  final _Timeline360Item item;
  final bool isDark;

  const _Timeline360Tile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final link = item.deepLink;
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.kind,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _timelineDate(item.at),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: mute, fontSize: 12.2, height: 1.25),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MiniAutonomyChip(label: item.priority, color: item.color),
                  _MiniAutonomyChip(label: item.meta, color: mute),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    if (link != null && link.isNotEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(link),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: child,
        ),
      );
    }
    return child;
  }
}

String _timelineDate(DateTime? value) {
  if (value == null) return 'sem data';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month às $hour:$minute';
}
