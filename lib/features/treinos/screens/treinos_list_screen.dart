import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';

class TreinosListScreen extends ConsumerWidget {
  final int? alunoId;
  final String? alunoNome;

  const TreinosListScreen({super.key, this.alunoId, this.alunoNome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TreinosListView(alunoId: alunoId, alunoNome: alunoNome);
  }
}

class _TreinosListView extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const _TreinosListView({required this.alunoId, required this.alunoNome});

  @override
  ConsumerState<_TreinosListView> createState() => _TreinosListViewState();
}

class _TreinosListViewState extends ConsumerState<_TreinosListView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  String _query = '';
  bool _selectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(Treino treino) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      treino.nome,
      treino.objetivo,
      treino.descricao,
      treino.nivel,
      '${treino.exercicios.length} exercicios',
      treino.isTemplate ? 'template base' : null,
    ].whereType<String>().any((value) => value.toLowerCase().contains(query));
  }

  void _toggleSelection(int id) {
    setState(() {
      _selectionMode = true;
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _startSelection(int id) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteTreinos(List<Treino> treinos) async {
    if (treinos.isEmpty) return;
    final count = treinos.length;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _DeleteWorkoutSheet(
            count: count,
            name: count == 1 ? treinos.first.nome : null,
            unlinkOnly: widget.alunoId != null,
          ),
    );
    if (confirmed != true) return;

    final repository = ref.read(treinoRepositoryProvider);
    try {
      for (final treino in treinos) {
        if (widget.alunoId == null) {
          await repository.excluirTreino(treino.id);
        } else {
          await repository.desvincularAluno(widget.alunoId!, treino.id);
        }
      }
      _clearSelection();
      if (widget.alunoId == null) {
        ref.invalidate(treinosProvider);
      } else {
        ref.invalidate(treinosDoAlunoProvider(widget.alunoId!));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? 'Treino removido.' : '$count treinos removidos.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nao foi possivel remover: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final treinosAsync =
        widget.alunoId == null
            ? ref.watch(treinosProvider)
            : ref.watch(treinosDoAlunoProvider(widget.alunoId!));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;

    Future<void> refresh() async {
      if (widget.alunoId == null) {
        ref.invalidate(treinosProvider);
      } else {
        ref.invalidate(treinosDoAlunoProvider(widget.alunoId!));
      }
    }

    Future<void> createWorkout() async {
      final criado = await context.push<bool>(
        '/treinos/novo',
        extra:
            widget.alunoId == null
                ? null
                : {'alunoId': widget.alunoId, 'alunoNome': widget.alunoNome},
      );
      if (criado == true) {
        await refresh();
      }
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: treinosAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.fromLTRB(20, 86, 20, 0),
                child: SkeletonList(count: 5),
              ),
          error:
              (e, _) => _TreinosErrorState(
                isDark: isDark,
                primary: primary,
                onRetry: refresh,
              ),
          data: (treinos) {
            final filteredTreinos = treinos.where(_matchesQuery).toList();
            final selectedTreinos =
                treinos
                    .where((treino) => _selectedIds.contains(treino.id))
                    .toList();

            return RefreshIndicator(
              color: primary,
              onRefresh: refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _TreinosHeader(
                      treinos: treinos,
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
                      isDark: isDark,
                      onBack:
                          () => safePopOrGo(
                            context,
                            widget.alunoId == null
                                ? '/dashboard/personal'
                                : '/alunos/${widget.alunoId}',
                          ),
                    ),
                  ),
                  if (treinos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        isDark: isDark,
                        primary: primary,
                        onCreate: createWorkout,
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: _TreinosCommandCard(
                          treinos: treinos,
                          isDark: isDark,
                          primary: primary,
                          onCreate: createWorkout,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: _LibraryControls(
                          controller: _searchController,
                          query: _query,
                          selectedCount: _selectedIds.length,
                          selectionMode: _selectionMode,
                          isDark: isDark,
                          primary: primary,
                          onQueryChanged:
                              (value) => setState(() => _query = value),
                          onClearQuery:
                              () => setState(() {
                                _query = '';
                                _searchController.clear();
                              }),
                          onSelectAll:
                              filteredTreinos.isEmpty
                                  ? null
                                  : () {
                                    setState(() {
                                      _selectionMode = true;
                                      _selectedIds
                                        ..clear()
                                        ..addAll(
                                          filteredTreinos.map(
                                            (treino) => treino.id,
                                          ),
                                        );
                                    });
                                  },
                          onCancelSelection: _clearSelection,
                          onDeleteSelected:
                              selectedTreinos.isEmpty
                                  ? null
                                  : () => _deleteTreinos(selectedTreinos),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _SectionHeader(
                          title:
                              widget.alunoId == null
                                  ? 'Biblioteca ativa'
                                  : 'Plano do aluno',
                          action:
                              _query.trim().isEmpty
                                  ? '${treinos.length} planos'
                                  : '${filteredTreinos.length} de ${treinos.length}',
                          isDark: isDark,
                        ),
                      ),
                    ),
                    if (filteredTreinos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoResultsState(
                          isDark: isDark,
                          primary: primary,
                          onClear:
                              () => setState(() {
                                _query = '';
                                _searchController.clear();
                              }),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
                        sliver: SliverList.separated(
                          itemCount: filteredTreinos.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder:
                              (context, i) => _TreinoCard(
                                treino: filteredTreinos[i],
                                index: i,
                                isDark: isDark,
                                primary: primary,
                                selectionMode: _selectionMode,
                                selected: _selectedIds.contains(
                                  filteredTreinos[i].id,
                                ),
                                onToggleSelection:
                                    () =>
                                        _toggleSelection(filteredTreinos[i].id),
                                onStartSelection:
                                    () =>
                                        _startSelection(filteredTreinos[i].id),
                                onDelete:
                                    () => _deleteTreinos([filteredTreinos[i]]),
                              ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeleteWorkoutSheet extends StatelessWidget {
  final int count;
  final String? name;
  final bool unlinkOnly;

  const _DeleteWorkoutSheet({
    required this.count,
    required this.name,
    required this.unlinkOnly,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final dangerFill =
        isDark ? const Color(0xFFB24646) : const Color(0xFFA83A3A);
    final dangerSoft =
        isDark
            ? EagleTokens.bad.withValues(alpha: 0.16)
            : EagleTokens.badSoft.withValues(alpha: 0.88);
    final actionLabel = unlinkOnly ? 'Desvincular' : 'Remover';
    final title =
        unlinkOnly
            ? count == 1
                ? 'Desvincular treino?'
                : 'Desvincular treinos?'
            : count == 1
            ? 'Remover da biblioteca?'
            : 'Remover treinos?';
    final subject = name ?? '$count treinos selecionados';
    final body =
        unlinkOnly
            ? count == 1
                ? '$subject sai do aluno, mas continua na sua biblioteca.'
                : '$subject saem destes alunos, mas continuam na sua biblioteca.'
            : count == 1
            ? '$subject sai da biblioteca. Historicos ja concluidos continuam preservados.'
            : '$subject saem da biblioteca. Historicos ja concluidos continuam preservados.';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 18),
                spreadRadius: -18,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: dangerSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: EagleTokens.bad,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            color: mute,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkBg : const Color(0xFFF7F7F4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: mute, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        unlinkOnly
                            ? 'O aluno perde o acesso a este plano.'
                            : 'Historico e execucoes antigas nao sao apagados.',
                        style: TextStyle(
                          color: mute,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(color: line),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: dangerFill,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreinosHeader extends StatelessWidget {
  final List<Treino> treinos;
  final int? alunoId;
  final String? alunoNome;
  final bool isDark;
  final VoidCallback onBack;

  const _TreinosHeader({
    required this.treinos,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final primary = Theme.of(context).colorScheme.primary;
    final ready = treinos.where((t) => t.exercicios.isNotEmpty).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: ink),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
              side: BorderSide(
                color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alunoId == null
                      ? '$ready PRONTOS  /  ${treinos.length} PLANOS'
                      : 'TREINOS DO ALUNO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alunoId == null
                      ? 'Treinos'
                      : alunoNome == null || alunoNome!.trim().isEmpty
                      ? 'Treinos do aluno'
                      : 'Treinos de ${alunoNome!.trim()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 28,
                    height: 1,
                    color: ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${treinos.length} ativos',
              style: TextStyle(
                color: primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreinosCommandCard extends StatelessWidget {
  final List<Treino> treinos;
  final bool isDark;
  final Color primary;
  final VoidCallback onCreate;

  const _TreinosCommandCard({
    required this.treinos,
    required this.isDark,
    required this.primary,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primaryDeep = BrandPalette.deep(primary);
    final totalExercises = treinos.fold<int>(
      0,
      (sum, treino) => sum + treino.exercicios.length,
    );
    final ready = treinos.where((t) => t.exercicios.isNotEmpty).length;
    final templates = treinos.where((t) => t.isTemplate).length;
    final assembling = treinos.length - ready;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryDeep],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.14 : 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biblioteca sob controle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      assembling == 0
                          ? 'Todos os planos têm exercícios.'
                          : '$assembling plano${assembling == 1 ? '' : 's'} ainda em montagem.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: onCreate,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text(
                  'Novo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CommandMetric(
                  label: 'prontos',
                  value: '$ready',
                  textColor: ink,
                  muteColor: mute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CommandMetric(
                  label: 'exercícios',
                  value: '$totalExercises',
                  textColor: ink,
                  muteColor: mute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CommandMetric(
                  label: 'templates',
                  value: '$templates',
                  textColor: ink,
                  muteColor: mute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommandMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color muteColor;

  const _CommandMetric({
    required this.label,
    required this.value,
    required this.textColor,
    required this.muteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
        ),
        Text(
          action,
          style: TextStyle(
            color: mute,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LibraryControls extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final int selectedCount;
  final bool selectionMode;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback? onSelectAll;
  final VoidCallback onCancelSelection;
  final VoidCallback? onDeleteSelected;

  const _LibraryControls({
    required this.controller,
    required this.query,
    required this.selectedCount,
    required this.selectionMode,
    required this.isDark,
    required this.primary,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSelectAll,
    required this.onCancelSelection,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark
                ? EagleTokens.darkCard
                : BrandPalette.soft(
                  primary,
                  dark: false,
                ).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark
                  ? line
                  : primary.withValues(alpha: selectionMode ? 0.28 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child:
                selectionMode
                    ? Row(
                      key: const ValueKey('selection-toolbar'),
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$selectedCount selecionado${selectedCount == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              Text(
                                'Acoes em lote',
                                style: TextStyle(
                                  color: mute,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onCancelSelection,
                          tooltip: 'Cancelar selecao',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                isDark
                                    ? EagleTokens.darkBg
                                    : Colors.white.withValues(alpha: 0.72),
                          ),
                          icon: Icon(
                            Icons.close_rounded,
                            color: mute,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.icon(
                          onPressed: onDeleteSelected,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                          ),
                          label: const Text('Excluir'),
                          style: FilledButton.styleFrom(
                            backgroundColor: EagleTokens.bad,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    )
                    : Row(
                      key: const ValueKey('normal-toolbar'),
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Operacoes da biblioteca',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              Text(
                                query.trim().isEmpty
                                    ? 'Buscar, selecionar e organizar'
                                    : 'Filtro aplicado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: mute,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: onSelectAll,
                          icon: const Icon(Icons.checklist_rounded, size: 17),
                          label: const Text('Selecionar'),
                          style: FilledButton.styleFrom(
                            foregroundColor: primary,
                            backgroundColor:
                                isDark
                                    ? primary.withValues(alpha: 0.16)
                                    : Colors.white.withValues(alpha: 0.86),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          const SizedBox(height: 11),
          TextField(
            onChanged: onQueryChanged,
            controller: controller,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar treino, objetivo ou nivel',
              hintStyle: TextStyle(color: mute, fontWeight: FontWeight.w600),
              prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
              suffixIcon:
                  query.trim().isEmpty
                      ? null
                      : IconButton(
                        onPressed: onClearQuery,
                        icon: Icon(Icons.close_rounded, color: mute, size: 18),
                      ),
              filled: true,
              fillColor:
                  isDark
                      ? EagleTokens.darkBg
                      : Colors.white.withValues(alpha: 0.92),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? EagleTokens.darkLine : Colors.white,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primary.withValues(alpha: 0.42)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onCreate;

  const _EmptyState({
    required this.isDark,
    required this.primary,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 150),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(Icons.fitness_center_rounded, color: primary, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Sua biblioteca começa aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um plano base, adicione exercícios e use como ponto de partida para seus alunos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar treino'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onClear;

  const _NoResultsState({
    required this.isDark,
    required this.primary,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 150),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.manage_search_rounded, color: primary, size: 31),
          ),
          const SizedBox(height: 16),
          Text(
            'Nada encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Ajuste a busca para encontrar outro treino da biblioteca.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Limpar busca'),
          ),
        ],
      ),
    );
  }
}

class _TreinoCard extends StatelessWidget {
  final Treino treino;
  final int index;
  final bool isDark;
  final Color primary;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelection;
  final VoidCallback onStartSelection;
  final VoidCallback onDelete;

  const _TreinoCard({
    required this.treino,
    required this.index,
    required this.isDark,
    required this.primary,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onStartSelection,
    required this.onDelete,
  });

  IconData get _nivelIcon {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO':
        return Icons.local_fire_department_rounded;
      case 'INTERMEDIARIO':
        return Icons.speed_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  Color get _nivelColor {
    switch (treino.nivel?.toUpperCase()) {
      case 'AVANCADO':
        return EagleTokens.bad;
      case 'INTERMEDIARIO':
        return EagleTokens.warn;
      default:
        return EagleTokens.good;
    }
  }

  String get _nivelLabel {
    final nivel = treino.nivel?.trim();
    if (nivel == null || nivel.isEmpty) {
      return 'Iniciante';
    }
    return nivel[0].toUpperCase() + nivel.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final hasExercises = treino.exercicios.isNotEmpty;
    final series = treino.exercicios.fold<int>(
      0,
      (sum, item) => sum + item.series,
    );
    final estimatedMinutes =
        hasExercises ? (treino.exercicios.length * 5).clamp(12, 90) : 0;

    return InkWell(
      onTap:
          selectionMode
              ? onToggleSelection
              : () => context.push('/treinos/${treino.id}'),
      onLongPress: onStartSelection,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? primary.withValues(alpha: 0.62) : line,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF16213E).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 12),
                spreadRadius: -18,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    hasExercises
                        ? Icons.fitness_center_rounded
                        : Icons.build_circle_outlined,
                    color: primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              treino.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15.5,
                                color: ink,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          if (treino.isTemplate) ...[
                            const SizedBox(width: 8),
                            _TinyBadge(
                              label: 'base',
                              color: primary,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        treino.objetivo?.trim().isNotEmpty == true
                            ? treino.objetivo!.trim()
                            : hasExercises
                            ? 'Plano pronto para atribuir'
                            : 'Estrutura aguardando exercícios',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mute,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 2),
                if (selectionMode)
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onToggleSelection(),
                    activeColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: 'Acoes do treino',
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'select') {
                        onStartSelection();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(Icons.checklist_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Selecionar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Excluir'),
                              ],
                            ),
                          ),
                        ],
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? EagleTokens.darkBg
                                : const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Acoes',
                            style: TextStyle(
                              color: mute,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: mute,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PlanPill(
                    icon: Icons.list_alt_rounded,
                    value:
                        '${treino.exercicios.length} exercício${treino.exercicios.length == 1 ? '' : 's'}',
                    isDark: isDark,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanPill(
                    icon: Icons.repeat_rounded,
                    value: hasExercises ? '$series séries' : 'em montagem',
                    isDark: isDark,
                    color: hasExercises ? primary : EagleTokens.warn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanPill(
                    icon: _nivelIcon,
                    value: _nivelLabel,
                    isDark: isDark,
                    color: _nivelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: hasExercises ? 1 : 0.28,
                      backgroundColor:
                          isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                      valueColor: AlwaysStoppedAnimation(
                        hasExercises ? primary : EagleTokens.warn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  hasExercises ? '~${estimatedMinutes}min' : 'finalizar',
                  style: TextStyle(
                    color: hasExercises ? mute : EagleTokens.warn,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;
  final Color color;

  const _PlanPill({
    required this.icon,
    required this.value,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 10.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _TinyBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: BrandPalette.soft(color, dark: isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TreinosErrorState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;

  const _TreinosErrorState({
    required this.isDark,
    required this.primary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: mute),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar',
              style: TextStyle(
                color: ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verifique a conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
