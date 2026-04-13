import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/treinos_provider.dart';

class TreinoDetailScreen extends ConsumerWidget {
  final int treinoId;
  const TreinoDetailScreen({super.key, required this.treinoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinoAsync = ref.watch(treinoProvider(treinoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar exercício',
            onPressed: () async {
              final adicionado = await context.push<bool>(
                  '/treinos/$treinoId/exercicios/add');
              if (adicionado == true) ref.invalidate(treinoProvider(treinoId));
            },
          ),
        ],
      ),
      body: treinoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (treino) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(treino.nome, style: Theme.of(context).textTheme.headlineSmall),
                  if (treino.nivel != null) Chip(label: Text(treino.nivel!)),
                  if (treino.objetivo != null)
                    Text(treino.objetivo!, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: treino.exercicios.isEmpty
                  ? const Center(child: Text('Nenhum exercício no treino.'))
                  : ListView.builder(
                      itemCount: treino.exercicios.length,
                      itemBuilder: (context, i) {
                        final te = treino.exercicios[i];
                        return ListTile(
                          leading: Text('${i + 1}', style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                          title: Text(te.exercicio.nome),
                          subtitle: Text('${te.series}x${te.repeticoes}'
                              '${te.cargaKg != null ? ' · ${te.cargaKg}kg' : ''}'),
                          trailing: te.descansoSegundos != null
                              ? Text('${te.descansoSegundos}s',
                                  style: const TextStyle(color: Colors.grey))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
