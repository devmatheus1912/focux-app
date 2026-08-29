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
    if (filter.equipamento != null) n++;
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
    if (filter.filtrarPorAluno && filter.equipamentosAluno.isNotEmpty) {
      chips.add(
        _FilterChip(
          label: 'Do aluno',
          icon: Icons.person_outline_rounded,
          selected: true,
          primary: primary,
          isDark: isDark,
          onTap: () => onChanged(filter.copyWith(clearAluno: true)),
        ),
      );
    }
    if (filter.espaco != null) {
      chips.add(
        _FilterChip(
          label: _espacoLabel(filter.espaco!),
          selected: true,
          primary: primary,
          isDark: isDark,
          onTap: () => onChanged(filter.copyWith(clearEspaco: true)),
        ),
      );
    }
    if (filter.equipamento != null) {
      chips.add(
        _FilterChip(
          label: _equipamentoLabel(filter.equipamento!),
          selected: true,
          primary: primary,
          isDark: isDark,
          onTap: () => onChanged(filter.copyWith(clearEquipamento: true)),
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
          Row(
            children: [
              Expanded(
                child: _FilterChip(
                  label: 'Favoritos',
                  icon: Icons.star_outline_rounded,
                  selected: filter.somenteFavoritos,
                  primary: primary,
                  isDark: isDark,
                  expanded: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(
                      filter.copyWith(
                        somenteFavoritos: !filter.somenteFavoritos,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterChip(
                  label: 'Com vídeo',
                  icon: Icons.play_circle_outline_rounded,
                  selected: filter.somenteComVideo,
                  primary: primary,
                  isDark: isDark,
                  expanded: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(
                      filter.copyWith(
                        somenteComVideo: !filter.somenteComVideo,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterChip(
                  label:
                      advancedCount > 0
                          ? 'Filtros ($advancedCount)'
                          : 'Filtros',
                  icon: Icons.tune_rounded,
                  selected: advancedCount > 0,
                  primary: primary,
                  isDark: isDark,
                  expanded: true,
                  onTap: () => _openAdvanced(context),
                ),
              ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Semantics(
              label: 'Resultado dos filtros: $caption',
              child: Text(
                caption,
                style: FxSettingsLayout.footer(color: mute),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final bool expanded;

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
            width: expanded ? double.infinity : null,
            constraints: BoxConstraints(
              minHeight: 40,
              minWidth: expanded ? 0 : 0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 8 : 12,
              vertical: 8,
            ),
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
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
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
                    ).copyWith(fontSize: expanded ? 12 : null),
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
