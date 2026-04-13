import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercicios_provider.dart';

class ExercicioDetailScreen extends ConsumerWidget {
  final int exercicioId;
  const ExercicioDetailScreen({super.key, required this.exercicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercicioAsync = ref.watch(exercicioProvider(exercicioId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercício')),
      body: exercicioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (ex) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ex.gifUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(ex.gifUrl!, height: 200, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              const SizedBox(height: 16),
              Text(ex.nome, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (ex.musculoAlvo != null)
                Chip(label: Text(ex.musculoAlvo!)),
              if (ex.categoria != null)
                Chip(label: Text(ex.categoria!)),
              if (ex.descricao != null && ex.descricao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Descrição', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(ex.descricao!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
