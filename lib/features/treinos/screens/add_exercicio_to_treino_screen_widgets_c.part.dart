part of 'add_exercicio_to_treino_screen.dart';

class _ExercisePickerSheet extends StatefulWidget {
  final Exercicio? selected;
  final Set<int> alreadyInTreinoIds;
  final String initialQuery;
  final String searchPlaceholder;
  final Future<ExercicioPickerPage> Function(String busca, int page) onLoadPage;
  final Future<Exercicio?> Function(Exercicio exercicio)? onUploadVideo;

  const _ExercisePickerSheet({
    required this.selected,
    required this.onLoadPage,
    this.alreadyInTreinoIds = const {},
    this.initialQuery = '',
    this.searchPlaceholder = 'Buscar por nome, músculo ou equipamento',
    this.onUploadVideo,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;
  Timer? _searchDebounce;
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

  @override
  void initState() {
    super.initState();
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
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final next = _searchCtrl.text.trim();
      if (next == _committedQuery) return;
      setState(() => _committedQuery = next);
      _fetchPage(reset: true);
    });
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
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final sorted = sortExerciciosForPicker(
      _items.map(_resolve),
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
    );

    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Biblioteca de exercícios',
            subtitle:
                _totalElements == 0
                    ? 'Carregando...'
                    : '${sorted.length} de $_totalElements disponíveis',
            leading: Icon(
              Icons.fitness_center_rounded,
              color: primary,
              size: 18,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            autofocus: widget.initialQuery.isEmpty,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.searchPlaceholder,
              prefixIcon: Icon(Icons.search_rounded, color: primary),
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
                      ),
              filled: true,
              fillColor: isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: line),
              ),
              enabledBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: line),
              ),
              focusedBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: FxLoading(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: _error!,
                onRetry: () => _fetchPage(reset: true),
              ),
            )
          else if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FxEmptyState(
                icon: 'search',
                title:
                    _committedQuery.isNotEmpty
                        ? 'Nada encontrado para "$_committedQuery"'
                        : 'Nenhum exercício nesta lista',
                subtitle: 'Tente outro termo ou limpe a busca.',
                action:
                    _committedQuery.isNotEmpty
                        ? FxEmptyAction(
                          label: 'Limpar busca',
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _committedQuery = '');
                            _fetchPage(reset: true);
                          },
                        )
                        : null,
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (maxHeight - 220).clamp(220.0, 480.0),
              ),
              child: ListView(
                controller: _scrollCtrl,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  FxSettingsGroup(
                    accent: primary,
                    children: [
                      for (var i = 0; i < sorted.length; i++)
                        _ExercisePickerTile(
                          exercicio: sorted[i],
                          selected: widget.selected?.id == sorted[i].id,
                          alreadyInTreino: widget.alreadyInTreinoIds.contains(
                            sorted[i].id,
                          ),
                          highlightQuery: _committedQuery,
                          primary: primary,
                          isDark: isDark,
                          showDivider: i < sorted.length - 1,
                          uploadEnabled:
                              widget.onUploadVideo != null &&
                              !_uploadingInSheet,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context, sorted[i]);
                          },
                          onPreviewThumb:
                              canPreviewExerciseMedia(sorted[i])
                                  ? () => showExerciseMediaPreview(
                                    context,
                                    exercicio: sorted[i],
                                  )
                                  : null,
                          onUploadVideo:
                              widget.onUploadVideo == null
                                  ? null
                                  : () => _handleUpload(sorted[i]),
                        ),
                    ],
                  ),
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: FxLoading(size: 22)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: FxSettingsLayout.footerAfterGroup),
        ],
      ),
    );
  }
}

class _ExercisePickerTile extends StatelessWidget {
  final Exercicio exercicio;
  final bool selected;
  final bool alreadyInTreino;
  final String highlightQuery;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onPreviewThumb;
  final VoidCallback? onUploadVideo;
  final bool uploadEnabled;
  final bool showDivider;

