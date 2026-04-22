import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/checkin_provider.dart';

class HistoricoCheckinScreen extends ConsumerWidget {
  const HistoricoCheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historicoAsync = ref.watch(historicoCheckinProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,title: const Text('Histórico de Treinos')),
      body: historicoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (historico) => historico.isEmpty
            ? const Center(child: Text('Nenhum treino realizado ainda.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(historicoCheckinProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historico.length,
                  itemBuilder: (context, i) {
                    final e = historico[i];
                    final concluido = e.status == 'CONCLUIDO';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          concluido ? Icons.check_circle : Icons.pending,
                          color: concluido ? EagleTokens.good : EagleTokens.warn,
                        ),
                        title: Text(e.treinoNome),
                        subtitle: Text(e.iniciadoEm ?? ''),
                        trailing: Chip(
                          label: Text(concluido ? 'Concluído' : 'Em andamento'),
                          backgroundColor: concluido
                              ? EagleTokens.good.withValues(alpha: 0.12)
                              : EagleTokens.warn.withValues(alpha: 0.12),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
