import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../exercicios/data/exercicio_page.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/screens/widgets/exercise_video_preview_sheet.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';
import '../utils/exercise_picker_filter.dart';
import '../utils/exercise_picker_library_label.dart';
import '../utils/exercise_picker_sort.dart';
import 'exercise_library_row.dart';

Future<Exercicio?> showExerciseLibrarySheet(
  BuildContext context, {
  required Exercicio? selected,
  required Set<int> alreadyInTreinoIds,
  required ExercisePickerFilter filter,
  required int libraryTotalCount,
  required ValueChanged<ExercisePickerFilter> onFilterChanged,
  required Future<ExercicioPickerPage> Function(String busca, int page) onLoadPage,
  String initialQuery = '',
  String searchPlaceholder = 'Buscar por nome, músculo ou equipamento',
  Future<Exercicio?> Function(Exercicio exercicio)? onUploadVideo,
}) {
  HapticFeedback.selectionClick();
  return showFxHomeSheet<Exercicio>(
    context,
    builder:
        (ctx) => _ExerciseLibrarySheet(
          selected: selected,
          alreadyInTreinoIds: alreadyInTreinoIds,
          initialQuery: initialQuery,
          searchPlaceholder: searchPlaceholder,
          filter: filter,
          libraryTotalCount: libraryTotalCount,
          onFilterChanged: onFilterChanged,
          onLoadPage: onLoadPage,
          onUploadVideo: onUploadVideo,
        ),
  );
}

class _ExerciseLibrarySheet extends StatefulWidget {
  const _ExerciseLibrarySheet({
    required this.selected,
    required this.alreadyInTreinoIds,
    required this.filter,
    required this.libraryTotalCount,
    required this.onFilterChanged,
    required this.onLoadPage,
    this.initialQuery = '',
    this.searchPlaceholder = 'Buscar por nome, músculo ou equipamento',
    this.onUploadVideo,
  });

  final Exercicio? selected;
  final Set<int> alreadyInTreinoIds;
  final String initialQuery;
  final String searchPlaceholder;
  final ExercisePickerFilter filter;
  final int libraryTotalCount;
  final ValueChanged<ExercisePickerFilter> onFilterChanged;
  final Future<ExercicioPickerPage> Function(String busca, int page) onLoadPage;
  final Future<Exercicio?> Function(Exercicio exercicio)? onUploadVideo;

  @override
  State<_ExerciseLibrarySheet> createState() => _ExerciseLibrarySheetState();
}

