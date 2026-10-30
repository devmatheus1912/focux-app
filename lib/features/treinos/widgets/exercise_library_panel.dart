import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_page.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/screens/widgets/exercise_video_preview_sheet.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';
import '../utils/aluno_restricao_match.dart';
import '../utils/exercise_library_sections.dart';
import '../../../core/widgets/fx_link_row.dart';
import '../utils/exercise_picker_filter.dart';
import 'exercise_picker_filter_sheet.dart';
import '../utils/exercise_picker_library_label.dart';
import '../utils/exercise_picker_sort.dart';
import 'exercise_alpha_rail.dart';
import 'exercise_balance_strip.dart';
import 'exercise_group_chips.dart';
import 'exercise_library_row.dart';
import '../utils/exercise_search_terms.dart';

typedef ExerciseLibraryPageLoader =
    Future<ExercicioPickerPage> Function({
      required String busca,
      required int page,
      required ExercisePickerFilter filter,
      PadraoMovimento? padrao,
      GrupoMuscular? grupo,
    });

/// Biblioteca paginada: busca, filtros, grupos musculares combináveis e lista
/// A–Z com favoritos, recentes e mais usados no topo.
class ExerciseLibraryPanel extends ConsumerStatefulWidget {
  const ExerciseLibraryPanel({
    super.key,
    required this.alreadyInTreinoIds,
    required this.filter,
    required this.onFilterChanged,
    required this.onLoadPage,
    required this.onSelect,
    required this.libraryTotalCount,
    this.searchPlaceholder = 'Buscar por nome, músculo ou equipamento',
    this.initialQuery = '',
    this.recentIds = const [],
    this.maisUsadosIds = const [],
    this.shortcutItems = const [],
    this.header,
    this.footer,
    this.onUploadVideo,
    this.resumoNoTreino = const {},
    this.onCadastrar,
    this.balanco = const {},
    this.regioesAluno = const {},
    this.onPreview,
    this.bottomPadding = 0,
    this.gruposIniciais = const {},
  });

  /// Grupos da sessão ("A · Peito e tríceps"): já vêm marcados ao abrir.
  final Set<GrupoMuscular> gruposIniciais;

  /// Prescrição já aplicada a cada exercício que está no treino ("3 × 10-12").
  final Map<int, String> resumoNoTreino;

  /// "Não achou? Cadastrar 'termo'": abre o cadastro de exercício.
  /// Abre o cadastro; recebe o texto da busca quando ela não achou nada.
  final void Function(String? nome)? onCadastrar;

  /// Grupos que já estão no treino ("No treino: Peito 3").
  final Map<GrupoMuscular, int> balanco;

  /// Regiões da anamnese do aluno, para marcar contraindicações. Só aviso.
  final Set<RegiaoCorpo> regioesAluno;

  /// Abre a prévia do exercício; sem ele, usa a prévia de mídia padrão.
  final void Function(Exercicio exercicio)? onPreview;

  /// Espaço no fim da lista para a barra "Pronto" não cobrir a última linha.
  final double bottomPadding;

  final Set<int> alreadyInTreinoIds;
  final ExercisePickerFilter filter;
  final ValueChanged<ExercisePickerFilter> onFilterChanged;
  final ExerciseLibraryPageLoader onLoadPage;
  final ValueChanged<Exercicio> onSelect;
  final int libraryTotalCount;
  final String searchPlaceholder;
  final String initialQuery;

  /// Ordem de uso, do mais recente para o mais antigo.
  final List<int> recentIds;

  /// Os que o personal mais adiciona (contagem).
  final List<int> maisUsadosIds;
  final List<Exercicio> shortcutItems;
  final Widget? header;
  final Widget? footer;
  final Future<Exercicio?> Function(Exercicio exercicio)? onUploadVideo;

  @override
  ConsumerState<ExerciseLibraryPanel> createState() =>
      _ExerciseLibraryPanelState();
}

