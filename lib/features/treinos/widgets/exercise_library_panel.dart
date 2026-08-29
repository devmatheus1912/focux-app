import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_page.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/data/exercise_enum_api.dart';
import '../../exercicios/providers/exercicio_picker_provider.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/screens/widgets/exercise_video_preview_sheet.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';
import '../utils/exercise_library_sections.dart';
import '../utils/exercise_picker_filter.dart';
import '../utils/exercise_picker_library_label.dart';
import '../utils/exercise_picker_sort.dart';
import 'exercise_library_row.dart';

typedef ExerciseLibraryPageLoader =
    Future<ExercicioPickerPage> Function({
      required String busca,
      required int page,
      required ExercisePickerFilter filter,
      PadraoMovimento? padrao,
      GrupoMuscular? grupo,
    });

enum ExerciseLibraryBrowseMode { todos, musculo }

/// Biblioteca paginada: busca, filtros, músculo e lista A–Z.
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
    this.shortcutItems = const [],
    this.header,
    this.footer,
    this.onUploadVideo,
  });

  final Set<int> alreadyInTreinoIds;
  final ExercisePickerFilter filter;
  final ValueChanged<ExercisePickerFilter> onFilterChanged;
  final ExerciseLibraryPageLoader onLoadPage;
  final ValueChanged<Exercicio> onSelect;
  final int libraryTotalCount;
  final String searchPlaceholder;
  final String initialQuery;
  final List<int> recentIds;
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
  ExerciseLibraryBrowseMode _browse = ExerciseLibraryBrowseMode.todos;
  GrupoMuscular? _grupo;
  final Map<int, Exercicio> _localUpdates = {};
  final List<Exercicio> _items = [];
  bool _uploading = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 0;
  int _totalElements = 0;
  String? _error;

  Exercicio _resolve(Exercicio exercicio) =>
      _localUpdates[exercicio.id] ?? exercicio;

  bool get _searching => _committedQuery.trim().length >= 2;

  bool get _showCategoryTiles =>
      !_searching &&
      _browse == ExerciseLibraryBrowseMode.musculo &&
      _grupo == null;

  bool get _showRecents =>
      !_searching &&
      _browse == ExerciseLibraryBrowseMode.todos &&
      _grupo == null &&
      widget.recentIds.isNotEmpty;

  String? get _categoryChipLabel {
    if (_grupo == null) return null;
    return TaxonomyLabels.grupo[_grupo] ?? _grupo!.name;
  }

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
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

  void _onScroll() {
    if (_showCategoryTiles || !_hasNext || _loadingMore || _loading) return;
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

  void _onFilterChanged(ExercisePickerFilter next) {
    setState(() => _filter = next);
    widget.onFilterChanged(next);
    _fetchPage(reset: true);
  }

  void _setBrowse(ExerciseLibraryBrowseMode mode) {
    if (_browse == mode && _grupo == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _browse = mode;
      _grupo = null;
    });
    if (!_showCategoryTiles) {
      _fetchPage(reset: true);
    }
  }

  void _selectGrupo(GrupoMuscular grupo) {
    HapticFeedback.selectionClick();
    setState(() {
      _browse = ExerciseLibraryBrowseMode.musculo;
      _grupo = grupo;
    });
    _fetchPage(reset: true);
  }

  void _clearCategory() {
    HapticFeedback.selectionClick();
    setState(() => _grupo = null);
    if (_browse == ExerciseLibraryBrowseMode.todos) {
      _fetchPage(reset: true);
    }
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

  Future<void> _fetchPage({required bool reset}) async {
    if (_showCategoryTiles && !_searching) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = null;
        });
      }
      return;
    }
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
      final result = await widget.onLoadPage(
        busca: _committedQuery,
        page: _page,
        filter: _filter,
        padrao: null,
        grupo: _grupo,
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl
      ..removeListener(_onSearchTextChanged)
      ..dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Exercicio> _recentExercicios(List<Exercicio> loaded) {
    if (!_showRecents) return const [];
    final byId = <int, Exercicio>{
      for (final item in widget.shortcutItems) item.id: item,
      for (final item in loaded) item.id: item,
    };
    final out = <Exercicio>[];
    for (final id in widget.recentIds) {
      final match = byId[id];
      if (match == null) continue;
      out.add(_resolve(match));
      if (out.length >= 5) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final sorted = sortExerciciosForPicker(
      _items.map(_resolve),
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
    );
    final caption =
        _filter.isActive || _searching
            ? exercisePickerLibraryLines(
              filteredCount: _totalElements,
              totalCount: widget.libraryTotalCount,
              filter: _filter,
            )
            : null;

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
                  'Buscar exercício',
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
              const SizedBox(height: 10),
              ExercisePickerFilterBar(
                filter: _filter,
                isDark: isDark,
                primary: primary,
                resultCaption: caption,
                onChanged: _onFilterChanged,
              ),
              const SizedBox(height: 10),
              _BrowseSegmentStrip(
                selected: _browse,
                primary: primary,
                isDark: isDark,
                onChanged: _setBrowse,
              ),
              if (_categoryChipLabel != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CategoryClearChip(
                    label: _categoryChipLabel!,
                    primary: primary,
                    isDark: isDark,
                    onClear: _clearCategory,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildBody(context, isDark, primary, sorted),
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
    List<Exercicio> sorted,
  ) {
    if (_showCategoryTiles) {
      return _CategoryTilesBody(
        primary: primary,
        onSelectGrupo: _selectGrupo,
      );
    }

    if (_loading && sorted.isEmpty) {
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
    if (sorted.isEmpty) {
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
                  : _filter.isActive
                  ? 'Nenhum exercício com estes filtros'
                  : 'Nenhum exercício nesta lista',
          subtitle:
              _filter.isActive || _committedQuery.isNotEmpty
                  ? 'Tente outro termo ou limpe busca e filtros.'
                  : 'A biblioteca ainda está vazia.',
          action:
              _committedQuery.isNotEmpty || _filter.isActive
                  ? FxEmptyAction(
                    label:
                        _committedQuery.isNotEmpty
                            ? 'Limpar busca'
                            : 'Limpar filtros',
                    onTap: () {
                      if (_committedQuery.isNotEmpty) {
                        _searchCtrl.clear();
                        setState(() => _committedQuery = '');
                      } else {
                        _onFilterChanged(const ExercisePickerFilter());
                      }
                      _fetchPage(reset: true);
                    },
                  )
                  : null,
        ),
      );
    }

    final recents = _recentExercicios(sorted);
    final sections = <ExerciseLibrarySection>[
      if (recents.isNotEmpty)
        ExerciseLibrarySection(letter: 'Recentes', items: recents),
      ...buildExerciseLibrarySections(sorted),
    ];

    return _GroupedExerciseList(
      controller: _scrollCtrl,
      sections: sections,
      searchQuery: _committedQuery,
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
      uploading: _uploading,
      primary: primary,
      onUploadVideo: widget.onUploadVideo,
      onSelect: widget.onSelect,
      onUpload: _handleUpload,
      loadingMore: _loadingMore,
    );
  }
}

class _BrowseSegmentStrip extends StatelessWidget {
  const _BrowseSegmentStrip({
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  final ExerciseLibraryBrowseMode selected;
  final Color primary;
  final bool isDark;
  final ValueChanged<ExerciseLibraryBrowseMode> onChanged;

  static const _tabs = [
    (
      mode: ExerciseLibraryBrowseMode.todos,
      label: 'Todos',
      semantics: 'Todos os exercícios',
    ),
    (
      mode: ExerciseLibraryBrowseMode.musculo,
      label: 'Músculo',
      semantics: 'Filtrar por grupo muscular',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Semantics(
      container: true,
      label: 'Ver todos ou por músculo',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          border: Border.all(
            color: line.withValues(alpha: isDark ? 0.7 : 0.85),
          ),
          color: isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
        ),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    width: 1,
                    thickness: FxSettingsLayout.dividerThickness,
                    color: line.withValues(alpha: isDark ? 0.55 : 0.7),
                  ),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected == _tabs[i].mode,
                    label: _tabs[i].semantics,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onChanged(_tabs[i].mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.center,
                          color:
                              selected == _tabs[i].mode
                                  ? action.withValues(
                                    alpha: isDark ? 0.18 : 0.10,
                                  )
                                  : Colors.transparent,
                          child: Text(
                            _tabs[i].label,
                            style: FocuxHubTypography.chip(
                              selected == _tabs[i].mode ? action : ink,
                            ).copyWith(
                              fontSize: 12,
                              fontWeight:
                                  selected == _tabs[i].mode
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                              color:
                                  selected == _tabs[i].mode ? action : mute,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryClearChip extends StatelessWidget {
  const _CategoryClearChip({
    required this.label,
    required this.primary,
    required this.isDark,
    required this.onClear,
  });

  final String label;
  final Color primary;
  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Limpar categoria $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClear,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(
                      color: primary,
                      fontWeight: FontWeight.w800,
                    ).copyWith(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.close_rounded, size: 15, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTilesBody extends ConsumerWidget {
  const _CategoryTilesBody({
    required this.primary,
    required this.onSelectGrupo,
  });

  final Color primary;
  final ValueChanged<GrupoMuscular> onSelectGrupo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(exercicioPickerStatsProvider);
    final soft = BrandPalette.softened(primary);

    return statsAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              8,
            ),
            child: SkeletonList(count: 6),
          ),
      error:
          (_, __) => Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              12,
              FxSettingsLayout.pageInset,
              12,
            ),
            child: FxEmptyState(
              icon: 'wifi-off',
              title: 'Não carregamos as categorias',
              subtitle: 'Verifique a conexão e tente de novo.',
              action: FxEmptyAction(
                label: 'Tentar novamente',
                onTap: () => ref.invalidate(exercicioPickerStatsProvider),
              ),
            ),
          ),
      data: (stats) {
        final items = [
          for (final grupo in GrupoMuscular.values)
            if (exercisePickerStatCount(stats.porGrupo, grupo.name) > 0)
              (
                label: TaxonomyLabels.grupo[grupo] ?? grupo.name,
                count: exercisePickerStatCount(stats.porGrupo, grupo.name),
                onTap: () => onSelectGrupo(grupo),
              ),
        ]..sort((a, b) => b.count.compareTo(a.count));

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              12,
              FxSettingsLayout.pageInset,
              12,
            ),
            child: FxEmptyState(
              icon: 'search',
              title: 'Sem grupos musculares',
              subtitle: 'Volte para Todos ou busque pelo nome.',
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            4,
            FxSettingsLayout.pageInset,
            16,
          ),
          children: [
            FxSettingsGroup(
              accent: primary,
              caption: 'Grupos musculares · ${items.length}',
              children: [
                for (var i = 0; i < items.length; i++)
                  FxSettingsTile(
                    icon: Icons.fitness_center_outlined,
                    accent: soft,
                    label: items[i].label,
                    subtitle:
                        items[i].count == 1
                            ? '1 exercício'
                            : '${items[i].count} exercícios',
                    value: '',
                    showDivider: i < items.length - 1,
                    onTap: items[i].onTap,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GroupedExerciseList extends StatelessWidget {
  const _GroupedExerciseList({
    required this.controller,
    required this.sections,
    required this.searchQuery,
    required this.alreadyInTreinoIds,
    required this.uploading,
    required this.primary,
    required this.onSelect,
    required this.onUpload,
    this.onUploadVideo,
    this.loadingMore = false,
  });

  final ScrollController controller;
  final List<ExerciseLibrarySection> sections;
  final String searchQuery;
  final Set<int> alreadyInTreinoIds;
  final bool uploading;
  final Color primary;
  final ValueChanged<Exercicio> onSelect;
  final Future<void> Function(Exercicio) onUpload;
  final Future<Exercicio?> Function(Exercicio exercicio)? onUploadVideo;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        4,
        FxSettingsLayout.pageInset,
        12,
      ),
      itemCount: sections.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, sectionIndex) {
        if (sectionIndex >= sections.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: FxLoading(size: 22)),
          );
        }

        final section = sections[sectionIndex];
        return Padding(
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
                  showDivider: i < section.items.length - 1,
                  insetGroup: true,
                  uploadEnabled: onUploadVideo != null && !uploading,
                  onTap: () => onSelect(section.items[i]),
                  onPreviewThumb:
                      canPreviewExerciseMedia(section.items[i])
                          ? () => showExerciseMediaPreview(
                            context,
                            exercicio: section.items[i],
                          )
                          : null,
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
