import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../utils/exercicios_filter_display.dart';
import '../data/exercise_enum_api.dart';
import '../data/exercicio_repository.dart';
import '../providers/exercicio_picker_provider.dart';
import '../providers/exercicios_provider.dart';
import 'widgets/exercicios_batch_actions.dart';
import 'widgets/exercicios_filter_bar.dart';
import 'widgets/exercicios_list_view.dart';

part 'exercicios_list_screen_body.part.dart';

class ExerciciosListScreen extends ConsumerStatefulWidget {
  const ExerciciosListScreen({super.key});

  @override
  ConsumerState<ExerciciosListScreen> createState() =>
      _ExerciciosListScreenState();
}

class _ExerciciosListScreenState extends ConsumerState<ExerciciosListScreen> {
  final _picker = ImagePicker();
  final _scrollCtrl = ScrollController();
  ExerciciosUiFilter _filter = const ExerciciosUiFilter();
  final Set<int> _selected = {};
  DateTime? _fetchedAt;
  final List<Exercicio> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 0;
  int _totalElements = 0;
  String? _error;

  List<Exercicio> get _visibleItems => _items;

  bool? get _hasVideoFilter {
    if (_filter.comVideo) return true;
    if (_filter.semVideo) return false;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNext || _loadingMore || _loading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      _fetchPage(reset: false);
    }
  }

  Future<void> _fetchPage({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 0;
        _items.clear();
      });
    } else {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await ref
          .read(exercicioRepositoryProvider)
          .listarPagina(
            busca: _filter.query.trim().isEmpty ? null : _filter.query.trim(),
            modalidade: enumQueryParam(_filter.modalidade),
            grupoMuscularPrimario: enumQueryParam(_filter.grupo),
            equipamento: enumQueryParam(_filter.equipamento),
            dificuldade: enumQueryParam(_filter.dificuldade),
            favoritos: _filter.favoritos ? true : null,
            hasVideo: _hasVideoFilter,
            page: _page,
          );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.content);
          _fetchedAt = DateTime.now();
        } else {
          _items.addAll(result.content);
        }
        _totalElements = result.meta.totalElements;
        _hasNext = result.meta.hasNext;
        _page = result.meta.page + 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _refresh() {
    ref.invalidate(exerciciosCuradoriaProvider);
    ref.invalidate(exercicioPickerStatsProvider);
    _fetchPage(reset: true);
  }

  Future<void> _uploadVideo(Exercicio exercicio) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    FeedbackHelper.showInfo(context, 'Enviando video de ${exercicio.nome}...');
    try {
      await ref
          .read(exercicioRepositoryProvider)
          .uploadVideo(
            id: exercicio.id,
            bytes: await file.readAsBytes(),
            filename: file.name,
          );
      AnalyticsService.instance.track(
        'video_personal_upload',
        props: {'exId': exercicio.id},
      );
      _refresh();
      if (mounted) FeedbackHelper.showSuccess(context, 'Video adicionado.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _deleteOne(Exercicio exercicio) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Excluir exercicio?',
      message:
          'Isso remove "${exercicio.nome}" da biblioteca. Se estiver em treino, o backend pode bloquear.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(exercicioRepositoryProvider).excluir(exercicio.id);
      _selected.remove(exercicio.id);
      _refresh();
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Exercicio excluido.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _favorite(Exercicio exercicio) async {
    try {
      final repo = ref.read(exercicioRepositoryProvider);
      if (exercicio.favoritado) {
        await repo.desfavoritarExercicio(exercicio.id);
      } else {
        await repo.favoritarExercicio(exercicio.id);
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _favoriteBatch() async {
    final repo = ref.read(exercicioRepositoryProvider);
    final ids = _selected.toList();
    for (final id in ids) {
      final ex = _items.firstWhere((item) => item.id == id);
      if (!ex.favoritado) await repo.favoritarExercicio(id);
    }
    setState(_selected.clear);
    _refresh();
  }

  void _selectAllVisible() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_visibleItems.map((e) => e.id));
    });
  }

  Future<void> _deleteBatch() async {
    final count = _selected.length;
    if (count == 0) return;
    final ok = await showFxConfirmSheet(
      context,
      title: 'Excluir $count exercicios?',
      message:
          'Esta acao remove os exercicios selecionados da biblioteca. '
          'Se algum estiver cadastrado em treino de aluno, ele sera mantido '
          'e eu vou te mostrar quais foram bloqueados.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    final repo = ref.read(exercicioRepositoryProvider);
    final byId = {for (final ex in _items) ex.id: ex};
    final deleted = <int>[];
    final blocked = <_DeleteFailure>[];
    final selectedIds = _selected.toList();

    for (final id in selectedIds) {
      final ex = byId[id];
      try {
        await repo.excluir(id);
        deleted.add(id);
      } catch (e) {
        blocked.add(
          _DeleteFailure(
            id: id,
            nome: ex?.nome ?? 'Exercicio #$id',
            motivo: friendlyError(e),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _selected
        ..removeAll(deleted)
        ..removeAll(blocked.map((e) => e.id));
      if (blocked.isEmpty) _selected.clear();
    });
    _refresh();
    if (blocked.isEmpty) {
      FeedbackHelper.showSuccess(
        context,
        deleted.length == 1
            ? '1 exercicio excluido.'
            : '${deleted.length} exercicios excluidos.',
      );
      return;
    }

    await showFxNoticeSheet(
      context,
      title: 'Alguns exercicios nao foram excluidos',
      icon: Icons.info_outline_rounded,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deleted.isNotEmpty)
            Text('${deleted.length} excluido(s) com sucesso.'),
          const SizedBox(height: 8),
          const Text(
            'Mantidos porque estao cadastrados para aluno ou em treino:',
          ),
          const SizedBox(height: 8),
          ...blocked.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${item.nome}\n${item.motivo}'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _novoExercicio() async {
    final created = await context.push<bool>('/exercicios/novo');
    if (created == true) _refresh();
  }

  Future<void> _abrirBiblioteca() async {
    final imported = await context.push<bool>('/exercicios/biblioteca-wizard');
    if (imported == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final totalLabel = exerciciosCountLabel(_totalElements);
    final headerSubtitle = FxHubFreshness.joinCount(totalLabel, freshnessLabel);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return fxScreenA11yScope(
      label: 'Exercícios',
      child: PopScope(
        canPop: !keyboardOpen && _selected.isEmpty,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          if (_selected.isNotEmpty) {
            setState(_selected.clear);
            return;
          }
          safePopOrGo(context, '/treinos');
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar:
            _selected.isEmpty
                ? FxShellAppBar(
                  title: 'Exercícios',
                  subtitle: headerSubtitle,
                  onBack: () {
                    FxKeyboardDismissScope.dismiss();
                    safePopOrGo(context, '/treinos');
                  },
                  actions: [
                    IconButton(
                      tooltip: 'Selecionar exercícios',
                      onPressed:
                          visible.isEmpty
                              ? null
                              : () => setState(
                                () => _selected.add(visible.first.id),
                              ),
                      icon: const Icon(Icons.checklist_rounded),
                    ),
                    IconButton(
                      tooltip: 'Carregar biblioteca completa',
                      onPressed: _abrirBiblioteca,
                      icon: const Icon(Icons.menu_book_rounded),
                    ),
                  ],
                )
                : null,
        body: SafeArea(
          bottom: false,
          child: FxContentWidthLimiter(
            child: Column(
            children: [
              if (_selected.isNotEmpty)
                ExerciciosBatchActions(
                  count: _selected.length,
                  onCancel: () => setState(_selected.clear),
                  onSelectAll: _selectAllVisible,
                  onFavorite: _favoriteBatch,
                  onDelete: _deleteBatch,
                ),
              ExerciciosFilterBar(
                filter: _filter,
                onChanged: (value) {
                  setState(() => _filter = value);
                  _fetchPage(reset: true);
                },
                onClear: () {
                  setState(() => _filter = const ExerciciosUiFilter());
                  _fetchPage(reset: true);
                },
              ),
              Expanded(
                child: _libraryBody(
                  isDark: isDark,
                  primary: primary,
                  visible: visible,
                ),
              ),
              if (_selected.isEmpty && !_loading && _error == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      TokensStrip.s2,
                      TokensStrip.s4,
                      TokensStrip.s2 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: 'Novo exercício',
                      onPressed: _novoExercicio,
                    ),
                  ),
                ),
            ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _DeleteFailure {
  final int id;
  final String nome;
  final String motivo;

  const _DeleteFailure({
    required this.id,
    required this.nome,
    required this.motivo,
  });
}
