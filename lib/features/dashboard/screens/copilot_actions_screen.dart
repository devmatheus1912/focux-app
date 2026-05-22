import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_dock.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

final iaActionsProvider = FutureProvider.family<List<FilaAcaoResumo>, String>((
  ref,
  status,
) {
  return ref
      .read(dashboardRepositoryProvider)
      .getIaCommandActions(status: status);
});

class CopilotActionsScreen extends ConsumerStatefulWidget {
  const CopilotActionsScreen({super.key});

  @override
  ConsumerState<CopilotActionsScreen> createState() =>
      _CopilotActionsScreenState();
}

class _CopilotActionsScreenState extends ConsumerState<CopilotActionsScreen> {
  String _status = 'ABERTO';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final actionsAsync = ref.watch(iaActionsProvider(_status));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Tarefas IA',
        subtitle: 'Command Center',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SafeArea(
          top: false,
          child: FxDock(
            items: FxDockItems.personal,
            currentIndex: 4,
            isDark: dark,
            onTap: (index) {
              final path = switch (index) {
                0 => '/dashboard/personal',
                1 => '/alunos',
                2 => '/treinos',
                3 => '/agenda',
                _ => '/ia/copiloto',
              };
              context.go(path);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: _StatusSegmentedControl(
              selected: _status,
              brand: brand,
              ink: ink,
              mute: mute,
              onChanged: (value) => setState(() => _status = value),
            ),
          ),
          Expanded(
            child: actionsAsync.when(
              loading:
                  () => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder:
                        (_, __) => Container(
                          height: 94,
                          decoration: fxListCardDecoration(
                            context,
                            radius: 16,
                          ),
                        ),
                  ),
              error:
                  (_, __) => _IaActionsEmpty(
                    title: 'Não foi possível carregar',
                    subtitle: 'Puxe para atualizar ou tente novamente.',
                    ink: ink,
                    mute: mute,
                    brand: brand,
                    onRefresh: _refresh,
                  ),
              data: (actions) {
                final copilot =
                    actions
                        .where((action) => action.tipo == 'IA_COPILOTO')
                        .toList();
                final radar =
                    actions
                        .where((action) => action.tipo != 'IA_COPILOTO')
                        .toList();

                if (actions.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        _IaActionsEmptyCard(
                          title: _emptyTitle(_status),
                          subtitle: _emptySubtitle(_status),
                          ink: ink,
                          mute: mute,
                          brand: brand,
                          onRefresh: _refresh,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                    children: [
                      if (copilot.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Copiloto',
                          detail: _sectionDetail(_status, copilot.length),
                          ink: ink,
                          mute: mute,
                        ),
                        const SizedBox(height: 8),
                        for (final entry in copilot.asMap().entries) ...[
                          _CopilotTaskCard(
                            action: entry.value,
                            status: _status,
                            highlighted: _status == 'ABERTO' && entry.key == 0,
                            ink: ink,
                            mute: mute,
                            brand: brand,
                            onOpen: () => _openAction(context, entry.value),
                            onComplete: () => _complete(entry.value),
                            onSnooze: () => _snooze(entry.value),
                            onReopen: () => _reopen(entry.value),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                      if (radar.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _SectionHeader(
                          title: 'Sinais automáticos',
                          detail: '${radar.length} sinais',
                          ink: ink,
                          mute: mute,
                        ),
                        const SizedBox(height: 8),
                        for (final action in radar) ...[
                          _RadarSignalCard(
                            action: action,
                            status: _status,
                            ink: ink,
                            mute: mute,
                            brand: brand,
                            onOpen: () => _openAction(context, action),
                            onComplete: () => _complete(action),
                            onSnooze: () => _snooze(action),
                            onReopen: () => _reopen(action),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(iaActionsProvider(_status));
    await ref.read(iaActionsProvider(_status).future);
  }

  void _openAction(BuildContext context, FilaAcaoResumo action) {
    if (action.acaoUrl.startsWith('/')) {
      context.push(action.acaoUrl);
    }
  }

  Future<void> _complete(FilaAcaoResumo action) async {
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .completeCommandAction(action.actionKey),
      'Tarefa concluída',
    );
  }

  Future<void> _snooze(FilaAcaoResumo action) async {
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .snoozeCommandAction(action.actionKey, hours: 24),
      'Tarefa adiada por 24h',
    );
  }

  Future<void> _reopen(FilaAcaoResumo action) async {
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .reopenCommandAction(action.actionKey),
      'Tarefa reaberta',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(iaActionsProvider(_status));
      ref.invalidate(commandCenterProvider);
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(successMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Não foi possível atualizar a tarefa.')),
      );
    }
  }
}

class _StatusSegmentedControl extends StatelessWidget {
  const _StatusSegmentedControl({
    required this.selected,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.onChanged,
  });

  final String selected;
  final Color brand;
  final Color ink;
  final Color mute;
  final ValueChanged<String> onChanged;

  static const _items = [
    ('ABERTO', 'Abertas'),
    ('ADIADO', 'Adiadas'),
    ('CONCLUIDO', 'Concluídas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: fxListCardDecoration(context, radius: 16),
      child: Row(
        children:
            _items.map((item) {
              final active = item.$1 == selected;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? brand : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow:
                          active
                              ? [
                                BoxShadow(
                                  color: brand.withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        color: active ? Colors.white : mute,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.detail,
    required this.ink,
    required this.mute,
  });

  final String title;
  final String detail;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          detail,
          style: TextStyle(
            color: mute,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CopilotTaskCard extends StatelessWidget {
  const _CopilotTaskCard({
    required this.action,
    required this.status,
    required this.highlighted,
    required this.ink,
    required this.mute,
    required this.brand,
    required this.onOpen,
    required this.onComplete,
    required this.onSnooze,
    required this.onReopen,
  });

  final FilaAcaoResumo action;
  final String status;
  final bool highlighted;
  final Color ink;
  final Color mute;
  final Color brand;
  final VoidCallback onOpen;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final mode = _modeLabel(action);
    final isDone = status == 'CONCLUIDO';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration:
          highlighted
              ? fxListCardDecoration(
                context,
                accent: brand,
                selected: true,
                radius: 16,
              )
              : fxListCardDecoration(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted) ...[
            Text(
              'Próxima ação',
              style: TextStyle(
                color: brand,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaskIcon(icon: Icons.auto_awesome, brand: brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.titulo,
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
                      'Copiloto · $mode',
                      style: TextStyle(
                        color: brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _CompactPill(
                label: _deadlineLabel(action, status),
                color: isDone ? mute : brand,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            action.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, fontSize: 12, height: 1.32),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child:
                    isDone
                        ? OutlinedButton.icon(
                          onPressed:
                              action.acaoUrl.startsWith('/') ? onOpen : null,
                          icon: const Icon(Icons.person_outline, size: 15),
                          label: const Text('Ver aluno'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brand,
                            minimumSize: const Size.fromHeight(38),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                        : FilledButton.icon(
                          onPressed:
                              action.acaoUrl.startsWith('/') ? onOpen : null,
                          icon: const Icon(Icons.person_outline, size: 15),
                          label: const Text('Revisar aluno'),
                          style: FilledButton.styleFrom(
                            backgroundColor: brand,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(38),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
              ),
              const SizedBox(width: 8),
              if (isDone)
                _MiniActionButton(label: 'Reabrir', onPressed: onReopen)
              else ...[
                _MiniActionButton(label: 'Adiar', onPressed: onSnooze),
                const SizedBox(width: 6),
                _MiniActionButton(label: 'Concluir', onPressed: onComplete),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarSignalCard extends StatelessWidget {
  const _RadarSignalCard({
    required this.action,
    required this.status,
    required this.ink,
    required this.mute,
    required this.brand,
    required this.onOpen,
    required this.onComplete,
    required this.onSnooze,
    required this.onReopen,
  });

  final FilaAcaoResumo action;
  final String status;
  final Color ink;
  final Color mute;
  final Color brand;
  final VoidCallback onOpen;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context, radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskIcon(icon: Icons.sensors, brand: brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CompactPill(label: action.prioridade, color: brand),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  action.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: mute, fontSize: 11.8, height: 1.3),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TextAction(label: action.ctaLabel, onPressed: onOpen),
                    if (status == 'CONCLUIDO')
                      _TextAction(label: 'Reabrir', onPressed: onReopen)
                    else ...[
                      _TextAction(label: 'Adiar', onPressed: onSnooze),
                      _TextAction(label: 'Concluir', onPressed: onComplete),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  const _TaskIcon({required this.icon, required this.brand});

  final IconData icon;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: brand, size: 17),
    );
  }
}

class _CompactPill extends StatelessWidget {
  const _CompactPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: primary.withValues(alpha: 0.07),
        foregroundColor: primary,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Text(label),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _IaActionsEmpty extends StatelessWidget {
  const _IaActionsEmpty({
    required this.title,
    required this.subtitle,
    required this.ink,
    required this.mute,
    required this.brand,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Color ink;
  final Color mute;
  final Color brand;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _IaActionsEmptyCard(
            title: title,
            subtitle: subtitle,
            ink: ink,
            mute: mute,
            brand: brand,
            onRefresh: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _IaActionsEmptyCard extends StatelessWidget {
  const _IaActionsEmptyCard({
    required this.title,
    required this.subtitle,
    required this.ink,
    required this.mute,
    required this.brand,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Color ink;
  final Color mute;
  final Color brand;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: fxListCardDecoration(context, accent: brand, radius: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.task_alt, color: brand, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Tudo em ordem',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: brand,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}

String _modeLabel(FilaAcaoResumo action) {
  final raw = (action.sourceMode ?? '').trim();
  if (raw.isEmpty) return 'Treino';
  final lower = raw.toLowerCase();
  return lower.substring(0, 1).toUpperCase() + lower.substring(1);
}

String _deadlineLabel(FilaAcaoResumo action, String status) {
  if (status == 'CONCLUIDO') return 'concluída';
  if (status == 'ADIADO') return 'adiada';
  final dueAt = DateTime.tryParse(action.dueAt ?? '');
  if (dueAt == null) {
    final sla = action.sla.trim();
    if (sla.isEmpty) return 'vence em 24h';
    return sla.toLowerCase().contains('vence') ? sla : 'vence em $sla';
  }
  final diff = dueAt.difference(DateTime.now());
  if (diff.isNegative) return 'atrasada';
  final hours = diff.inHours.clamp(1, 999);
  return 'vence em ${hours}h';
}

String _sectionDetail(String status, int count) {
  final suffix = switch (status) {
    'ADIADO' => 'adiadas',
    'CONCLUIDO' => 'concluídas',
    _ => 'abertas',
  };
  return '$count $suffix';
}

String _emptyTitle(String status) {
  return switch (status) {
    'ADIADO' => 'Nenhuma tarefa adiada',
    'CONCLUIDO' => 'Nenhuma tarefa concluída',
    _ => 'Nenhuma tarefa IA aberta',
  };
}

String _emptySubtitle(String status) {
  return switch (status) {
    'ADIADO' => 'Quando uma ação for adiada, ela fica guardada aqui.',
    'CONCLUIDO' => 'As tarefas resolvidas aparecem aqui para auditoria.',
    _ => 'Copiloto e Radar Focux aparecem aqui quando exigem ação humana.',
  };
}