class _ExerciseLibrarySheetState extends State<_ExerciseLibrarySheet> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;
  Timer? _searchDebounce;
  late ExercisePickerFilter _filter;
  String _committedQuery = '';
  final Map<int, Exercicio> _localUpdates = {};
  final List<Exercicio> _items = [];
  bool _uploadingInSheet = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 0;
  int _totalElements = 0;
  String? _error;

  Exercicio _resolve(Exercicio exercicio) =>
      _localUpdates[exercicio.id] ?? exercicio;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
    _committedQuery = widget.initialQuery.trim();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
    _fetchPage(reset: true);
  }

  void _onScroll() {
    if (!_hasNext || _loadingMore || _loading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      _fetchPage(reset: false);
    }
  }

  void _onSearchChanged() {
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

  Future<void> _handleUpload(Exercicio exercicio) async {
    final upload = widget.onUploadVideo;
    if (upload == null || _uploadingInSheet) return;
    setState(() => _uploadingInSheet = true);
    try {
      final updated = await upload(exercicio);
      if (updated != null && mounted) {
        setState(() => _localUpdates[updated.id] = updated);
      }
    } finally {
      if (mounted) setState(() => _uploadingInSheet = false);
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
      final result = await widget.onLoadPage(_committedQuery, _page);
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
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final sorted = sortExerciciosForPicker(
      _items.map(_resolve),
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
    );
    final subtitle = exerciseLibrarySheetSubtitle(
      filteredCount: _totalElements,
      totalCount: widget.libraryTotalCount,
      filter: _filter,
      committedQuery: _committedQuery,
    );
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;

    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight: maxHeight,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: 8),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Biblioteca de exercícios',
            subtitle: _loading && _items.isEmpty ? null : subtitle,
            leading: Icon(
              Icons.library_books_outlined,
              color: primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          _LibrarySearchPanel(
            isDark: isDark,
            primary: primary,
            searchCtrl: _searchCtrl,
            searchPlaceholder: widget.searchPlaceholder,
            filter: _filter,
            resultCaption:
                _filter.isActive || _committedQuery.length >= 2
                    ? exercisePickerLibraryLines(
                      filteredCount: _totalElements,
                      totalCount: widget.libraryTotalCount,
                      filter: _filter,
                    )
                    : null,
            onFilterChanged: _onFilterChanged,
            onClearSearch: () {
              _searchCtrl.clear();
              setState(() => _committedQuery = '');
              _fetchPage(reset: true);
            },
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBody(context, isDark, primary, sorted)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color primary,
    List<Exercicio> sorted,
  ) {
    if (_loading && sorted.isEmpty) {
      return const _ExerciseLibraryListShimmer();
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.zero,
      itemCount: sorted.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sorted.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: FxLoading(size: 22)),
          );
        }
        final exercicio = sorted[index];
        return ExerciseLibraryRow(
          exercicio: exercicio,
          selected: widget.selected?.id == exercicio.id,
          alreadyInTreino: widget.alreadyInTreinoIds.contains(exercicio.id),
          showDivider: index < sorted.length - 1,
          uploadEnabled: widget.onUploadVideo != null && !_uploadingInSheet,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, exercicio);
          },
          onPreviewThumb:
              canPreviewExerciseMedia(exercicio)
                  ? () => showExerciseMediaPreview(
                    context,
                    exercicio: exercicio,
                  )
                  : null,
          onUploadVideo:
              widget.onUploadVideo == null
                  ? null
                  : () => _handleUpload(exercicio),
        );
      },
    );
  }
}

class _LibrarySearchPanel extends StatefulWidget {
  const _LibrarySearchPanel({
    required this.isDark,
    required this.primary,
    required this.searchCtrl,
    required this.searchPlaceholder,
    required this.filter,
    required this.onFilterChanged,
    required this.onClearSearch,
    this.resultCaption,
  });

  final bool isDark;
  final Color primary;
  final TextEditingController searchCtrl;
  final String searchPlaceholder;
  final ExercisePickerFilter filter;
  final ValueChanged<ExercisePickerFilter> onFilterChanged;
  final VoidCallback onClearSearch;
  final ExercisePickerLibraryLines? resultCaption;

  @override
  State<_LibrarySearchPanel> createState() => _LibrarySearchPanelState();
}

class _LibrarySearchPanelState extends State<_LibrarySearchPanel> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.searchCtrl.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.searchCtrl.text.isEmpty) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onSearchTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_onSearchTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: fxListCardDecoration(
        context,
        accent: widget.primary,
        radius: FxSettingsLayout.groupRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: widget.searchCtrl,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.searchPlaceholder,
                prefixIcon: Icon(Icons.search_rounded, color: widget.primary),
                suffixIcon:
                    widget.searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                          onPressed: widget.onClearSearch,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Limpar busca',
                        ),
                filled: true,
                fillColor:
                    widget.isDark
                        ? EagleTokens.darkCardHi
                        : TokensStrip.cardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ExercisePickerFilterBar(
              filter: widget.filter,
              isDark: widget.isDark,
              primary: widget.primary,
              resultCaption: widget.resultCaption,
              onChanged: widget.onFilterChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseLibraryListShimmer extends StatelessWidget {
  const _ExerciseLibraryListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder:
          (context, index) => FxLoading.sectionShimmer(
            context,
            height: 52,
            showHeader: true,
          ),
    );
  }
}
