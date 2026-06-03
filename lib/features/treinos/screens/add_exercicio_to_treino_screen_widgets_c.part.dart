part of 'add_exercicio_to_treino_screen.dart';

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercicio> exercicios;
  final Exercicio? selected;
  final Set<int> alreadyInTreinoIds;
  final String initialQuery;
  final Future<Exercicio?> Function(Exercicio exercicio)? onUploadVideo;

  const _ExercisePickerSheet({
    required this.exercicios,
    required this.selected,
    this.alreadyInTreinoIds = const {},
    this.initialQuery = '',
    this.onUploadVideo,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final TextEditingController _searchCtrl;
  late String _query;
  Timer? _searchDebounce;
  String _highlightQuery = '';
  final Map<int, Exercicio> _localUpdates = {};
  bool _uploadingInSheet = false;

  List<Exercicio> get _exercicios =>
      widget.exercicios
          .map((exercicio) => _localUpdates[exercicio.id] ?? exercicio)
          .toList();

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
    _query = widget.initialQuery;
    _highlightQuery = widget.initialQuery.trim();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = _searchCtrl.text;
    setState(() => _query = text);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _highlightQuery = text.trim());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final normalized = _query.trim().toLowerCase();
    final filtered = sortExerciciosForPicker(
      normalized.isEmpty
          ? _exercicios
          : _exercicios.where((exercicio) {
            final haystack =
                '${exercicio.nome} ${exercicio.musculoAlvo ?? ''} '
                        '${exercicio.equipamento ?? ''} ${exercicio.nivel ?? ''}'
                    .toLowerCase();
            return haystack.contains(normalized);
          }),
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 8 + keyboardInset),
            child: Container(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 10, 16, 16),
              decoration: fxListCardDecoration(context, accent: primary),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : TokensStrip.borderDefault,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: EagleTokens.brandSofter,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.fitness_center_rounded, color: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biblioteca de exercícios',
                              style: AppTypography.inter(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${filtered.length} de ${_exercicios.length} disponíveis',
                              style: AppTypography.inter(
                                color: mute,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchCtrl,
                    autofocus: widget.initialQuery.isEmpty,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, músculo ou equipamento',
                      prefixIcon: Icon(Icons.search_rounded, color: primary),
                      suffixIcon:
                          _searchCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _query = '';
                                    _highlightQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      filled: true,
                      fillColor:
                          isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
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
                  Expanded(
                    child:
                        filtered.isEmpty
                            ? _PickerSheetEmptyState(
                              query: _query,
                              isDark: isDark,
                              primary: primary,
                              onClear:
                                  () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _query = '';
                                      _highlightQuery = '';
                                    });
                                  },
                            )
                            : ListView.separated(
                              controller: scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final exercicio = _resolve(filtered[index]);
                                final selected =
                                    widget.selected?.id == exercicio.id;
                                return _ExercisePickerTile(
                                  exercicio: exercicio,
                                  selected: selected,
                                  alreadyInTreino:
                                      widget.alreadyInTreinoIds.contains(
                                        exercicio.id,
                                      ),
                                  highlightQuery: _highlightQuery,
                                  primary: primary,
                                  isDark: isDark,
                                  uploadEnabled:
                                      widget.onUploadVideo != null &&
                                      !_uploadingInSheet,
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
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PickerSheetEmptyState extends StatelessWidget {
  const _PickerSheetEmptyState({
    required this.query,
    required this.isDark,
    required this.primary,
    required this.onClear,
  });

  final String query;
  final bool isDark;
  final Color primary;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final hasQuery = query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: primary.withValues(alpha: 0.75),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'Nada encontrado para "${query.trim()}"'
                  : 'Nenhum exercício nesta lista',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Tente outro termo ou limpe a busca.'
                  : 'Ajuste os filtros na tela anterior.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: mute,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: onClear,
                child: const Text('Limpar busca'),
              ),
            ],
          ],
        ),
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
  });

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Semantics(
      button: true,
      selected: selected,
      label: exercicio.nomeDisplay,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected
                    ? EagleTokens.brandSofter
                    : isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? primary.withValues(alpha: 0.30)
                      : line.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            children: [
              if (onPreviewThumb != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPreviewThumb!();
                  },
                  child: ExerciseMediaThumb.fromExercicio(
                    exercicio,
                    size: 44,
                    radius: 14,
                  ),
                )
              else
                ExerciseMediaThumb.fromExercicio(
                  exercicio,
                  size: 44,
                  radius: 14,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    highlightedExerciseName(
                      name: exercicio.nomeDisplay,
                      query: highlightQuery,
                      baseStyle: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      highlightColor: primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alreadyInTreino
                          ? 'Já está neste treino · ${_exerciseMeta(exercicio)}'
                          : _exerciseMeta(exercicio),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: _metaTextColor(isDark),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onUploadVideo != null) ...[
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
                    size: 22,
                  ),
                ),
              ],
              Icon(Icons.chevron_right_rounded, color: mute, size: 20),
            ],
          ),
        ),
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
  final base =
      isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
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
                style: AppTypography.inter(
                  color: ink,
                  fontSize: 13,
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
                    labelStyle: AppTypography.inter(
                      color: isSelected ? Colors.white : primary,
                      fontWeight: FontWeight.w800,
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
            style: AppTypography.inter(
              color: mute,
              fontSize: 12.5,
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
            style: AppTypography.inter(
              color: mute,
              fontSize: 12,
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
                    labelStyle: AppTypography.inter(
                      color: selected ? Colors.white : primary,
                      fontWeight: FontWeight.w800,
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
              style: AppTypography.inter(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Premium composed error state for exercise loading
// ──────────────────────────────────────────────
class _ExercicioErrorState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;

  const _ExercicioErrorState({
    required this.isDark,
    required this.primary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(alpha: isDark ? 0.18 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: EagleTokens.bad,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Erro ao carregar exercícios',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(color: mute, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Centralized premium InputDecoration factory
// ──────────────────────────────────────────────
InputDecoration _fxInputDecoration({
  required String label,
  required bool isDark,
  required Color primary,
  String? helper,
}) {
  final fillColor = isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg;
  final lineColor = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
  final labelColor =
      isDark
          ? EagleTokens.darkInk
          : Color.lerp(
            TokensStrip.textSecondary,
            TokensStrip.textPrimary,
            0.55,
          )!;

  return InputDecoration(
    labelText: label,
    helperText: helper,
    labelStyle: AppTypography.inter(
      color: labelColor,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
    floatingLabelStyle: AppTypography.inter(
      color: primary,
      fontSize: 12.5,
      fontWeight: FontWeight.w900,
    ),
    filled: true,
    fillColor: fillColor,
    border: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: lineColor),
    ),
    enabledBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: lineColor),
    ),
    focusedBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: primary, width: 1.6),
    ),
    errorBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EagleTokens.bad),
    ),
    focusedErrorBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EagleTokens.bad, width: 1.6),
    ),
  );
}
