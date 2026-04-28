import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';

class CommandCenterWidget extends ConsumerWidget {
  const CommandCenterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandCenterAsync = ref.watch(commandCenterProvider);

    return commandCenterAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erro ao carregar Central: $e',
              style: const TextStyle(color: EagleTokens.bad),
            ),
          ),
      data: (data) {
        if (data.agendaHoje.isEmpty && data.filaAcoes.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommandHeader(total: data.filaAcoes.length),
            if (data.filaAcoes.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...data.filaAcoes.map((acao) => _CommandActionCard(action: acao)),
              const SizedBox(height: 16),
            ],
            if (data.agendaHoje.isNotEmpty) ...[
              Text(
                'Agenda de Hoje',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...data.agendaHoje.map((ag) => _AgendaTile(agendamento: ag)),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _CommandHeader extends StatelessWidget {
  final int total;

  const _CommandHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Central de Comando',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total acoes',
            style: TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CommandActionCard extends ConsumerWidget {
  final FilaAcaoResumo action;

  const _CommandActionCard({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final severityColor = _severityColor(action.severidade);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkCardHi : EagleTokens.card;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                label: action.prioridade,
                color: severityColor,
                filled: true,
              ),
              const SizedBox(width: 8),
              _Pill(label: action.severidade, color: severityColor),
              const SizedBox(width: 8),
              if (action.iaSugerida) _Pill(label: 'IA', color: primary),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 16, color: severityColor),
              const SizedBox(width: 4),
              Text(
                action.sla,
                style: TextStyle(
                  color: severityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            action.titulo,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.descricao,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 13,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  action.responsavel,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(dashboardRepositoryProvider)
                      .completeCommandAction(action.actionKey);
                  ref.invalidate(commandCenterProvider);
                },
                child: const Text('Concluir'),
              ),
              FilledButton(
                onPressed: () => context.push(action.acaoUrl),
                style: FilledButton.styleFrom(backgroundColor: primary),
                child: Text(action.ctaLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    if (severity == 'ALTA') return EagleTokens.bad;
    if (severity == 'MEDIA') return EagleTokens.warn;
    return const Color(0xFF2563EB);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _Pill({required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final AgendamentoResumo agendamento;

  const _AgendaTile({required this.agendamento});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event)),
        title: Text(
          agendamento.nomeAluno,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Horario: ${agendamento.horario.substring(11, 16)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                agendamento.status == 'CONFIRMADO'
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            agendamento.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  agendamento.status == 'CONFIRMADO'
                      ? const Color(0xFF166534)
                      : const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}
