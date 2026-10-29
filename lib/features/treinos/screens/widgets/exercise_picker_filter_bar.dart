import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../exercicios/data/enums.dart';
import '../../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../utils/exercise_picker_filter.dart';
import '../../utils/exercise_picker_library_label.dart';
import '../../widgets/exercise_picker_filter_sheet.dart';

class ExercisePickerFilterBar extends StatelessWidget {
  const ExercisePickerFilterBar({
    super.key,
    required this.filter,
    required this.isDark,
    required this.primary,
    required this.onChanged,
    this.resultCaption,
  });

  final ExercisePickerFilter filter;
  final bool isDark;
  final Color primary;
  final ValueChanged<ExercisePickerFilter> onChanged;
  final ExercisePickerLibraryLines? resultCaption;

  int get _advancedActiveCount {
    var n = 0;
    if (filter.espaco != null) n++;
    n += filter.equipamentos.length;
    return n;
  }

  String _espacoLabel(Espaco espaco) =>
      TaxonomyLabels.espacoShort[espaco] ??
      TaxonomyLabels.espaco[espaco] ??
      espaco.name;

  String _equipamentoLabel(Equipamento equipamento) =>
      TaxonomyLabels.equipamento[equipamento] ?? equipamento.name;

  String? get _resultCaptionText {
    final lines = resultCaption;
    if (lines == null) return null;
    if (lines.secondary == null) return lines.primary;
    return '${lines.primary} · ${lines.secondary}';
  }

  void _openAdvanced(BuildContext context) {
    HapticFeedback.selectionClick();
    showExercisePickerFilterSheet(
      context,
      filter: filter,
      onChanged: onChanged,
    );
  }

  List<Widget> _activeFilterChips() {
    final chips = <Widget>[];
    if (filter.espaco != null) {
      chips.add(
        ExercisePickerChip(
          label: _espacoLabel(filter.espaco!),
          selected: true,
          primary: primary,
          isDark: isDark,
          onTap: () => onChanged(filter.copyWith(clearEspaco: true)),
        ),
      );
    }
    for (final equipamento in filter.equipamentos) {
      chips.add(
        ExercisePickerChip(
          label: _equipamentoLabel(equipamento),
          selected: true,
          primary: primary,
          isDark: isDark,
          onTap:
              () => onChanged(
                filter.copyWith(
                  equipamentos: {...filter.equipamentos}..remove(equipamento),
                ),
              ),
        ),
      );
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final caption = _resultCaptionText;
    final advancedCount = _advancedActiveCount;
    final activeChips = _activeFilterChips();

    return Semantics(
      container: true,
      label: 'Filtros rápidos da biblioteca',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeChips.isNotEmpty) ...[
            ClipRect(
              clipBehavior: Clip.none,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (var i = 0; i < activeChips.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      activeChips[i],
                    ],
                  ],
                ),
              ),
            ),
          ],
          ClipRect(
            clipBehavior: Clip.none,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  ExercisePickerChip(
                    label:
                        advancedCount > 0
                            ? 'Filtros ($advancedCount)'
                            : 'Filtros',
                    icon: Icons.tune_rounded,
                    selected: advancedCount > 0,
                    primary: primary,
                    isDark: isDark,
                    onTap: () => _openAdvanced(context),
                  ),
                  const SizedBox(width: 8),
                  ExercisePickerChip(
                    label: 'Favoritos',
                    icon:
                        filter.somenteFavoritos
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                    selected: filter.somenteFavoritos,
                    primary: primary,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(
                        filter.copyWith(
                          somenteFavoritos: !filter.somenteFavoritos,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ExercisePickerChip(
                    label: 'Com vídeo',
                    icon: Icons.play_circle_outline_rounded,
                    selected: filter.somenteComVideo,
                    primary: primary,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(
                        filter.copyWith(
                          somenteComVideo: !filter.somenteComVideo,
                        ),
                      );
                    },
                  ),
                  if (filter.equipamentosAluno.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ExercisePickerChip(
                      label: 'Equipamento do aluno',
                      icon: Icons.person_outline_rounded,
                      selected: filter.filtrarPorAluno,
                      primary: primary,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(
                          filter.copyWith(
                            filtrarPorAluno: !filter.filtrarPorAluno,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Semantics(
              label: 'Resultado dos filtros: $caption',
              child: Text(caption, style: FxSettingsLayout.footer(color: mute)),
            ),
          ],
        ],
      ),
    );
  }
}

class ExercisePickerChip extends StatelessWidget {
  const ExercisePickerChip({
    super.key,
    required this.label,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Semantics(
      button: true,
      toggled: selected,
      label: selected ? '$label, filtro ativo' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: 44),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  selected
                      ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
                      : (isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg),
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              border: Border.all(
                color: selected ? primary : line.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? primary : ink.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.bodyMuted(
                      color: selected ? primary : ink,
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
