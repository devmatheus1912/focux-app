import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/focux_hub_typography.dart';
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

  int get _activeCount {
    var n = 0;
    if (widget.filter.somenteFavoritos) n++;
    if (widget.filter.somenteComVideo) n++;
    if (widget.filter.espaco != null) n++;
    if (widget.filter.equipamento != null) n++;
    if (widget.filter.filtrarPorAluno) n++;
    return n;
  }

  int get _advancedActiveCount {
    var n = 0;
    if (widget.filter.espaco != null) n++;
    if (widget.filter.equipamento != null) n++;
    if (widget.filter.filtrarPorAluno) n++;
    return n;
  }

  String _espacoLabel(Espaco espaco) {
    return TaxonomyLabels.espacoShort[espaco] ??
        TaxonomyLabels.espaco[espaco] ??
        espaco.name;
  }

  String _equipamentoLabel(Equipamento equipamento) {
    return TaxonomyLabels.equipamento[equipamento] ?? equipamento.name;
  }

  @override
  Widget build(BuildContext context) {
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final showFull = _expanded;

    if (!showFull) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 12),
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
            if (widget.filter.espaco != null) ...[
              _FilterChip(
                label: _espacoLabel(widget.filter.espaco!),
                selected: true,
                primary: widget.primary,
                isDark: widget.isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onChanged(widget.filter.copyWith(clearEspaco: true));
                },
              ),
              const SizedBox(width: 8),
            ],
            if (widget.filter.equipamento != null) ...[
              _FilterChip(
                label: _equipamentoLabel(widget.filter.equipamento!),
                selected: true,
                primary: widget.primary,
                isDark: widget.isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onChanged(
                    widget.filter.copyWith(clearEquipamento: true),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            _FilterChip(
              label:
                  _advancedActiveCount > 0
                      ? 'Filtros ($_advancedActiveCount)'
                      : 'Filtros',
              icon: Icons.tune_rounded,
              selected: _advancedActiveCount > 0,
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
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w800,
                ).copyWith(letterSpacing: 0.4),
              ),
            ),
            if (_activeCount > 0)
              Text(
                '$_activeCount ativo${_activeCount == 1 ? '' : 's'}',
                style: FocuxHubTypography.bodyMuted(
                  color: widget.primary,
                  fontWeight: FontWeight.w900,
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
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Espaço',
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w800,
            ).copyWith(letterSpacing: 0.35),
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Text(
            'Equipamento',
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w800,
            ).copyWith(letterSpacing: 0.35),
          ),
        ),
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, ativo' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  selected
                      ? primary
                      : (isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    selected
                        ? primary
                        : primary.withValues(alpha: isDark ? 0.28 : 0.32),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: FocuxHubTypography.chip(
                    selected ? Colors.white : ink,
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
