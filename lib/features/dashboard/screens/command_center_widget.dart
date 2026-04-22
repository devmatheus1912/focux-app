import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';

class CommandCenterWidget extends ConsumerWidget {
  const CommandCenterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandCenterAsync = ref.watch(commandCenterProvider);

    return commandCenterAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Erro ao carregar Central: $e', style: const TextStyle(color: EagleTokens.bad)),
      ),
      data: (data) {
        if (data.agendaHoje.isEmpty && data.filaAcoes.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text('Central de Comando', 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ),
            
            if (data.filaAcoes.isNotEmpty) ...[
              ...data.filaAcoes.map((acao) => Card(
                color: acao.tipo == 'RISCO' ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: acao.tipo == 'RISCO' ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    acao.tipo == 'RISCO' ? Icons.warning : Icons.attach_money,
                    color: acao.tipo == 'RISCO' ? EagleTokens.bad : EagleTokens.warn,
                  ),
                  title: Text(acao.descricao, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(acao.acaoUrl),
                ),
              )),
              const SizedBox(height: 16),
            ],

            if (data.agendaHoje.isNotEmpty) ...[
              Text('Agenda de Hoje', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...data.agendaHoje.map((ag) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.event)),
                  title: Text(ag.nomeAluno, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Horário: ${ag.horario.substring(11, 16)}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ag.status == 'CONFIRMADO' ? const Color(0xFFDCFCE7) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(ag.status, style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ag.status == 'CONFIRMADO' ? const Color(0xFF166534) : const Color(0xFF1F2937),
                    )),
                  ),
                ),
              )),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}
