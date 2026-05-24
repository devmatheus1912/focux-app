import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../exercicios/data/enums.dart';
import '../../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../utils/exercise_picker_filter.dart';

class ExercisePickerFilterBar extends StatefulWidget {
  const ExercisePickerFilterBar({
    super.key,
    required this.filter,
    required this.isDark,
    required this.primary,
    required this.onChanged,
  });

  final ExercisePickerFilter filter;
  final bool isDark;
  final Color primary;
  final ValueChanged<ExercisePickerFilter> onChanged;

  @override
  State<ExercisePickerFilterBar> createState() =>
      _ExercisePickerFilterBarState();
}

class _ExercisePickerFilterBarState extends State<ExercisePickerFilterBar> {
  bool _expanded = false;

  static final _espacos = [
    Espaco.academiaCompleta,
    Espaco.academiaBasica,
    Espaco.casaEquipada,
    Espaco.casaSemEquipo,
  ];

  static final _equipamentos = [
    Equipamento.barra,
    Equipamento.halter,
    Equipamento.maquina,
    Equipamento.pesoCorporal,
    Equipamento.polia,
    Equipamento.banda,
  ];

  @override
  void didUpdateWidget(covariant ExercisePickerFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.isActive && !_expanded) {
      _expanded = true;
    }
  }

  int get _activeCount {
    var n = 0;
    if (widget.filter.somenteFavoritos) n++;
    if (widget.filter.somenteComVideo) n++;
    if (widget.filter.espaco != null) n++;
    if (widget.filter.equipamento != null) n++;
    if (widget.filter.filtrarPorAluno) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final mute = widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final showFull = _expanded || widget.filter.isActive;

    if (!showFull) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            if (widget.filter.filtrarPorAluno &&
                widget.filter.equipamentosAluno.isNotEmpty)
              ...[
                _FilterChip(
                  label: 'Do aluno',
                  icon: Icons.person_rounded,
                  selected: true,
                  primary: widget.primary,
                  isDark: widget.isDark,
                  onTap:
                      () => widget.onChanged(
                        widget.filter.copyWith(clearAluno: true),
                      ),
                ),
                const SizedBox(width: 8),
              ],
            _FilterChip(
              label: 'Favoritos',
              icon: Icons.star_rounded,
              selected: widget.filter.somenteFavoritos,
              primary: widget.primary,
              isDark: widget.isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onChanged(
                  widget.filter.copyWith(
                    somenteFavoritos: !widget.filter.somenteFavoritos,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Com vídeo',
              icon: Icons.play_circle_outline_rounded,
              selected: widget.filter.somenteComVideo,
              primary: widget.primary,
              isDark: widget.isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onChanged(
                  widget.filter.copyWith(
                    somenteComVideo: !widget.filter.somenteComVideo,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Filtros',
              icon: Icons.tune_rounded,
              selected: false,
              primary: widget.primary,
              isDark: widget.isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _expanded = true);
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Filtros',
                style: AppTypography.inter(
                  color: mute,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (_activeCount > 0)
              Text(
                '$_activeCount ativo${_activeCount == 1 ? '' : 's'}',
                style: AppTypography.inter(
                  color: widget.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                if (widget.filter.isActive) {
                  widget.onChanged(const ExercisePickerFilter());
                }
                setState(() => _expanded = false);
              },
              child: Text(
                widget.filter.isActive ? 'Limpar' : 'Recolher',
                style: AppTypography.inter(
                  color: mute,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              if (widget.filter.filtrarPorAluno &&
                  widget.filter.equipamentosAluno.isNotEmpty) ...[
                _FilterChip(
                  label: 'Do aluno',
                  icon: Icons.person_rounded,
                  selected: true,
                  primary: widget.primary,
                  isDark: widget.isDark,
                  onTap:
                      () => widget.onChanged(
                        widget.filter.copyWith(clearAluno: true),
                      ),
                ),
                const SizedBox(width: 8),
              ],
              _FilterChip(
                label: 'Favoritos',
                icon: Icons.star_rounded,
                selected: widget.filter.somenteFavoritos,
                primary: widget.primary,
                isDark: widget.isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onChanged(
                    widget.filter.copyWith(
                      somenteFavoritos: !widget.filter.somenteFavoritos,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Com vídeo',
                icon: Icons.play_circle_outline_rounded,
                selected: widget.filter.somenteComVideo,
                primary: widget.primary,
                isDark: widget.isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onChanged(
                    widget.filter.copyWith(
                      somenteComVideo: !widget.filter.somenteComVideo,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              for (final espaco in _espacos) ...[
                _FilterChip(
                  label:
                      TaxonomyLabels.espacoShort[espaco] ??
                      TaxonomyLabels.espaco[espaco] ??
                      espaco.name,
                  selected: widget.filter.espaco == espaco,
                  primary: widget.primary,
                  isDark: widget.isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(
                      widget.filter.espaco == espaco
                          ? widget.filter.copyWith(clearEspaco: true)
                          : widget.filter.copyWith(espaco: espaco),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              for (final equipamento in _equipamentos) ...[
                _FilterChip(
                  label:
                      TaxonomyLabels.equipamento[equipamento] ??
                      equipamento.name,
                  selected: widget.filter.equipamento == equipamento,
                  primary: widget.primary,
                  isDark: widget.isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(
                      widget.filter.equipamento == equipamento
                          ? widget.filter.copyWith(clearEquipamento: true)
                          : widget.filter.copyWith(equipamento: equipamento),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
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
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FilterChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 16),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        labelStyle: AppTypography.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? primary : null,
        ),
        selectedColor: primary.withValues(alpha: isDark ? 0.18 : 0.12),
        backgroundColor: isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
        side: BorderSide(
          color:
              selected
                  ? primary.withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : TokensStrip.borderDefault),
        ),
      ),
    );
  }
}
