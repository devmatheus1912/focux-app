import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/brand_palette.dart';
import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../core/widgets/fx_error_state.dart';
import '../../../../core/widgets/fx_home_sheet.dart';
import '../../../../core/widgets/fx_loading.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../../alunos/widgets/aluno360_inset_empty_actions.dart';
import '../../providers/exercicios_provider.dart';
import '../../data/exercise_enum_api.dart';
import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../data/substituicao_engine.dart';
import 'exercise_media_thumb.dart';
import 'exercise_video_preview_sheet.dart';

class SubstituirExercicioBottomSheet extends ConsumerStatefulWidget {
  const SubstituirExercicioBottomSheet({
    super.key,
    required this.alvo,
    required this.onEscolher,
    this.equipamentosAluno,
    this.onCriarNovo,
  });

  final Exercicio alvo;
  final Set<Equipamento>? equipamentosAluno;
  final ValueChanged<Exercicio> onEscolher;
  final VoidCallback? onCriarNovo;

  @override
  ConsumerState<SubstituirExercicioBottomSheet> createState() =>
      _SubstituirExercicioBottomSheetState();
}

class _SubstituirExercicioBottomSheetState
    extends ConsumerState<SubstituirExercicioBottomSheet> {
  final ScrollController _scrollCtrl = ScrollController();
  final List<Exercicio> _candidatos = [];
  List<AlternativaResultado> _alternativas = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 0;
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

  void _recomputeAlternativas() {
    _alternativas =
        SubstituicaoEngine()
            .encontrarAlternativas(
              alvo: widget.alvo,
              candidatos: _candidatos,
              equipamentosAluno: widget.equipamentosAluno,
            )
            .where((item) => item.exercicio.id != widget.alvo.id)
            .toList();
  }

  Future<void> _fetchPage({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 0;
        _candidatos.clear();
        _alternativas = const [];
      });
    } else {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await ref
          .read(exercicioRepositoryProvider)
          .listarPickerPagina(
            padraoMovimento: enumQueryParam(widget.alvo.padraoMovimento),
            grupoMuscularPrimario: enumQueryParam(widget.alvo.grupoMuscularPrimario),
            page: _page,
            size: 40,
          );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _candidatos
            ..clear()
            ..addAll(result.content.where((ex) => ex.id != widget.alvo.id));
        } else {
          _candidatos.addAll(
            result.content.where((ex) => ex.id != widget.alvo.id),
          );
        }
        _hasNext = result.meta.hasNext;
        _page = result.meta.page + 1;
        _loading = false;
        _loadingMore = false;
        _recomputeAlternativas();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight:
          MediaQuery.sizeOf(context).height *
          FxHomeSheetChrome.expandHeightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Trocar por similar',
            subtitle: 'Substituindo ${widget.alvo.nomeDisplay}',
            leading: Icon(
              Icons.swap_horiz_rounded,
              color: BrandPalette.softened(primary),
              size: FxSettingsLayout.iconSize,
            ),
          ),
          Expanded(
            child:
                _loading
                    ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FxLoading.sectionShimmer(context, height: 180),
                    )
                    : _error != null
                    ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FxErrorState(
                        chromeOnDark: isDark,
                        primary: primary,
                        message: _error!,
                        onRetry: () => _fetchPage(reset: true),
                      ),
                    )
                    : Column(
                      children: [
                        if (_alternativas.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_alternativas.length} opções por padrão de movimento e equipamento',
                                style: FocuxHubTypography.bodyMuted(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child:
                              _alternativas.isEmpty
                                  ? _EmptyState(
                                    onCriarNovo:
                                        widget.onCriarNovo == null
                                            ? null
                                            : () {
                                              Navigator.of(context).pop();
                                              widget.onCriarNovo!();
                                            },
                                  )
                                  : ListView(
                                    controller: _scrollCtrl,
                                    padding: const EdgeInsets.only(bottom: 8),
                                    children: [
                                      FxSettingsGroup(
                                        accent: primary,
                                        children: [
                                          for (
                                            var i = 0;
                                            i < _alternativas.length;
                                            i++
                                          )
                                            _AlternativaTile(
                                              item: _alternativas[i],
                                              primary: primary,
                                              isDark: isDark,
                                              showDivider:
                                                  i < _alternativas.length - 1,
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                Navigator.of(context).pop();
                                                widget.onEscolher(
                                                  _alternativas[i].exercicio,
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                      if (_loadingMore)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Center(
                                            child: FxLoading(size: 22),
                                          ),
                                        ),
                                    ],
                                  ),
                        ),
                        if (_alternativas.isNotEmpty &&
                            widget.onCriarNovo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onCriarNovo!();
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Criar exercício personalizado',
                              ),
                            ),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

class _AlternativaTile extends StatelessWidget {
  const _AlternativaTile({
    required this.item,
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.showDivider = true,
  });

  final AlternativaResultado item;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final exercicio = item.exercicio;
    final meta = _metaParts(exercicio);

    return FxSettingsTile(
      icon: Icons.fitness_center_rounded,
      accent: primary,
      label: exercicio.nomeDisplay,
      subtitle: meta,
      value: '${item.score.clamp(0, 100)}%',
      picker: true,
      showDivider: showDivider,
      onTap: onTap,
      accessory:
          canPreviewExerciseMedia(exercicio)
              ? GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  showExerciseMediaPreview(context, exercicio: exercicio);
                },
                child: ExerciseMediaThumb.fromExercicio(
                  exercicio,
                  size: 34,
                ),
              )
              : null,
    );
  }

  String _metaParts(Exercicio exercicio) {
    final parts = <String>[];
    if (exercicio.padraoMovimento != null) {
      final label = TaxonomyLabels.padrao[exercicio.padraoMovimento!];
      if (label != null) parts.add(label);
    }
    if (exercicio.grupoMuscularPrimario != null) {
      final label = TaxonomyLabels.grupo[exercicio.grupoMuscularPrimario!];
      if (label != null) parts.add(label);
    }
    if (exercicio.equipamentos.isNotEmpty) {
      final label = TaxonomyLabels.equipamento[exercicio.equipamentos.first];
      if (label != null) parts.add(label);
    }
    if (exercicio.dificuldade != null) {
      final label = TaxonomyLabels.dificuldade[exercicio.dificuldade!];
      if (label != null) parts.add(label);
    }
    return parts.take(4).join(' · ');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCriarNovo});

  final VoidCallback? onCriarNovo;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = fxScreenMute(context);
    const caption =
        'Nenhuma alternativa próxima. Ajuste o equipamento do aluno ou cadastre um exercício personalizado.';
    if (onCriarNovo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            caption,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      children: [
        FxSettingsGroup(
          accent: primary,
          caption: caption,
          children: aluno360InsetEmptyActionTiles([
            Aluno360InsetEmptyActionSpec(
              icon: Icons.add_rounded,
              accent: BrandPalette.softened(primary),
              label: 'Criar exercício personalizado',
              subtitle: 'Abre o cadastro e usa no lugar deste',
              highlight: true,
              onTap: onCriarNovo!,
            ),
          ]),
        ),
      ],
    );
  }
}
