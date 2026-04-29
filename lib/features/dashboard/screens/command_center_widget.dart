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
        if (data.agendaHoje.isEmpty &&
            data.filaAcoes.isEmpty &&
            data.autonomiaGargalos.isEmpty) {
          return const _IaActionHistory();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommandHeader(total: data.filaAcoes.length),
            if (data.autonomiaGargalos.isNotEmpty) ...[
              const SizedBox(height: 10),
              _AutonomiaGargalosSection(gargalos: data.autonomiaGargalos),
              const SizedBox(height: 16),
            ],
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
            const _IaActionHistory(),
          ],
        );
      },
    );
  }
}

class _IaActionHistory extends ConsumerStatefulWidget {
  const _IaActionHistory();

  @override
  ConsumerState<_IaActionHistory> createState() => _IaActionHistoryState();
}

class _IaActionHistoryState extends ConsumerState<_IaActionHistory> {
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(dashboardRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return FutureBuilder<List<FilaAcaoResumo>>(
      future: repo.getIaCommandActions(status: _status),
      builder: (context, snapshot) {
        final actions = snapshot.data ?? const <FilaAcaoResumo>[];
        if (snapshot.connectionState == ConnectionState.waiting && actions.isEmpty) {
          return const SizedBox.shrink();
        }
        if (actions.isEmpty && _status.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Histórico IA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                DropdownButton<String>(
                  value: _status,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todas')),
                    DropdownMenuItem(value: 'ABERTO', child: Text('Abertas')),
                    DropdownMenuItem(value: 'ADIADO', child: Text('Adiadas')),
                    DropdownMenuItem(value: 'CONCLUIDO', child: Text('Concluidas')),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (actions.isEmpty)
              Text(
                'Nenhuma ação IA neste filtro.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...actions.take(6).map((action) => _IaHistoryTile(action: action)),
          ],
        );
      },
    );
  }
}

class _IaHistoryTile extends ConsumerWidget {
  final FilaAcaoResumo action;

  const _IaHistoryTile({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.titulo,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Pill(label: action.status, color: primary),
                    if (action.alunoId != null)
                      _Pill(label: 'Aluno ${action.alunoId}', color: primary),
                  ],
                ),
              ],
            ),
          ),
          if (action.status != 'ABERTO')
            TextButton(
              onPressed: () async {
                await ref
                    .read(dashboardRepositoryProvider)
                    .reopenCommandAction(action.actionKey);
                ref.invalidate(commandCenterProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ação reaberta.')),
                  );
                }
              },
              child: const Text('Reabrir'),
            ),
        ],
      ),
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

class _AutonomiaGargalosSection extends StatelessWidget {
  final List<AutonomiaGargaloResumo> gargalos;

  const _AutonomiaGargalosSection({required this.gargalos});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final topGargalos = gargalos.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gargalos de autonomia',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Pill(label: '${gargalos.length} ativos', color: primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Priorize alunos que pediram ajuda na pratica e ainda nao fecharam a tarefa.',
            style: TextStyle(color: mute, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          for (final gargalo in topGargalos) ...[
            _AutonomiaGargaloTile(gargalo: gargalo),
            if (gargalo != topGargalos.last)
              Divider(
                height: 16,
                color: isDark ? EagleTokens.darkLine : EagleTokens.line,
              ),
          ],
        ],
      ),
    );
  }
}

class _AutonomiaGargaloTile extends StatelessWidget {
  final AutonomiaGargaloResumo gargalo;

  const _AutonomiaGargaloTile({required this.gargalo});

  String _actionLabel(String action) {
    switch (action.toUpperCase()) {
      case 'CLICKED':
        return 'Clicou';
      case 'COMPLETED':
        return 'Concluiu';
      case 'VIEWED':
        return 'Viu';
      default:
        return action;
    }
  }

  String _dateLabel(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return '--';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final openClicks = gargalo.cliques - gargalo.concluidos;
    final pendingLabel = openClicks == 1 ? '1 clique aberto' : '$openClicks cliques abertos';

    final icon = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: EagleTokens.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.touch_app_outlined,
        color: EagleTokens.warn,
        size: 18,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          gargalo.alunoNome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          gargalo.taskTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: mute, fontSize: 12.5, height: 1.25),
        ),
        const SizedBox(height: 4),
        Text(
          _suggestedAction(gargalo.taskId),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _Pill(label: pendingLabel, color: EagleTokens.warn),
            _Pill(label: gargalo.prioridade, color: primary),
            _Pill(
              label: _actionLabel(gargalo.ultimaAcao),
              color: primary,
            ),
            _Pill(label: _dateLabel(gargalo.ultimoEventoEm), color: mute),
          ],
        ),
      ],
    );
    final action = IconButton.filledTonal(
      onPressed: () => context.push(gargalo.acaoUrl),
      icon: const Icon(Icons.arrow_forward_rounded),
      tooltip: 'Abrir aluno',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(child: copy),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: action,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(child: copy),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 52),
              child: action,
            ),
          ],
        );
      },
    );
  }
}

String _suggestedAction(String taskId) {
  return switch (taskId) {
    'perfil-base' || 'foto-dados' => 'Peca os dados que faltam e explique por que isso melhora o acompanhamento.',
    'medida-recente' => 'Convide o aluno a registrar medida ou envie um lembrete com prazo curto.',
    'chat-contexto' => 'Abra conversa com uma pergunta objetiva para destravar o contexto.',
    'agenda-semana' => 'Confirme o melhor horario e reduza atrito de agenda.',
    'financeiro' => 'Oriente regularizacao antes de bloquear acesso.',
    'treino-semana' => 'Confirme treino ativo e remova barreira para executar.',
    _ => 'Abra a ficha e resolva o proximo passo com o aluno.',
  };
}

class _CommandActionCard extends ConsumerWidget {
  final FilaAcaoResumo action;

  const _CommandActionCard({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final severityColor = _severityColor(action.severidade, primary);
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
              TextButton(
                onPressed: () async {
                  await ref
                      .read(dashboardRepositoryProvider)
                      .snoozeCommandAction(action.actionKey);
                  ref.invalidate(commandCenterProvider);
                },
                child: const Text('Adiar'),
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

  Color _severityColor(String severity, Color fallback) {
    if (severity == 'ALTA') return EagleTokens.bad;
    if (severity == 'MEDIA') return EagleTokens.warn;
    return fallback;
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