class _ExerciseLibraryPanelState extends ConsumerState<ExerciseLibraryPanel> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;
  late final FocusNode _searchFocus;
  Timer? _searchDebounce;
  late ExercisePickerFilter _filter;
  String _committedQuery = '';
  final Set<GrupoMuscular> _grupos = {};
  final Map<int, Exercicio> _localUpdates = {};
  final List<Exercicio> _items = [];
  final Map<String, GlobalKey> _chavesDasLetras = {};
  final GlobalKey _listaKey = GlobalKey();
  final ValueNotifier<String?> _letraFixa = ValueNotifier(null);
  List<String> _ordemDasSecoes = const [];
  bool _focoAntesDoToque = false;
  bool _uploading = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 0;
  int _totalElements = 0;
  String? _error;

  /// Altura aproximada usada para saltar pelo índice A–Z.
  static const _alturaLinha = 52.0;
  static const _alturaCabecalho = 40.0;

  Exercicio _resolve(Exercicio exercicio) =>
      _localUpdates[exercicio.id] ?? exercicio;

  bool get _searching => _committedQuery.trim().length >= 2;

  /// Palavras da busca que são grupo ou equipamento ("peito halter").
  List<TermoReconhecido> get _termosReconhecidos =>
      termosReconhecidos(_committedQuery);

  void _removerTermo(TermoReconhecido termo) {
    final novo = removerTermoDaBusca(_searchCtrl.text, termo.palavra);
    _searchCtrl.text = novo;
    _searchCtrl.selection = TextSelection.collapsed(offset: novo.length);
  }

  /// Favoritos, recentes e mais usados só valem na navegação sem busca nem
  /// grupo escolhido.
  bool get _mostraAtalhos => !_searching && _grupos.isEmpty;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
    _grupos.addAll(widget.gruposIniciais);
    _committedQuery = widget.initialQuery.trim();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _searchFocus = FocusNode();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _searchCtrl.addListener(_onSearchTextChanged);
    _fetchPage(reset: true);
  }

  @override
  void didUpdateWidget(covariant ExerciseLibraryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter && widget.filter != _filter) {
      _filter = widget.filter;
      _fetchPage(reset: true);
    }
  }

  /// Adicionar um exercício não tira o foco da busca: o personal digita,
  /// toca, digita o próximo sem reabrir o teclado.
  void _aoSelecionar(Exercicio exercicio) {
    final tinhaFoco = _focoAntesDoToque;
    widget.onSelect(exercicio);
    if (tinhaFoco) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  /// Seção que está no topo da lista agora: vira o rótulo fixo (a letra não
  /// some enquanto se rola por uma seção longa).
  void _atualizarLetraFixa() {
    if (!_scrollCtrl.hasClients || _scrollCtrl.offset < 24) {
      _letraFixa.value = null;
      return;
    }
    final lista = _listaKey.currentContext?.findRenderObject();
    if (lista is! RenderBox || !lista.attached) return;
    final topo = lista.localToGlobal(Offset.zero).dy;
    String? atual;
    for (final letra in _ordemDasSecoes) {
      final ctx = _chavesDasLetras[letra]?.currentContext;
      final caixa = ctx?.findRenderObject();
      if (caixa is! RenderBox || !caixa.attached) continue;
      final base = caixa.localToGlobal(Offset(0, caixa.size.height)).dy;
      if (base > topo + 16) {
        atual = letra;
        break;
      }
    }
    _letraFixa.value = atual;
  }

  void _onScroll() {
    _atualizarLetraFixa();
    if (!_hasNext || _loadingMore || _loading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      _fetchPage(reset: false);
    }
  }

  void _onSearchTextChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final next = _searchCtrl.text.trim();
      if (next == _committedQuery) return;
      setState(() => _committedQuery = next);
      _fetchPage(reset: true);
    });
  }

  /// "Limpar" só aparece quando há algo além dos grupos da sessão.
  bool get _temAlgoAlemDaSessao =>
      _filter.isActive ||
      _grupos.length != widget.gruposIniciais.length ||
      !_grupos.containsAll(widget.gruposIniciais);

  void _limparTudo() {
    setState(() {
      _grupos
        ..clear()
        ..addAll(widget.gruposIniciais);
    });
    _onFilterChanged(const ExercisePickerFilter());
  }

  void _onFilterChanged(ExercisePickerFilter next) {
    setState(() => _filter = next);
    widget.onFilterChanged(next);
    _fetchPage(reset: true);
  }

  void _alternarGrupo(GrupoMuscular grupo) {
    setState(() {
      if (!_grupos.add(grupo)) _grupos.remove(grupo);
    });
    _fetchPage(reset: true);
  }

  Future<void> _handleUpload(Exercicio exercicio) async {
    final upload = widget.onUploadVideo;
    if (upload == null || _uploading) return;
    setState(() => _uploading = true);
    try {
      final updated = await upload(exercicio);
      if (updated != null && mounted) {
        setState(() => _localUpdates[updated.id] = updated);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _toggleFavorite(Exercicio exercicio) async {
    final current = _resolve(exercicio);
    final makeFavorite = !current.favoritado;
    try {
      final repo = ref.read(exercicioRepositoryProvider);
      if (makeFavorite) {
        await repo.favoritarExercicio(current.id);
      } else {
        await repo.desfavoritarExercicio(current.id);
      }
      if (!mounted) return;
      final updated = current.copyWith(favoritado: makeFavorite);
      setState(() {
        if (_filter.somenteFavoritos && !makeFavorite) {
          _items.removeWhere((e) => e.id == updated.id);
          _localUpdates.remove(updated.id);
          if (_totalElements > 0) _totalElements -= 1;
        } else {
          _localUpdates[updated.id] = updated;
        }
      });
      FeedbackHelper.showSuccess(
        context,
        makeFavorite ? 'Adicionado aos favoritos' : 'Removido dos favoritos',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showApiFailure(context, e);
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
      // Vários grupos: uma consulta por grupo (mesma página) e a lista junta.
      final alvos = _grupos.isEmpty ? <GrupoMuscular?>[null] : _grupos.toList();
      final resultados = await Future.wait([
        for (final grupo in alvos)
          widget.onLoadPage(
            busca: _committedQuery,
            page: _page,
            filter: _filter,
            padrao: null,
            grupo: grupo,
          ),
      ]);
      if (!mounted) return;
      final vistos = <int>{};
      final novos = [
        for (final r in resultados)
          for (final e in r.content)
            if (vistos.add(e.id)) e,
      ];
      setState(() {
        if (reset) _items.clear();
        _items.addAll(novos);
        _totalElements = resultados.fold(
          0,
          (soma, r) => soma + r.meta.totalElements,
        );
        _hasNext = resultados.any((r) => r.meta.hasNext);
        _page = resultados.map((r) => r.meta.page).reduce(math.max) + 1;
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _letraFixa.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl
      ..removeListener(_onSearchTextChanged)
      ..dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Exercicio> _porIds(
    List<int> ids,
    List<Exercicio> loaded, {
    Set<int> ignorar = const {},
    int limite = 5,
  }) {
    final byId = <int, Exercicio>{
      for (final item in widget.shortcutItems) item.id: item,
      for (final item in loaded) item.id: item,
    };
    final out = <Exercicio>[];
    for (final id in ids) {
      if (ignorar.contains(id)) continue;
      final match = byId[id];
      if (match == null) continue;
      out.add(_resolve(match));
      if (out.length >= limite) break;
    }
    return out;
  }

  /// Seções da lista: Favoritos, Recentes, Mais usados e depois A–Z.
  List<ExerciseLibrarySection> _secoes(List<Exercicio> ordenados) {
    final atalhos = _mostraAtalhos;
    final favoritos =
        atalhos && !_filter.somenteFavoritos
            ? ordenados.where((e) => e.favoritado).toList()
            : const <Exercicio>[];
    final recentes =
        atalhos ? _porIds(widget.recentIds, ordenados) : const <Exercicio>[];
    final maisUsados =
        atalhos
            ? _porIds(
              widget.maisUsadosIds,
              ordenados,
              ignorar: {for (final e in recentes) e.id},
            )
            : const <Exercicio>[];
    final idsFavoritos = {for (final e in favoritos) e.id};
    return [
      if (favoritos.isNotEmpty)
        ExerciseLibrarySection(letter: 'Favoritos', items: favoritos),
      if (recentes.isNotEmpty)
        ExerciseLibrarySection(letter: 'Recentes', items: recentes),
      if (maisUsados.isNotEmpty)
        ExerciseLibrarySection(letter: 'Mais usados', items: maisUsados),
      ...buildExerciseLibrarySections([
        for (final e in ordenados)
          if (!idsFavoritos.contains(e.id)) e,
      ]),
    ];
  }

  static const _secoesEspeciais = {'Favoritos', 'Recentes', 'Mais usados'};

  void _saltarParaLetra(List<ExerciseLibrarySection> secoes, String letra) {
    var offset = 0.0;
    for (final s in secoes) {
      if (s.letter == letra) break;
      offset += _alturaCabecalho +
          s.items.length * _alturaLinha +
          FxSettingsLayout.groupGap;
    }
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.jumpTo(offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent));
    // Depois do salto aproximado, alinha pela seção de verdade se já existir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chavesDasLetras[letra]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 120));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ordenados = sortExerciciosAlfabetico(_items.map(_resolve));
    final secoes = _secoes(ordenados);
    _ordemDasSecoes = [for (final s in secoes) s.letter];
    final caption =
        _filter.isActive || _searching
            ? exercisePickerLibraryLines(
              filteredCount: _totalElements,
              totalCount: widget.libraryTotalCount,
              filter: _filter,
            )
            : null;
    final letras = [
      for (final s in secoes)
        if (!_secoesEspeciais.contains(s.letter)) s.letter,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            8,
            FxSettingsLayout.pageInset,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) widget.header!,
              TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                decoration: FxInputDeco.build(
                  context,
                  'Buscar',
                  icon: Icons.search_rounded,
                  hint: widget.searchPlaceholder,
                ).copyWith(
                  suffixIcon:
                      _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _committedQuery = '');
                              _fetchPage(reset: true);
                            },
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Limpar busca',
                          ),
                ),
              ),
              if (_termosReconhecidos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _termosReconhecidos)
                      ExercisePickerChip(
                        label: '${t.rotulo}  ✕',
                        selected: true,
                        primary: primary,
                        isDark: isDark,
                        onTap: () => _removerTermo(t),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              ExerciseGroupChips(
                selecionados: _grupos,
                noTreino: widget.balanco,
                onToggle: _alternarGrupo,
                marcadosPrimeiro: widget.gruposIniciais,
                primary: primary,
                isDark: isDark,
                antes: [
                  if (_temAlgoAlemDaSessao)
                    ExercisePickerChip(
                      label: 'Limpar',
                      selected: false,
                      primary: primary,
                      isDark: isDark,
                      onTap: _limparTudo,
                    ),
                ],
                extras: [
                  ExercisePickerChip(
                    label: rotuloDoEquipamento(_filter),
                    selected: _filter.isActive,
                    primary: primary,
                    isDark: isDark,
                    onTap: () => showExercisePickerFilterSheet(
                      context,
                      filter: _filter,
                      onChanged: _onFilterChanged,
                    ),
                  ),
                ],
              ),
              if (caption != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    caption.secondary == null ? caption.primary : '${caption.primary} · ${caption.secondary}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ExerciseBalanceStrip(
                balanco: widget.balanco,
                selecionados: _grupos,
                onToggle: _alternarGrupo,
                primary: primary,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown:
                      (_) => _focoAntesDoToque = _searchFocus.hasFocus,
                  child: KeyedSubtree(
                    key: _listaKey,
                    child: _buildBody(context, isDark, primary, secoes),
                  ),
                ),
              ),
              Positioned(
                left: FxSettingsLayout.pageInset,
                top: 4,
                child: IgnorePointer(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _letraFixa,
                    builder:
                        (context, letra, _) =>
                            letra == null
                                ? const SizedBox.shrink()
                                : _LetraFixa(
                                  letra: letra,
                                  primary: primary,
                                  isDark: isDark,
                                ),
                  ),
                ),
              ),
              if (!_searching && _grupos.isEmpty && letras.length >= 5)
                Positioned(
                  right: 2,
                  top: 8,
                  bottom: 8 + widget.bottomPadding,
                  child: ExerciseAlphaRail(
                    letras: letras,
                    isDark: isDark,
                    primary: primary,
                    onLetra: (l) => _saltarParaLetra(secoes, l),
                  ),
                ),
            ],
          ),
        ),
        if (widget.footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              8 + MediaQuery.paddingOf(context).bottom,
            ),
            child: widget.footer,
          )
        else
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color primary,
    List<ExerciseLibrarySection> secoes,
  ) {
    if (_loading && _items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          8,
        ),
        child: SkeletonList(count: 6),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          12,
          FxSettingsLayout.pageInset,
          12,
        ),
        child: FxErrorState(
          chromeOnDark: isDark,
          primary: primary,
          message: _error!,
          onRetry: () => _fetchPage(reset: true),
        ),
      );
    }
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          12,
          FxSettingsLayout.pageInset,
          12,
        ),
        child: FxEmptyState(
          icon: 'search',
          title:
              _committedQuery.isNotEmpty
                  ? 'Nada encontrado para "$_committedQuery"'
                  : _filter.isActive || _grupos.isNotEmpty
                  ? 'Nenhum exercício com estes filtros'
                  : 'Nenhum exercício nesta lista',
          subtitle:
              _filter.isActive ||
                      _grupos.isNotEmpty ||
                      _committedQuery.isNotEmpty
                  ? 'Tente outro termo ou limpe busca e filtros.'
                  : 'A biblioteca ainda está vazia.',
          action:
              _committedQuery.isNotEmpty && widget.onCadastrar != null
                  ? FxEmptyAction(
                    label: 'Não achou? Criar “$_committedQuery”',
                    onTap: () => widget.onCadastrar!(_committedQuery),
                  )
                  : _committedQuery.isNotEmpty ||
                      _filter.isActive ||
                      _grupos.isNotEmpty
                  ? FxEmptyAction(
                    label:
                        _committedQuery.isNotEmpty
                            ? 'Limpar busca'
                            : 'Limpar filtros',
                    secondary: true,
                    onTap: () {
                      if (_committedQuery.isNotEmpty) {
                        _searchCtrl.clear();
                        setState(() => _committedQuery = '');
                      } else {
                        _grupos.clear();
                        _onFilterChanged(const ExercisePickerFilter());
                        return;
                      }
                      _fetchPage(reset: true);
                    },
                  )
                  : null,
        ),
      );
    }

    return _GroupedExerciseList(
      controller: _scrollCtrl,
      sections: secoes,
      chaves: _chavesDasLetras,
      searchQuery: _committedQuery,
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
      resumoNoTreino: widget.resumoNoTreino,
      regioesAluno: widget.regioesAluno,
      uploading: _uploading,
      primary: primary,
      onUploadVideo: widget.onUploadVideo,
      onSelect: _aoSelecionar,
      onPreview: widget.onPreview,
      onUpload: _handleUpload,
      onFavoriteToggle: _toggleFavorite,
      loadingMore: _loadingMore,
      bottomPadding: widget.bottomPadding,
      rodape: widget.onCadastrar == null || _hasNext
          ? null
          : FxLinkRow(
              label: 'Criar meu exercício',
              icon: Icons.add_rounded,
              onTap: () => widget.onCadastrar!(null),
            ),
    );
  }
}

