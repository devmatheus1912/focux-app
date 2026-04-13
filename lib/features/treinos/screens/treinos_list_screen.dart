import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';

class TreinosListScreen extends ConsumerWidget {
  const TreinosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(treinosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final criado = await context.push<bool>('/treinos/novo');
          if (criado == true) ref.invalidate(treinosProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: treinosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (treinos) => treinos.isEmpty
            ? const Center(child: Text('Nenhum treino cadastrado.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(treinosProvider),
                child: ListView.builder(
                  itemCount: treinos.length,
                  itemBuilder: (context, i) => _TreinoTile(treino: treinos[i]),
                ),
              ),
      ),
    );
  }
}

class _TreinoTile extends StatelessWidget {
  final Treino treino;
  const _TreinoTile({required this.treino});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.list_alt)),
      title: Text(treino.nome),
      subtitle: Text('${treino.exercicios.length} exercício(s)'
          '${treino.nivel != null ? ' · ${treino.nivel}' : ''}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/treinos/${treino.id}'),
    );
  }
}
