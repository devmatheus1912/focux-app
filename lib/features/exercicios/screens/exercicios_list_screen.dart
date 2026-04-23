import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
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
  final _nomeCtrl = TextEditingController();
  String _tagFiltro = '';
  String _nomeFiltro = '';

  @override
  void dispose() {
    _tagCtrl.dispose();
    _nomeCtrl.dispose();
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandInk]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: EagleTokens.brand.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final criado = await context.push<bool>('/exercicios/novo');
            if (criado == true) ref.invalidate(exerciciosFilteredProvider);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CATÁLOGO',
                        style: TextStyle(
                          fontSize: 12,
                          color: mute,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exercícios',
                        style: TextStyle(
                          fontSize: 32,
                          color: ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _apenasFavoritos ? Icons.star : Icons.star_border,
                          color: _apenasFavoritos ? EagleTokens.warn : mute,
                        ),
                        tooltip: 'Apenas favoritos',
                        onPressed: () => setState(() => _apenasFavoritos = !_apenasFavoritos),
                      ),
                      if (context.canPop())
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: mute),
                          onPressed: () => context.pop(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Busca por nome
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                controller: _nomeCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _nomeFiltro.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _nomeCtrl.clear();
                            setState(() => _nomeFiltro = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _nomeFiltro = v.trim()),
              ),
            ),
            const SizedBox(height: 6),
            // Filtro por tag
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
                data: (exercicios) {
                  final filtrados = _nomeFiltro.isEmpty
                      ? exercicios
                      : exercicios
                          .where((e) => e.nome
                              .toLowerCase()
                              .contains(_nomeFiltro.toLowerCase()))
                          .toList();
                  if (filtrados.isEmpty) {
                    return const Center(child: Text('Nenhum exercício encontrado.'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(exerciciosFilteredProvider),
                    child: ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (context, i) => _ExercicioTile(
                        exercicio: filtrados[i],
                        onFavoritoToggle: () => ref.invalidate(exerciciosFilteredProvider),
                      ),
                    ),
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
    } catch (e) {
      debugPrint('[Focux] Error: $e');
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
              width: 48,
              height: 48,
              child: Image.network(
                exercicio.gifUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center),
              ),
            )
          : const CircleAvatar(child: Icon(Icons.fitness_center)),
      title: Text(exercicio.nome),
      subtitle: Text(
        [exercicio.musculoAlvo, exercicio.categoria]
            .where((s) => s != null && s.isNotEmpty)
            .join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              exercicio.favoritado ? Icons.star : Icons.star_border,
              color: exercicio.favoritado ? EagleTokens.warn : null,
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
