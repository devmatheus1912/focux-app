import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';

final copilotActionsProvider = FutureProvider<List<FilaAcaoResumo>>((ref) {
  return ref
      .read(dashboardRepositoryProvider)
      .getIaCommandActions(status: 'ABERTO');
});

class CopilotActionsScreen extends ConsumerWidget {
  const CopilotActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final actionsAsync = ref.watch(copilotActionsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: ink, size: 18),
          onPressed: () => context.go('/dashboard/personal'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Command Center',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Tarefas do Copiloto',
              style: TextStyle(
                color: brand,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
      body: actionsAsync.when(
        loading:
            () => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:
                  (_, __) => Container(
                    height: 104,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line),
                    ),
                  ),
            ),
        error:
            (_, __) => _CopilotActionsEmpty(
              title: 'Não foi possível carregar',
              subtitle: 'Tente novamente em alguns instantes.',
              ink: ink,
              mute: mute,
              cardBg: cardBg,
              line: line,
              brand: brand,
              onRefresh: () => ref.invalidate(copilotActionsProvider),
            ),
        data: (actions) {
          if (actions.isEmpty) {
            return _CopilotActionsEmpty(
              title: 'Nenhuma tarefa aberta',
              subtitle:
                  'Quando o Copiloto criar uma tarefa, ela aparece aqui primeiro.',
              ink: ink,
              mute: mute,
              cardBg: cardBg,
              line: line,
              brand: brand,
              onRefresh: () => ref.invalidate(copilotActionsProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(copilotActionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _CopilotActionCard(
                  action: action,
                  cardBg: cardBg,
                  line: line,
                  ink: ink,
                  mute: mute,
                  brand: brand,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CopilotActionCard extends StatelessWidget {
  const _CopilotActionCard({
    required this.action,
    required this.cardBg,
    required this.line,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final FilaAcaoResumo action;
  final Color cardBg;
  final Color line;
  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: brand, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.titulo,
                      style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((action.sourceMode ?? '').isNotEmpty)
                          'Copiloto · ${action.sourceMode}',
                        action.prioridade,
                        action.sla,
                      ].join(' · '),
                      style: TextStyle(
                        color: brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: action.status, color: brand),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            action.descricao,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, fontSize: 12.4, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  action.acaoUrl.startsWith('/')
                      ? () => context.push(action.acaoUrl)
                      : null,
              icon: const Icon(Icons.person_outline, size: 16),
              label: Text(action.ctaLabel),
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

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

class _CopilotActionsEmpty extends StatelessWidget {
  const _CopilotActionsEmpty({
    required this.title,
    required this.subtitle,
    required this.ink,
    required this.mute,
    required this.cardBg,
    required this.line,
    required this.brand,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Color ink;
  final Color mute;
  final Color cardBg;
  final Color line;
  final Color brand;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: brand, size: 28),
            const SizedBox(height: 10),
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
      ),
    );
  }
}