  const _ExercisePickerTile({
    required this.exercicio,
    required this.selected,
    this.alreadyInTreino = false,
    this.highlightQuery = '',
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.onPreviewThumb,
    this.onUploadVideo,
    this.uploadEnabled = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle =
        alreadyInTreino
            ? 'Já está neste treino · ${_exerciseMeta(exercicio)}'
            : _exerciseMeta(exercicio);

    return FxSettingsTile(
      icon: Icons.fitness_center_rounded,
      accent: primary,
      label: exercicio.nomeDisplay,
      subtitle: subtitle,
      value: '',
      highlight: selected,
      showDivider: showDivider,
      onTap: onTap,
      accessory: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onUploadVideo != null)
            IconButton(
              tooltip:
                  exercicioHasPersonalVideo(exercicio)
                      ? 'Trocar vídeo do personal'
                      : 'Enviar vídeo do personal',
              onPressed: uploadEnabled ? onUploadVideo : null,
              icon: Icon(
                exercicioHasPersonalVideo(exercicio)
                    ? Icons.swap_horiz_rounded
                    : Icons.video_call_outlined,
                color: primary,
                size: 20,
              ),
            ),
          if (onPreviewThumb != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onPreviewThumb!();
              },
              child: ExerciseMediaThumb.fromExercicio(exercicio, size: 34),
            ),
        ],
      ),
    );
  }
}

String _exerciseMeta(Exercicio exercicio) {
  final parts = <String>[
    if (exercicio.grupoMuscularPrimario != null)
      TaxonomyLabels.grupo[exercicio.grupoMuscularPrimario!] ??
          _humanizeMetaToken(exercicio.grupoMuscularPrimario!.backendName),
    if (exercicio.grupoMuscularPrimario == null &&
        exercicio.primaryGroupLabel?.trim().isNotEmpty == true)
      _humanizeMetaToken(exercicio.primaryGroupLabel!),
    if (exercicio.equipamentos.isNotEmpty)
      exercicio.equipamentos
          .take(2)
          .map((e) => TaxonomyLabels.equipamento[e])
          .whereType<String>()
          .join(' / '),
    if (exercicio.equipamentos.isEmpty &&
        exercicio.equipamento?.trim().isNotEmpty == true)
      _humanizeMetaToken(exercicio.equipamento!),
    if (exercicio.dificuldade != null)
      TaxonomyLabels.dificuldade[exercicio.dificuldade!] ??
          _humanizeMetaToken(exercicio.dificuldade!.backendName),
    if (exercicio.dificuldade == null &&
        exercicio.nivel?.trim().isNotEmpty == true)
      _humanizeMetaToken(exercicio.nivel!),
  ];
  final clean = parts.whereType<String>().where((e) => e.isNotEmpty).toList();
  return clean.isEmpty ? 'Sem detalhes' : clean.take(3).join(' · ');
}

Color _metaTextColor(bool isDark, {bool muted = true}) {
  final base = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
  if (isDark) return base;
  final lerp = muted ? 0.55 : 0.38;
  return Color.lerp(base, TokensStrip.textPrimary, lerp)!;
}

String _humanizeMetaToken(String value) => displayMetaToken(value);

class _PresetSelector extends StatelessWidget {
  final String selectedId;
  final Color primary;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const _PresetSelector({
    required this.selectedId,
    required this.primary,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = workoutBuilderPresetById(selectedId);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Presets de prescrição',
                style: FocuxHubTypography.bodyMuted(
                  color: ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                workoutBuilderPresets.map((preset) {
                  final isSelected = preset.id == selectedId;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(preset.label),
                    labelStyle: FocuxHubTypography.chip(
                      isSelected ? Colors.white : primary,
                    ),
                    selectedColor: primary,
                    backgroundColor: primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: primary.withValues(alpha: isSelected ? 0 : 0.24),
                    ),
                    onSelected: (_) => onSelected(preset.id),
                  );
                }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            selected.summary,
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SerieTypeSelector extends StatelessWidget {
  final String value;
  final Color primary;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SerieTypeSelector({
    required this.value,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final options = const [
      ('NORMAL', Icons.fitness_center_rounded, 'Normal'),
      ('SUPERSET', Icons.link_rounded, 'Superset'),
      ('DROPSET', Icons.trending_down_rounded, 'Drop set'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de série',
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.map((option) {
                  final selected = value == option.$1;
                  return ChoiceChip(
                    selected: selected,
                    avatar: Icon(
                      option.$2,
                      size: 16,
                      color: selected ? Colors.white : primary,
                    ),
                    label: Text(option.$3),
                    labelStyle: FocuxHubTypography.chip(
                      selected ? Colors.white : primary,
                    ),
                    selectedColor: primary,
                    backgroundColor: primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: primary.withValues(alpha: selected ? 0 : 0.25),
                    ),
                    onSelected: (_) => onChanged(option.$1),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ModeHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _ModeHint({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: FocuxHubTypography.bodyMuted(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
