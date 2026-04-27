import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/exercicio_repository.dart';
import '../providers/exercicios_provider.dart';

const _categoriasFiltro = [
  'Todos',
  'Musculacao',
  'Mobilidade',
  'Lutas',
  'Yoga',
  'Funcional',
];

const _gruposFiltro = [
  'PEITO',
  'COSTAS',
  'OMBROS',
  'BICEPS',
  'TRICEPS',
  'PERNAS',
  'ABDOMEN',
  'CARDIO',
];

const _equipamentosFiltro = [
  'Peso corporal',
  'Halteres',
  'Barra',
  'Maquina',
  'Cabo',
  'Elastico',
  'Kettlebell',
  'Cardio',
];

const _niveisFiltro = ['Iniciante', 'Intermediario', 'Avancado'];
const _mecanicasFiltro = ['Composto', 'Isolado', 'Mobilidade', 'Cardio'];
const _objetivosFiltro = ['Forca', 'Hipertrofia', 'Emagrecimento', 'Condicionamento', 'Mobilidade'];

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
  String? _musculoFiltro;
  String? _equipamentoFiltro;
  String? _nivelFiltro;
  String? _mecanicaFiltro;
  String? _objetivoFiltro;

  @override
  void dispose() {
    _tagCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  String? get _categoriaParam => _categoriaFiltro == 'Todos' ? null : _categoriaFiltro;

  bool get _hasAdvancedFilters =>
      _musculoFiltro != null ||
      _equipamentoFiltro != null ||
      _nivelFiltro != null ||
      _mecanicaFiltro != null ||
      _objetivoFiltro != null;

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(exerciciosFilteredProvider(
      ExercicioFilter(
        categoria: _categoriaParam,
        tag: _tagFiltro.isEmpty ? null : _tagFiltro,
        musculoAlvo: _musculoFiltro,
        equipamento: _equipamentoFiltro,
        nivel: _nivelFiltro,
        mecanica: _mecanicaFiltro,
        objetivo: _objetivoFiltro,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATALOGO',
                          style: TextStyle(
                            fontSize: 12,
                            color: mute,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Exercicios',
                          style: TextStyle(
                            fontSize: 32,
                            color: ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _apenasFavoritos ? Icons.star : Icons.star_border,
                      color: _apenasFavoritos ? EagleTokens.warn : mute,
                    ),
                    tooltip: 'Apenas favoritos',
                    onPressed: () => setState(() => _apenasFavoritos = !_apenasFavoritos),
                  ),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _hasAdvancedFilters,
                      smallSize: 8,
                      child: Icon(Icons.tune_rounded, color: _hasAdvancedFilters ? Theme.of(context).colorScheme.primary : mute),
                    ),
                    tooltip: 'Filtros avancados',
                    onPressed: () => _openFilters(context),
                  ),
                  if (context.canPop())
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: mute),
                      onPressed: () => context.pop(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
            if (_hasAdvancedFilters)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    _ActiveFilterChip(label: _musculoFiltro, onDeleted: () => setState(() => _musculoFiltro = null)),
                    _ActiveFilterChip(label: _equipamentoFiltro, onDeleted: () => setState(() => _equipamentoFiltro = null)),
                    _ActiveFilterChip(label: _nivelFiltro, onDeleted: () => setState(() => _nivelFiltro = null)),
                    _ActiveFilterChip(label: _mecanicaFiltro, onDeleted: () => setState(() => _mecanicaFiltro = null)),
                    _ActiveFilterChip(label: _objetivoFiltro, onDeleted: () => setState(() => _objetivoFiltro = null)),
                  ],
                ),
              ),
            Expanded(
              child: exerciciosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (exercicios) {
                  final filtrados = _nomeFiltro.isEmpty
                      ? exercicios
                      : exercicios
                          .where((e) => e.nome.toLowerCase().contains(_nomeFiltro.toLowerCase()))
                          .toList();
                  if (filtrados.isEmpty) {
                    return const Center(child: Text('Nenhum exercicio encontrado.'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(exerciciosFilteredProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 96),
                      itemCount: filtrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
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

  Future<void> _openFilters(BuildContext context) async {
    var musculo = _musculoFiltro;
    var equipamento = _equipamentoFiltro;
    var nivel = _nivelFiltro;
    var mecanica = _mecanicaFiltro;
    var objetivo = _objetivoFiltro;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filtros da biblioteca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  _FilterDropdown(label: 'Grupo muscular', value: musculo, values: _gruposFiltro, onChanged: (v) => modalSetState(() => musculo = v)),
                  const SizedBox(height: 10),
                  _FilterDropdown(label: 'Equipamento', value: equipamento, values: _equipamentosFiltro, onChanged: (v) => modalSetState(() => equipamento = v)),
                  const SizedBox(height: 10),
                  _FilterDropdown(label: 'Nivel', value: nivel, values: _niveisFiltro, onChanged: (v) => modalSetState(() => nivel = v)),
                  const SizedBox(height: 10),
                  _FilterDropdown(label: 'Mecanica', value: mecanica, values: _mecanicasFiltro, onChanged: (v) => modalSetState(() => mecanica = v)),
                  const SizedBox(height: 10),
                  _FilterDropdown(label: 'Objetivo', value: objetivo, values: _objetivosFiltro, onChanged: (v) => modalSetState(() => objetivo = v)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            modalSetState(() {
                              musculo = null;
                              equipamento = null;
                              nivel = null;
                              mecanica = null;
                              objetivo = null;
                            });
                          },
                          child: const Text('Limpar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _musculoFiltro = musculo;
                              _equipamentoFiltro = equipamento;
                              _nivelFiltro = nivel;
                              _mecanicaFiltro = mecanica;
                              _objetivoFiltro = objetivo;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String? label;
  final VoidCallback onDeleted;

  const _ActiveFilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    if (label == null || label!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label!),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final card = isDark ? EagleTokens.darkCardHi : EagleTokens.card;
    final subtitle = [
      exercicio.musculoAlvo,
      exercicio.categoria,
      exercicio.equipamento,
      exercicio.nivel,
    ].where((s) => s != null && s.isNotEmpty).join(' | ');

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: line),
        ),
        leading: exercicio.gifUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Image.network(
                    exercicio.gifUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center),
                  ),
                ),
              )
            : const CircleAvatar(child: Icon(Icons.fitness_center)),
        title: Text(exercicio.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exercicio.videoUrl?.isNotEmpty == true)
              const Icon(Icons.play_circle_fill_rounded, color: EagleTokens.good),
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
      ),
    );
  }
}
