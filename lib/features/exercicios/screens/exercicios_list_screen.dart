import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/friendly_error.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/enums.dart';
import '../data/exercicio_repository.dart';
import '../data/exercicio_taxonomy_labels.dart';
import '../providers/exercicios_provider.dart';
import 'widgets/exercicio_card.dart';
import '../../../core/widgets/skeleton_loader.dart';

// ---------------------------------------------------------------------------
// Seed import provider (simple FutureProvider for one-shot call)
// ---------------------------------------------------------------------------

const _categoriasFiltro = ['Todos', 'MUSCULACAO', 'MOBILIDADE', 'CARDIO'];

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
const _objetivosFiltro = [
  'Forca',
  'Hipertrofia',
  'Emagrecimento',
  'Condicionamento',
  'Mobilidade',
];
const _fontesVideoFiltro = [
  'CURATION_REQUIRED',
  'FOCUX_LIBRARY',
  'PERSONAL_UPLOAD',
];
const _licencasFiltro = ['LICENSED', 'PERSONAL_OWNED', 'PENDING_REVIEW'];

class ExerciciosListScreen extends ConsumerStatefulWidget {
  const ExerciciosListScreen({super.key});

  @override
  ConsumerState<ExerciciosListScreen> createState() =>
      _ExerciciosListScreenState();
}

class _ExerciciosListScreenState extends ConsumerState<ExerciciosListScreen> {
  final _picker = ImagePicker();
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
  bool _comVideoFiltro = false;
  String? _fonteVideoFiltro;
  String? _licencaFiltro;

