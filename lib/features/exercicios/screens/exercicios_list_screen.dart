import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/offline_queued_ack.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/batch_mutation_notice.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/exercicios_filter_display.dart';
import '../data/exercise_enum_api.dart';
import '../data/exercicio_repository.dart';
import '../providers/exercicio_picker_provider.dart';
import '../providers/exercicios_provider.dart';
import 'widgets/exercicios_batch_actions.dart';
import 'widgets/exercicios_filter_bar.dart';
import 'widgets/exercicios_list_view.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../models/exercicio_criado.dart';

part 'exercicios_list_screen_body.part.dart';

class ExerciciosListScreen extends ConsumerStatefulWidget {
  const ExerciciosListScreen({super.key, this.embedded = false});

  /// Dentro da aba Treinos: sem scaffold nem barra, só o conteúdo.
  final bool embedded;

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
  String _aba = 'MEUS';

  /// "Meus" é o padrão; sem nenhum exercício do personal, abre a Focux uma vez.
  bool _abaDecidida = false;

  List<Exercicio> get _visibleItems => _items;

  bool? get _hasVideoFilter {
    if (_filter.comVideo) return true;
    if (_filter.semVideo) return false;
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Dentro de Treinos só aparecem os exercícios do personal; a biblioteca
    // Focux fica em um lugar só (tela cheia).
    if (widget.embedded) _abaDecidida = true;
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
            aba: _aba,
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
      if (reset && !_abaDecidida) {
        _abaDecidida = true;
        if (_aba == 'MEUS' && _totalElements == 0 && !_filter.hasActive) {
          setState(() => _aba = 'FOCUX');
          _fetchPage(reset: true);
        }
      }
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
    FeedbackHelper.showInfo(context, 'Enviando vídeo de ${exercicio.nome}…');
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
      if (mounted) FeedbackHelper.showSuccess(context, 'Vídeo adicionado.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _deleteOne(Exercicio exercicio) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Excluir exercício?',
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
        FeedbackHelper.showSuccess(context, 'Exercício excluído.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showApiFailure(context, e);
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
      FeedbackHelper.showApiFailure(context, e);
    }
  }

  Future<void> _favoriteBatch() async {
    final repo = ref.read(exercicioRepositoryProvider);
    final ids = _selected.toList();
    var queued = 0;
    var failed = 0;
    for (final id in ids) {
      final ex = _items.firstWhere((item) => item.id == id);
      if (ex.favoritado) continue;
      try {
        await repo.favoritarExercicio(id);
      } on OfflineQueuedException {
        queued++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(_selected.clear);
    _refresh();
    final s = S.of(context);
    switch (resolveBatchMutationNotice(failed: failed, queued: queued)) {
      case BatchMutationNotice.failure:
        FeedbackHelper.showError(context, s.exerciciosFavoritarLoteFalhou);
      case BatchMutationNotice.failureWithQueued:
        FeedbackHelper.showError(
          context,
          '${s.exerciciosFavoritarLoteFalhou}\n${s.acaoEnfileiradaOffline}',
        );
      case BatchMutationNotice.queued:
        FeedbackHelper.showWarn(context, s.acaoEnfileiradaOffline);
      case BatchMutationNotice.success:
        break;
    }
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
    var queued = 0;

    for (final id in selectedIds) {
      final ex = byId[id];
      try {
        await repo.excluir(id);
        deleted.add(id);
      } on OfflineQueuedException {
        deleted.add(id);
        queued++;
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
    switch (resolveBatchMutationNotice(
      failed: blocked.length,
      queued: queued,
    )) {
      case BatchMutationNotice.success:
        FeedbackHelper.showSuccess(
          context,
          deleted.length == 1
              ? '1 exercicio excluido.'
              : '${deleted.length} exercicios excluidos.',
        );
        return;
      case BatchMutationNotice.queued:
        FeedbackHelper.showWarn(context, S.of(context).acaoEnfileiradaOffline);
        return;
      case BatchMutationNotice.failure:
      case BatchMutationNotice.failureWithQueued:
        // A sheet lista os bloqueados e, se houver, a linha de pendentes.
        break;
    }

    await showFxNoticeSheet(
      context,
      title: 'Alguns exercicios nao foram excluidos',
      icon: Icons.info_outline_rounded,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deleted.length > queued)
            Text('${deleted.length - queued} excluido(s) com sucesso.'),
          if (queued > 0) Text(S.of(context).acaoEnfileiradaOffline),
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
    final criado = await context.push<ExercicioCriado>('/exercicios/novo');
    if (criado == null || !mounted) return;
    if (_aba != 'MEUS') setState(() => _aba = 'MEUS');
    _refresh();
    if (criado.destino == ExercicioCriadoDestino.criarOutro) {
      await _novoExercicio();
    }
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

    if (widget.embedded) {
      return _conteudo(isDark: isDark, primary: primary, visible: visible);
    }

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
              child: _conteudo(
                isDark: isDark,
                primary: primary,
                visible: visible,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo({
    required bool isDark,
    required Color primary,
    required List<Exercicio> visible,
  }) {
    return Column(
      children: [
        if (_selected.isNotEmpty)
          ExerciciosBatchActions(
            count: _selected.length,
            onCancel: () => setState(_selected.clear),
            onSelectAll: _selectAllVisible,
            onFavorite: _favoriteBatch,
            onDelete: _deleteBatch,
          ),
        if (widget.embedded)
          Align(
            alignment: Alignment.centerLeft,
            child: FxActionLink(
              label: 'Biblioteca Focux',
              onTap: () => context.push('/exercicios'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: AlunoSegmentedChoice(
              options: const [
                (value: 'MEUS', label: 'Meus'),
                (value: 'FOCUX', label: 'Focux'),
              ],
              selected: _aba,
              isDark: isDark,
              onSelect: (value) {
                if (_aba == value) return;
                _abaDecidida = true;
                setState(() => _aba = value);
                _fetchPage(reset: true);
              },
            ),
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
