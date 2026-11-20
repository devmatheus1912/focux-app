import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/offline_queued_ack.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/batch_mutation_notice.dart';
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
import '../../../l10n/app_localizations.dart';
import '../data/exercise_enum_api.dart';
import '../data/exercicio_repository.dart';
import '../models/exercicio_criado.dart';
import '../providers/exercicio_picker_provider.dart';
import '../providers/exercicios_contagem_provider.dart';
import '../providers/exercicios_provider.dart';
import '../utils/exercicios_aba_display.dart';
import '../widgets/exercicio_acoes.dart';
import 'widgets/exercicios_batch_actions.dart';
import 'widgets/exercicios_filter_bar.dart';
import 'widgets/exercicios_list_view.dart';
import 'widgets/exercise_video_preview_sheet.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../../core/theme/fx_icons.dart';

part 'exercicios_list_screen_body.part.dart';
part 'exercicios_list_screen_lote.part.dart';

class ExerciciosListScreen extends ConsumerStatefulWidget {
  const ExerciciosListScreen({
    super.key,
    this.embedded = false,
    this.onResumoTopo,
  });

  /// Dentro da aba Treinos: sem scaffold nem barra, só o conteúdo.
  final bool embedded;

  /// Embutido: o topo é da tela de Treinos, que mostra este resumo
  /// ("3 seus · 492 da biblioteca" ou "12 exercícios" com filtro).
  final ValueChanged<String?>? onResumoTopo;

  @override
  ConsumerState<ExerciciosListScreen> createState() =>
      _ExerciciosListScreenState();
}

class _ExerciciosListScreenState extends ConsumerState<ExerciciosListScreen> {
  final _scrollCtrl = ScrollController();
  ExerciciosUiFilter _filter = const ExerciciosUiFilter();
  final Set<int> _selected = {};
  final List<Exercicio> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 0;
  int _totalElements = 0;
  String? _error;
  ExerciciosAba _aba = ExerciciosAba.meus;
  String? _ultimoResumo;

  /// "Meus" vazio, sem busca nem filtro: o estado vazio traz "Novo
  /// exercício", então o botão fixo não repete a ação.
  bool get _meusVazio =>
      !_loading &&
      _error == null &&
      _totalElements == 0 &&
      !_filter.hasActive &&
      _aba == ExerciciosAba.meus;

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
            grupoMuscularPrimario: enumQueryParam(_filter.grupo),
            equipamento: enumQueryParam(_filter.equipamento),
            favoritos: _aba == ExerciciosAba.favoritos ? true : null,
            aba: exerciciosAbaParam(_aba),
            page: _page,
          );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.content);
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
    ref.invalidate(exerciciosContagemProvider);
    _fetchPage(reset: true);
  }

  void _mudarAba(ExerciciosAba aba) {
    if (_aba == aba) return;
    setState(() {
      _aba = aba;
      _selected.clear();
    });
    _fetchPage(reset: true);
  }

  void _mudarFiltro(ExerciciosUiFilter filtro) {
    setState(() => _filter = filtro);
    _fetchPage(reset: true);
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

  Future<void> _acoes(Exercicio exercicio) async {
    final mudou = await abrirAcoesDoExercicio(context, ref, exercicio);
    if (mudou && mounted) _refresh();
  }

  Future<void> _novoExercicio() async {
    final criado = await context.push<ExercicioCriado>('/exercicios/novo');
    if (criado == null || !mounted) return;
    if (_aba != ExerciciosAba.meus) setState(() => _aba = ExerciciosAba.meus);
    _refresh();
    if (criado.destino == ExercicioCriadoDestino.criarOutro) {
      await _novoExercicio();
    }
  }

  Future<void> _abrirBiblioteca() async {
    final imported = await context.push<bool>('/exercicios/biblioteca-wizard');
    if (imported == true) _refresh();
  }

  String? _resumoTopo() {
    final contagem = ref.watch(exerciciosContagemProvider).asData?.value;
    return exerciciosResumoTopo(
      meus: contagem?.meus,
      biblioteca: contagem?.biblioteca,
      filtrando: _filter.hasActive,
      totalFiltrado: _totalElements,
    );
  }

  /// Embutido: avisa a tela de Treinos quando o resumo muda.
  void _avisarResumo(String? resumo) {
    final aviso = widget.onResumoTopo;
    if (aviso == null || resumo == _ultimoResumo) return;
    _ultimoResumo = resumo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) aviso(resumo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final resumo = _resumoTopo();
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (widget.embedded) {
      _avisarResumo(resumo);
      return _conteudo(isDark: isDark, primary: primary);
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
          comFundo: true,
          appBar:
              _selected.isEmpty
                  ? FxShellAppBar(
                    title: 'Exercícios',
                    subtitle: resumo,
                    onBack: () {
                      FxKeyboardDismissScope.dismiss();
                      safePopOrGo(context, '/treinos');
                    },
                    actions: [
                      IconButton(
                        tooltip: 'Selecionar exercícios',
                        onPressed:
                            _items.isEmpty
                                ? null
                                : () => setState(
                                  () => _selected.add(_items.first.id),
                                ),
                        icon: const Icon(FxIcons.checklist),
                      ),
                      IconButton(
                        tooltip: 'Carregar biblioteca completa',
                        onPressed: _abrirBiblioteca,
                        icon: const Icon(FxIcons.livro),
                      ),
                    ],
                  )
                  : null,
          body: SafeArea(
            bottom: false,
            child: FxContentWidthLimiter(
              child: _conteudo(isDark: isDark, primary: primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo({required bool isDark, required Color primary}) {
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            0,
            TokensStrip.s4,
            TokensStrip.s2,
          ),
          // Três partes iguais: cabem em 320 pt (os chips do FxChoiceStrip
          // empurravam "Favoritos" para fora da tela).
          child: AlunoSegmentedChoice(
            options: [
              for (final aba in ExerciciosAba.values)
                (value: aba.name, label: exerciciosAbaRotulo(aba)),
            ],
            selected: _aba.name,
            isDark: isDark,
            onSelect: (v) => _mudarAba(ExerciciosAba.values.byName(v)),
          ),
        ),
        ExerciciosFilterBar(
          filter: _filter,
          onChanged: _mudarFiltro,
          onClear: () => _mudarFiltro(const ExerciciosUiFilter()),
        ),
        Expanded(child: _libraryBody(isDark: isDark, primary: primary)),
        if (_selected.isEmpty && !_loading && _error == null && !_meusVazio)
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
