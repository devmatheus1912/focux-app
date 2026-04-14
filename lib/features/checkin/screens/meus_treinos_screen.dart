import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/checkin_provider.dart';

class MeusTreinosScreen extends ConsumerWidget {
  const MeusTreinosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(meusTreinosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Treinos')),
      body: treinosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (treinos) => treinos.isEmpty
            ? const Center(child: Text('Nenhum treino atribuído ainda.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(meusTreinosProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: treinos.length,
                  itemBuilder: (context, i) {
                    final t = treinos[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                        title: Text(t.treinoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: FilledButton(
                          onPressed: () => context.push('/checkin/executar', extra: t.treinoId),
                          child: const Text('Iniciar'),
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