/// Letra (ou seção) do topo da lista, fixa enquanto se rola.
class _LetraFixa extends StatelessWidget {
  const _LetraFixa({
    required this.letra,
    required this.primary,
    required this.isDark,
  });

  final String letra;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Seção $letra',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCardHi : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: primary.withValues(alpha: 0.5)),
        ),
        child: Text(
          letra,
          style: TextStyle(
            color: primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GroupedExerciseList extends StatelessWidget {
  const _GroupedExerciseList({
    required this.controller,
    required this.sections,
    required this.chaves,
    required this.searchQuery,
    required this.alreadyInTreinoIds,
    this.resumoNoTreino = const {},
    this.regioesAluno = const {},
    required this.uploading,
    required this.primary,
    required this.onSelect,
    required this.onUpload,
    required this.onFavoriteToggle,
    this.onPreview,
    this.onUploadVideo,
    this.loadingMore = false,
    this.bottomPadding = 0,
    this.rodape,
  });

  /// Fim da lista ("Criar meu exercício"), só depois da última página.
  final Widget? rodape;

  final ScrollController controller;
  final List<ExerciseLibrarySection> sections;
  final Map<String, GlobalKey> chaves;
  final String searchQuery;
  final Set<int> alreadyInTreinoIds;
  final Map<int, String> resumoNoTreino;
  final Set<RegiaoCorpo> regioesAluno;
  final bool uploading;
  final Color primary;
  final ValueChanged<Exercicio> onSelect;
  final void Function(Exercicio exercicio)? onPreview;
  final Future<void> Function(Exercicio) onUpload;
  final Future<void> Function(Exercicio) onFavoriteToggle;
  final Future<Exercicio?> Function(Exercicio exercicio)? onUploadVideo;
  final bool loadingMore;
  final double bottomPadding;

  String? _alerta(Exercicio e) {
    final comum = regioesEmComum(regioesAluno, e);
    return comum.isEmpty ? null : 'Atenção: ${resumoRegioes(comum)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        4,
        FxSettingsLayout.pageInset + 20,
        12 + bottomPadding,
      ),
      itemCount: sections.length + (loadingMore || rodape != null ? 1 : 0),
      itemBuilder: (context, sectionIndex) {
        if (sectionIndex >= sections.length) {
          if (!loadingMore && rodape != null) {
            return Padding(padding: const EdgeInsets.only(top: 16), child: rodape);
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: FxLoading(size: 22)),
          );
        }

        final section = sections[sectionIndex];
        final chave = chaves.putIfAbsent(section.letter, GlobalKey.new);
        return Padding(
          key: chave,
          padding: EdgeInsets.only(
            bottom:
                sectionIndex < sections.length - 1
                    ? FxSettingsLayout.groupGap
                    : 0,
          ),
          child: FxSettingsGroup(
            header: section.letter,
            accent: primary,
            children: [
              for (var i = 0; i < section.items.length; i++)
                ExerciseLibraryRow(
                  exercicio: section.items[i],
                  searchQuery: searchQuery,
                  alreadyInTreino: alreadyInTreinoIds.contains(
                    section.items[i].id,
                  ),
                  resumoNoTreino: resumoNoTreino[section.items[i].id],
                  alerta: _alerta(section.items[i]),
                  showDivider: i < section.items.length - 1,
                  insetGroup: true,
                  uploadEnabled: onUploadVideo != null && !uploading,
                  onTap: () => onSelect(section.items[i]),
                  onFavoriteToggle: () => onFavoriteToggle(section.items[i]),
                  onPreviewThumb:
                      !canPreviewExerciseMedia(section.items[i])
                          ? null
                          : onPreview != null
                          ? () => onPreview!(section.items[i])
                          : () => showExerciseMediaPreview(
                            context,
                            exercicio: section.items[i],
                          ),
                  onUploadVideo:
                      onUploadVideo == null
                          ? null
                          : () => onUpload(section.items[i]),
                ),
            ],
          ),
        );
      },
    );
  }
}