  @override
  void dispose() {
    _tagCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  String? get _categoriaParam =>
      _categoriaFiltro == 'Todos' ? null : _categoriaFiltro;

  bool get _hasAdvancedFilters =>
      _tagFiltro.isNotEmpty ||
      _musculoFiltro != null ||
      _equipamentoFiltro != null ||
      _nivelFiltro != null ||
      _mecanicaFiltro != null ||
      _objetivoFiltro != null ||
      _comVideoFiltro ||
      _fonteVideoFiltro != null ||
      _licencaFiltro != null;

  bool get _hasAnyFilter =>
      _categoriaFiltro != 'Todos' ||
      _apenasFavoritos ||
      _nomeFiltro.isNotEmpty ||
      _hasAdvancedFilters;

  void _clearFilters() {
    _nomeCtrl.clear();
    _tagCtrl.clear();
    setState(() {
      _categoriaFiltro = 'Todos';
      _apenasFavoritos = false;
      _nomeFiltro = '';
      _tagFiltro = '';
      _musculoFiltro = null;
      _equipamentoFiltro = null;
      _nivelFiltro = null;
      _mecanicaFiltro = null;
      _objetivoFiltro = null;
      _comVideoFiltro = false;
      _fonteVideoFiltro = null;
      _licencaFiltro = null;
    });
  }

  void _applyReviewFilter() {
    setState(() {
      _comVideoFiltro = false;
      _fonteVideoFiltro = null;
      _licencaFiltro = 'PENDING_REVIEW';
    });
  }

  void _applyAllFilter() {
    setState(() {
      _apenasFavoritos = false;
      _comVideoFiltro = false;
      _fonteVideoFiltro = null;
      _licencaFiltro = null;
    });
  }

  Future<void> _pickAndUploadVideoFor(BuildContext context, int id) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Enviando video do exercicio...')),
    );
    try {
      await ref
          .read(exercicioRepositoryProvider)
          .uploadVideo(
            id: id,
            bytes: await file.readAsBytes(),
            filename: file.name,
          );
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exercicioProvider(id));
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Video adicionado ao exercicio.'),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteExercise(
    BuildContext context,
    Exercicio exercicio,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir exercicio?'),
            content: Text(
              'Isso remove "${exercicio.nome}" da sua biblioteca. Se ele ja estiver em um treino, o app vai avisar e manter o exercicio.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: EagleTokens.bad,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirm != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(exercicioRepositoryProvider).excluir(exercicio.id);
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Exercicio excluido.'),
          backgroundColor: EagleTokens.good,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: EagleTokens.bad,
        ),
      );
    }
  }

  void _applyVideoFilter() {
    setState(() {
      _comVideoFiltro = true;
      _fonteVideoFiltro = null;
      _licencaFiltro = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(
      exerciciosFilteredProvider(
        ExercicioFilter(
          nome: _nomeFiltro.isEmpty ? null : _nomeFiltro,
          categoria: _categoriaParam,
          tag: _tagFiltro.isEmpty ? null : _tagFiltro,
          musculoAlvo: _musculoFiltro,
          equipamento: _equipamentoFiltro,
          nivel: _nivelFiltro,
          mecanica: _mecanicaFiltro,
          objetivo: _objetivoFiltro,
          hasVideo: _comVideoFiltro ? true : null,
          videoSource: _fonteVideoFiltro,
          licenseStatus: _licencaFiltro,
          favoritos: _apenasFavoritos ? true : null,
        ),
      ),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primary, primaryDeep]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.4),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final title = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIBLIOTECA',
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 28 : 32,
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                  final actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _apenasFavoritos ? Icons.star : Icons.star_border,
                          color: _apenasFavoritos ? EagleTokens.warn : mute,
                        ),
                        tooltip: 'Apenas favoritos',
                        onPressed:
                            () => setState(
                              () => _apenasFavoritos = !_apenasFavoritos,
                            ),
                      ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: _hasAdvancedFilters,
                          smallSize: 8,
                          child: Icon(
                            Icons.tune_rounded,
                            color:
                                _hasAdvancedFilters
                                    ? Theme.of(context).colorScheme.primary
                                    : mute,
                          ),
                        ),
                        tooltip: 'Filtros avancados',
                        onPressed: () => _openFilters(context),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: mute),
                        tooltip: 'Mais opcoes',
                        onSelected: (value) {
                          if (value == 'biblioteca_completa') {
                            _importarSeedPremiumV1(context, ref);
                          }
                          if (value == 'fila_editorial') {
                            _openFilaEditorial(context, ref);
                          }
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'biblioteca_completa',
                                child: Row(
                                  children: [
                                    Icon(Icons.download_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text('Carregar biblioteca completa'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'fila_editorial',
                                child: Row(
                                  children: [
                                    Icon(Icons.rate_review_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text('Fila editorial'),
                                  ],
                                ),
                              ),
                            ],
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: mute),
                        onPressed:
                            () => safePopOrGo(context, '/dashboard/personal'),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [Expanded(child: title), actions],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: TextField(
                controller: _nomeCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar exercicio por nome',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _nomeFiltro.isNotEmpty
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
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _categoriasFiltro.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categoriasFiltro[i];
                  final selecionado = cat == _categoriaFiltro;
                  return FilterChip(
                    label: Text(_formatCategoriaFiltro(cat)),
                    selected: selecionado,
                    onSelected: (_) => setState(() => _categoriaFiltro = cat),
                  );
                },
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  _QuickFilterChip(
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'Todos',
                    selected:
                        !_apenasFavoritos &&
                        !_comVideoFiltro &&
                        _licencaFiltro == null,
                    onTap: _applyAllFilter,
                  ),
                  const SizedBox(width: 8),
                  _QuickFilterChip(
                    icon: Icons.star_rounded,
                    label: 'Favoritos',
                    selected: _apenasFavoritos,
                    onTap:
                        () => setState(
                          () => _apenasFavoritos = !_apenasFavoritos,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _QuickFilterChip(
                    icon: Icons.play_circle_fill_rounded,
                    label: 'Com video',
                    selected: _comVideoFiltro && _licencaFiltro == null,
                    onTap: _applyVideoFilter,
                  ),
                  const SizedBox(width: 8),
                  _QuickFilterChip(
                    icon: Icons.rate_review_rounded,
                    label: 'Revisar',
                    selected: _licencaFiltro == 'PENDING_REVIEW',
                    onTap: _applyReviewFilter,
                  ),
                  if (_hasAnyFilter) ...[
                    const SizedBox(width: 8),
                    _QuickFilterChip(
                      icon: Icons.close_rounded,
                      label: 'Limpar',
                      selected: false,
                      onTap: _clearFilters,
                    ),
                  ],
                ],
              ),
            ),
            if (_hasAdvancedFilters)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: [
                    _ActiveFilterChip(
                      label: _tagFiltro.isEmpty ? null : '#$_tagFiltro',
                      onDeleted: () {
                        _tagCtrl.clear();
                        setState(() => _tagFiltro = '');
                      },
                    ),
                    _ActiveFilterChip(
                      label: _musculoFiltro,
                      onDeleted: () => setState(() => _musculoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _equipamentoFiltro,
                      onDeleted:
                          () => setState(() => _equipamentoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _nivelFiltro,
                      onDeleted: () => setState(() => _nivelFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _mecanicaFiltro,
                      onDeleted: () => setState(() => _mecanicaFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _objetivoFiltro,
                      onDeleted: () => setState(() => _objetivoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _comVideoFiltro ? 'Com video' : null,
                      onDeleted: () => setState(() => _comVideoFiltro = false),
                    ),
                    _ActiveFilterChip(
                      label: _formatSourceLabel(_fonteVideoFiltro),
                      onDeleted: () => setState(() => _fonteVideoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _formatLicenseLabel(_licencaFiltro),
                      onDeleted: () => setState(() => _licencaFiltro = null),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: exerciciosAsync.when(
                loading: () => const SkeletonList(count: 6),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (exercicios) {
                  if (exercicios.isEmpty) {
                    return const Center(
                      child: Text('Nenhum exercicio encontrado.'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh:
                        () async => ref.invalidate(exerciciosFilteredProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 96),
                      itemCount:
                          exercicios.length + (_nomeFiltro.isNotEmpty ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (_nomeFiltro.isNotEmpty && i == exercicios.length) {
                          return _CreateExerciseSuggestion(
                            query: _nomeFiltro,
                            onTap: () async {
                              final criado = await context.push<bool>(
                                '/exercicios/novo',
                              );
                              if (criado == true) {
                                ref.invalidate(exerciciosFilteredProvider);
                              }
                            },
                          );
                        }
                        return ExercicioCard(
                          exercicio: exercicios[i],
                          onFavoritoToggle:
                              () => ref.invalidate(exerciciosFilteredProvider),
                          onUploadVideo:
                              () => _pickAndUploadVideoFor(
                                context,
                                exercicios[i].id,
                              ),
                          onDelete:
                              () => _confirmDeleteExercise(
                                context,
                                exercicios[i],
                              ),
                        );
                      },
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

  Future<void> _importarSeedPremiumV1(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Carregar biblioteca curada'),
            content: const Text(
              'Isso vai carregar os exercicios curados v2 com modalidade, grupo, padrao de movimento, equipamento e espaco.\n\nVideos oficiais nao serao falsificados. Itens sem video entram para curadoria ate voce anexar video proprio ou licenciado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Carregar'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Carregando biblioteca curada...'),
          ],
        ),
        duration: Duration(seconds: 45),
      ),
    );

    try {
      final count =
          await ref.read(exercicioRepositoryProvider).importarSeedPremiumV1();
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$count exercicios importados para biblioteca.'),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    }
  }

  Future<void> _openFilaEditorial(BuildContext context, WidgetRef ref) async {
    var status = 'PENDING_REVIEW';
    var refreshToken = 0;
    final selectedIds = <int>{};

    Future<List<ExercicioEditorialQueue>> loadQueues() {
      final repo = ref.read(exercicioRepositoryProvider);
      return Future.wait([
        repo.buscarFilaEditorial('PENDING_REVIEW'),
        repo.buscarFilaEditorial('REJECTED'),
        repo.buscarFilaEditorial('APPROVED', size: 1),
      ]);
    }

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) {
              final media = MediaQuery.of(ctx);
              final isCompact = media.size.width < 640;
              final dialogWidth = isCompact ? media.size.width - 24 : 760.0;
              final maxListHeight =
                  isCompact ? media.size.height * 0.52 : 500.0;

              return AlertDialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 24,
                  vertical: 16,
                ),
                title: Row(
                  children: [
                    const Expanded(child: Text('Fila editorial')),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: dialogWidth,
                  child: FutureBuilder<List<ExercicioEditorialQueue>>(
                    key: ValueKey(refreshToken),
                    future: loadQueues(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text('Erro ao carregar fila: ${snapshot.error}');
                      }

                      final queues = snapshot.data ?? [];
                      final pending =
                          queues.isNotEmpty
                              ? queues[0]
                              : ExercicioEditorialQueue(
                                total: 0,
                                items: const [],
                              );
                      final rejected =
                          queues.length > 1
                              ? queues[1]
                              : ExercicioEditorialQueue(
                                total: 0,
                                items: const [],
                              );
                      final approvedTotal =
                          queues.length > 2 ? queues[2].total : 0;
                      final activeQueue =
                          status == 'REJECTED' ? rejected : pending;

                      Future<void> review(
                        Exercicio exercicio,
                        String nextStatus,
                      ) async {
                        await ref
                            .read(exercicioRepositoryProvider)
                            .atualizarCuradoriaEditorial(
                              id: exercicio.id,
                              status: nextStatus,
                              notes:
                                  nextStatus == 'APPROVED'
                                      ? 'Aprovado pela fila editorial.'
                                      : 'Reprovado pela fila editorial.',
                            );
                        ref.invalidate(exerciciosFilteredProvider);
                        ref.invalidate(exerciciosCuradoriaProvider);
                        setModalState(() => refreshToken++);
                      }

                      Future<void> bulkReview(String nextStatus) async {
                        if (selectedIds.isEmpty) return;
                        final count = await ref
                            .read(exercicioRepositoryProvider)
                            .atualizarCuradoriaEditorialLote(
                              ids: selectedIds.toList(),
                              status: nextStatus,
                              notes:
                                  nextStatus == 'APPROVED'
                                      ? 'Aprovado em lote pela fila editorial.'
                                      : 'Reprovado em lote pela fila editorial.',
                            );
                        selectedIds.clear();
                        ref.invalidate(exerciciosFilteredProvider);
                        ref.invalidate(exerciciosCuradoriaProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$count exercicios atualizados.'),
                            ),
                          );
                        }
                        setModalState(() => refreshToken++);
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text('Pendentes ${pending.total}'),
                                selected: status == 'PENDING_REVIEW',
                                onSelected:
                                    (_) => setModalState(() {
                                      status = 'PENDING_REVIEW';
                                      selectedIds.clear();
                                    }),
                              ),
                              ChoiceChip(
                                label: Text('Reprovados ${rejected.total}'),
                                selected: status == 'REJECTED',
                                onSelected:
                                    (_) => setModalState(() {
                                      status = 'REJECTED';
                                      selectedIds.clear();
                                    }),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                ),
                                label: Text('Aprovados $approvedTotal'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (activeQueue.items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Text('Nada para revisar nesta fila.'),
                            )
                          else ...[
                            _EditorialQueueBulkBar(
                              selectedCount: selectedIds.length,
                              allSelected:
                                  selectedIds.length ==
                                  activeQueue.items.length,
                              onToggleAll:
                                  () => setModalState(() {
                                    if (selectedIds.length ==
                                        activeQueue.items.length) {
                                      selectedIds.clear();
                                    } else {
                                      selectedIds
                                        ..clear()
                                        ..addAll(
                                          activeQueue.items.map(
                                            (item) => item.id,
                                          ),
                                        );
                                    }
                                  }),
                              onApprove:
                                  selectedIds.isEmpty
                                      ? null
                                      : () => bulkReview('APPROVED'),
                              onReject:
                                  selectedIds.isEmpty
                                      ? null
                                      : () => bulkReview('REJECTED'),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: maxListHeight,
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: activeQueue.items.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 20),
                                itemBuilder: (context, index) {
                                  final exercicio = activeQueue.items[index];
                                  return _EditorialQueueTile(
                                    exercicio: exercicio,
                                    selected: selectedIds.contains(
                                      exercicio.id,
                                    ),
                                    onSelectedChanged:
                                        (checked) => setModalState(() {
                                          if (checked == true) {
                                            selectedIds.add(exercicio.id);
                                          } else {
                                            selectedIds.remove(exercicio.id);
                                          }
                                        }),
                                    onApprove:
                                        () => review(exercicio, 'APPROVED'),
                                    onReject:
                                        () => review(exercicio, 'REJECTED'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                actions: const [],
              );
            },
          ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    var musculo = _musculoFiltro;
    var equipamento = _equipamentoFiltro;
    var nivel = _nivelFiltro;
    var mecanica = _mecanicaFiltro;
    var objetivo = _objetivoFiltro;
    var comVideo = _comVideoFiltro;
    var fonteVideo = _fonteVideoFiltro;
    var licenca = _licencaFiltro;
    final tagCtrl = TextEditingController(text: _tagFiltro);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filtros da biblioteca',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use quando quiser afinar por musculo, equipamento ou status do video.',
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tag opcional',
                      hintText: 'Ex: EmCasa, SemEquipamento',
                      prefixIcon: Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Grupo muscular',
                    value: musculo,
                    values: _gruposFiltro,
                    onChanged: (v) => modalSetState(() => musculo = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Equipamento',
                    value: equipamento,
                    values: _equipamentosFiltro,
                    onChanged: (v) => modalSetState(() => equipamento = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Nivel',
                    value: nivel,
                    values: _niveisFiltro,
                    onChanged: (v) => modalSetState(() => nivel = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Mecanica',
                    value: mecanica,
                    values: _mecanicasFiltro,
                    onChanged: (v) => modalSetState(() => mecanica = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Objetivo',
                    value: objetivo,
                    values: _objetivosFiltro,
                    onChanged: (v) => modalSetState(() => objetivo = v),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    value: comVideo,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Somente com video'),
                    secondary: const Icon(Icons.play_circle_fill_rounded),
                    onChanged: (value) => modalSetState(() => comVideo = value),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Fonte do video',
                    value: fonteVideo,
                    values: _fontesVideoFiltro,
                    formatter: _formatSourceLabel,
                    onChanged: (v) => modalSetState(() => fonteVideo = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Licenca',
                    value: licenca,
                    values: _licencasFiltro,
                    formatter: _formatLicenseLabel,
                    onChanged: (v) => modalSetState(() => licenca = v),
                  ),
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
                              comVideo = false;
                              fonteVideo = null;
                              licenca = null;
                              tagCtrl.clear();
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
                              _comVideoFiltro = comVideo;
                              _fonteVideoFiltro = fonteVideo;
                              _licencaFiltro = licenca;
                              _tagFiltro = tagCtrl.text.trim().replaceFirst(
                                '#',
                                '',
                              );
                              _tagCtrl.text = _tagFiltro;
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
    tagCtrl.dispose();
  }

  String? _formatSourceLabel(String? value) {
    return switch (value) {
      'CURATION_REQUIRED' => 'Curadoria pendente',
      'FOCUX_LIBRARY' => 'Biblioteca Focux',
      'PERSONAL_UPLOAD' => 'Video do personal',
      null || '' => null,
      _ => value.replaceAll('_', ' '),
    };
  }

  String? _formatLicenseLabel(String? value) {
    return switch (value) {
      'LICENSED' => 'Licenciado',
      'PERSONAL_OWNED' => 'Proprio',
      'PENDING_REVIEW' => 'Pendente',
      null || '' => null,
      _ => value.replaceAll('_', ' '),
    };
  }
}

class _QuickFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ActionChip(
      avatar: Icon(icon, size: 17, color: selected ? Colors.white : primary),
      label: Text(label),
      onPressed: onTap,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: selected ? primary : null,
      side: BorderSide(
        color: selected ? primary : Theme.of(context).dividerColor,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CreateExerciseSuggestion extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const _CreateExerciseSuggestion({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nao encontrou?',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Criar "$query" na sua biblioteca',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? formatter;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Todos')),
        for (final item in values)
          DropdownMenuItem<String>(
            value: item,
            child: Text(formatter?.call(item) ?? item),
          ),
      ],
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

String _formatLicense(String value) {
  return switch (value) {
    'LICENSED' => 'Licenciado',
    'PERSONAL_OWNED' => 'Proprio',
    'PENDING_REVIEW' => 'Licenca pendente',
    _ => value.replaceAll('_', ' '),
  };
}

String _formatSource(String value) {
  return switch (value) {
    'FOCUX_LIBRARY' => 'Focux',
    'PERSONAL_UPLOAD' => 'Personal',
    'CURATION_REQUIRED' => 'Curadoria',
    _ => value.replaceAll('_', ' '),
  };
}

class _EditorialQueueBulkBar extends StatelessWidget {
  final int selectedCount;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _EditorialQueueBulkBar({
    required this.selectedCount,
    required this.allSelected,
    required this.onToggleAll,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final select = OutlinedButton.icon(
          onPressed: onToggleAll,
          icon: Icon(
            allSelected ? Icons.check_box_rounded : Icons.select_all_rounded,
          ),
          label: Text(allSelected ? 'Limpar' : 'Todos'),
        );
        final approve = FilledButton.icon(
          onPressed: onApprove,
          icon: const Icon(Icons.verified_rounded),
          label: Text('Aprovar $selectedCount'),
        );
        final reject = OutlinedButton.icon(
          onPressed: onReject,
          icon: const Icon(Icons.block_rounded),
          label: Text('Reprovar $selectedCount'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              select,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: approve),
                  const SizedBox(width: 8),
                  Expanded(child: reject),
                ],
              ),
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [select, approve, reject],
        );
      },
    );
  }
}

class _EditorialQueueTile extends StatelessWidget {
  final Exercicio exercicio;
  final bool selected;
  final ValueChanged<bool?> onSelectedChanged;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const _EditorialQueueTile({
    required this.exercicio,
    required this.selected,
    required this.onSelectedChanged,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = exercicio.videoUrl?.isNotEmpty == true;
    final license = _formatLicense(exercicio.licenseStatus ?? 'PENDING_REVIEW');
    final source =
        exercicio.videoSource?.isNotEmpty == true
            ? _formatSource(exercicio.videoSource!)
            : 'Sem fonte';
    final subtitle = [
      _formatEditorialStatus(exercicio.editorialStatus),
      source,
      license,
      if (exercicio.editorialNotes?.trim().isNotEmpty == true)
        exercicio.editorialNotes!.trim(),
    ].join(' - ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final mediaIcon = CircleAvatar(
          radius: 18,
          backgroundColor:
              hasMedia
                  ? EagleTokens.good.withValues(alpha: 0.14)
                  : EagleTokens.warn.withValues(alpha: 0.14),
          child: Icon(
            hasMedia
                ? Icons.play_circle_fill_rounded
                : Icons.videocam_off_rounded,
            color: hasMedia ? EagleTokens.good : EagleTokens.warn,
            size: 19,
          ),
        );
        final actions = Wrap(
          spacing: 6,
          children: [
            IconButton.filledTonal(
              tooltip: 'Aprovar',
              onPressed: onApprove,
              icon: const Icon(Icons.verified_rounded),
            ),
            IconButton(
              tooltip: 'Reprovar',
              onPressed: onReject,
              icon: const Icon(Icons.block_rounded),
            ),
          ],
        );

        if (compact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Checkbox(value: selected, onChanged: onSelectedChanged),
                    mediaIcon,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        exercicio.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 56, top: 2),
                  child: Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            ),
          );
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
            width: 82,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(value: selected, onChanged: onSelectedChanged),
                mediaIcon,
              ],
            ),
          ),
          title: Text(
            exercicio.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: actions,
        );
      },
    );
  }
}

String _formatCategoriaFiltro(String value) {
  if (value == 'Todos') return value;
  final modalidade = tryParseEnum(Modalidade.values, value);
  return modalidade == null
      ? value
      : TaxonomyLabels.modalidade[modalidade] ?? value;
}

String _formatEditorialStatus(String value) {
  return switch (value) {
    'APPROVED' => 'Aprovado',
    'REJECTED' => 'Reprovado',
    _ => 'Revisar',
  };
}
