import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/exercicio_repository.dart';
import '../providers/exercicios_provider.dart';

// Categorias disponíveis nos chips de filtro
const _categoriasFiltro = [
  'Todos',
  'Musculação',
  'Mobilidade',
  'Lutas',
  'Yoga',
  'Funcional',
];

class ExerciciosListScreen extends ConsumerStatefulWidget {
  const ExerciciosListScreen({super.key});

  @override
  ConsumerState<ExerciciosListScreen> createState() => _ExerciciosListScreenState();
}

class _ExerciciosListScreenState extends ConsumerState<ExerciciosListScreen> {
  String _categoriaFiltro = 'Todos';
  bool _apenasFavoritos = false;
  final _tagCtrl = TextEditingController();
  String _tagFiltro = '';

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  String? get _categoriaParam =>
      _categoriaFiltro == 'Todos' ? null : _categoriaFiltro;

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(exerciciosFilteredProvider(
      ExercicioFilter(
        categoria: _categoriaParam,
        tag: _tagFiltro.isEmpty ? null : _tagFiltro,
        favoritos: _apenasFavoritos ? true : null,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercícios'),
        actions: [
          IconButton(
            icon: Icon(
              _apenasFavoritos ? Icons.star : Icons.star_border,
              color: _apenasFavoritos ? Colors.amber : null,
            ),
            tooltip: 'Apenas favoritos',
            onPressed: () => setState(() => _apenasFavoritos = !_apenasFavoritos),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final criado = await context.push<bool>('/exercicios/novo');
          if (criado == true) ref.invalidate(exerciciosFilteredProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filtro por tag
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _tagCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por tag (ex: #EmCasa)',
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: _tagFiltro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _tagCtrl.clear();
                          setState(() => _tagFiltro = '');
                        },
                      )
                    : null,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _tagFiltro = v.trim()),
            ),
          ),
          // Chips de categoria
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categoriasFiltro.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categoriasFiltro[i];
                final selecionado = cat == _categoriaFiltro;
                return FilterChip(
                  label: Text(cat),
                  selected: selecionado,
                  onSelected: (_) => setState(() => _categoriaFiltro = cat),
                );
              },
            ),
          ),
          // Lista de exercícios
          Expanded(
            child: exerciciosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (exercicios) => exercicios.isEmpty
                  ? const Center(child: Text('Nenhum exercício encontrado.'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(exerciciosFilteredProvider),
                      child: ListView.builder(
                        itemCount: exercicios.length,
                        itemBuilder: (context, i) => _ExercicioTile(
                          exercicio: exercicios[i],
                          onFavoritoToggle: () => ref.invalidate(exerciciosFilteredProvider),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercicioTile extends ConsumerWidget {
  final Exercicio exercicio;
  final VoidCallback onFavoritoToggle;
  const _ExercicioTile({required this.exercicio, required this.onFavoritoToggle});

  Future<void> _toggleFavorito(WidgetRef ref, BuildContext context) async {
    final repo = ref.read(exercicioRepositoryProvider);
    try {
      if (exercicio.favoritado) {
        await repo.desfavoritarExercicio(exercicio.id);
      } else {
        await repo.favoritarExercicio(exercicio.id);
      }
      onFavoritoToggle();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar favorito.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              exercicio.favoritado ? Icons.star : Icons.star_border,
              color: exercicio.favoritado ? Colors.amber : null,
            ),
            tooltip: exercicio.favoritado ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            onPressed: () => _toggleFavorito(ref, context),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.push('/exercicios/${exercicio.id}'),
    );
  }
}
