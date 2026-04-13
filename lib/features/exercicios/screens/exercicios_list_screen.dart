import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/exercicio_repository.dart';
import '../providers/exercicios_provider.dart';

class ExerciciosListScreen extends ConsumerWidget {
  const ExerciciosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciciosAsync = ref.watch(exerciciosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final criado = await context.push<bool>('/exercicios/novo');
          if (criado == true) ref.invalidate(exerciciosProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: exerciciosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (exercicios) => exercicios.isEmpty
            ? const Center(child: Text('Nenhum exercício cadastrado.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(exerciciosProvider),
                child: ListView.builder(
                  itemCount: exercicios.length,
                  itemBuilder: (context, i) => _ExercicioTile(exercicio: exercicios[i]),
                ),
              ),
      ),
    );
  }
}

class _ExercicioTile extends StatelessWidget {
  final Exercicio exercicio;
  const _ExercicioTile({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: exercicio.gifUrl != null
          ? SizedBox(
              width: 48, height: 48,
              child: Image.network(exercicio.gifUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center)),
            )
          : const CircleAvatar(child: Icon(Icons.fitness_center)),
      title: Text(exercicio.nome),
      subtitle: Text([exercicio.musculoAlvo, exercicio.categoria]
          .where((s) => s != null && s.isNotEmpty)
          .join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/exercicios/${exercicio.id}'),
    );
  }
}
