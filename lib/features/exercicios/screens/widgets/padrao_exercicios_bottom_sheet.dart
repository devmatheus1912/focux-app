import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../core/widgets/fx_home_sheet.dart';
import '../../../../core/widgets/fx_loading.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../providers/exercicios_provider.dart';
import '../../../treinos/utils/exercise_picker_filter.dart';
import '../../../treinos/utils/exercise_picker_sort.dart';
import '../../data/enums.dart';
import '../../data/exercise_enum_api.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import 'exercise_media_thumb.dart';
import 'exercise_video_preview_sheet.dart';

class PadraoExerciciosBottomSheet extends ConsumerStatefulWidget {
  const PadraoExerciciosBottomSheet({
    super.key,
    this.padrao,
    this.grupo,
    required this.onAdicionar,
    this.alreadyInTreinoIds = const {},
    this.pickerFilter = const ExercisePickerFilter(),
  });

  final PadraoMovimento? padrao;
  final GrupoMuscular? grupo;
  final ValueChanged<Exercicio> onAdicionar;
  final Set<int> alreadyInTreinoIds;
  final ExercisePickerFilter pickerFilter;

  @override
  ConsumerState<PadraoExerciciosBottomSheet> createState() =>
      _PadraoExerciciosBottomSheetState();
}

class _PadraoExerciciosBottomSheetState
    extends ConsumerState<PadraoExerciciosBottomSheet> {
  final ScrollController _scrollCtrl = ScrollController();
  final List<Exercicio> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 0;
  int _totalElements = 0;
  String? _error;

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
          .listarPickerPagina(
            padraoMovimento: enumQueryParam(widget.padrao),
            grupoMuscularPrimario: enumQueryParam(widget.grupo),
            favoritos: widget.pickerFilter.somenteFavoritos ? true : null,
            hasVideo: widget.pickerFilter.somenteComVideo ? true : null,
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

  @override
  Widget build(BuildContext context) {
    final title =
        widget.padrao != null
            ? TaxonomyLabels.padrao[widget.padrao!] ?? 'Padrão'
            : TaxonomyLabels.grupo[widget.grupo!] ?? 'Grupo';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;

    final sorted = sortExerciciosForPicker(
      _items,
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
    );
    final count = _totalElements > 0 ? _totalElements : sorted.length;

    Widget header() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            subtitle: 'Toque para revisar a prescrição e adicionar ao treino.',
            leading: Icon(
              Icons.fitness_center_outlined,
              color: primary,
              size: 18,
            ),
            trailing: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count exercícios',
                style: FocuxHubTypography.chip(primary),
              ),
            ),
          ),
        ],
      );
    }

    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight: maxHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          const SizedBox(height: 10),
          Expanded(
            child:
                _loading
                    ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FxLoading.sectionShimmer(context, height: 180),
                    )
                    : _error != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.bodyMuted(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () => _fetchPage(reset: true),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                    : sorted.isEmpty
                    ? Center(
                      child: Text(
                        'Nenhum exercício nesta categoria.',
                        style: FocuxHubTypography.bodyMuted(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                    : ListView(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.zero,
                      children: [
                        FxSettingsGroup(
                          accent: primary,
                          children: [
                            for (var i = 0; i < sorted.length; i++)
                              _ExerciseChoiceTile(
                                exercicio: sorted[i],
                                primary: primary,
                                alreadyInTreino: widget.alreadyInTreinoIds
                                    .contains(sorted[i].id),
                                showDivider: i < sorted.length - 1,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context);
                                  widget.onAdicionar(sorted[i]);
                                },
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
        ],
      ),
    );
  }
}

class _ExerciseChoiceTile extends StatelessWidget {
  const _ExerciseChoiceTile({
    required this.exercicio,
    required this.primary,
    required this.onTap,
    this.alreadyInTreino = false,
    this.showDivider = true,
  });

  final Exercicio exercicio;
  final Color primary;
  final VoidCallback onTap;
  final bool alreadyInTreino;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (alreadyInTreino) 'Já está neste treino',
      if (exercicio.grupoMuscularPrimario != null)
        TaxonomyLabels.grupo[exercicio.grupoMuscularPrimario!],
      if (exercicio.equipamentos.isNotEmpty)
        exercicio.equipamentos
            .take(2)
            .map((e) => TaxonomyLabels.equipamento[e])
            .whereType<String>()
            .join(' / '),
    ].whereType<String>().join(' · ');

    return FxSettingsTile(
      icon: Icons.fitness_center_rounded,
      accent: primary,
      label: exercicio.nomeDisplay,
      subtitle: subtitle,
      value: '',
      picker: true,
      showDivider: showDivider,
      onTap: onTap,
      accessory: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canPreviewExerciseMedia(exercicio))
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                showExerciseMediaPreview(context, exercicio: exercicio);
              },
              child: ExerciseMediaThumb.fromExercicio(
                exercicio,
                size: 34,
              ),
            ),
          const SizedBox(width: 6),
          Icon(Icons.add_rounded, color: primary, size: 20),
        ],
      ),
    );
  }
}
