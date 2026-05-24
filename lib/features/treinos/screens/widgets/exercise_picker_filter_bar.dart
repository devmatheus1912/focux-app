import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../exercicios/data/enums.dart';
import '../../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../utils/exercise_picker_filter.dart';

class ExercisePickerFilterBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (filter.filtrarPorAluno && filter.equipamentosAluno.isNotEmpty)
                _FilterChip(
                  label: 'Do aluno',
                  icon: Icons.person_rounded,
                  selected: true,
                  primary: primary,
                  isDark: isDark,
                  onTap:
                      () => onChanged(filter.copyWith(clearAluno: true)),
                ),
              if (filter.filtrarPorAluno && filter.equipamentosAluno.isNotEmpty)
                const SizedBox(width: 8),
              _FilterChip(
                label: 'Favoritos',
                icon: Icons.star_rounded,
                selected: filter.somenteFavoritos,
                primary: primary,
                isDark: isDark,
                onTap:
                    () => onChanged(
                      filter.copyWith(
                        somenteFavoritos: !filter.somenteFavoritos,
                      ),
                    ),
              ),
              const SizedBox(width: 8),
              for (final espaco in _espacos) ...[
                _FilterChip(
                  label: TaxonomyLabels.espaco[espaco] ?? espaco.name,
                  selected: filter.espaco == espaco,
                  primary: primary,
                  isDark: isDark,
                  onTap:
                      () => onChanged(
                        filter.espaco == espaco
                            ? filter.copyWith(clearEspaco: true)
                            : filter.copyWith(espaco: espaco),
                      ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final equipamento in _equipamentos) ...[
                _FilterChip(
                  label:
                      TaxonomyLabels.equipamento[equipamento] ?? equipamento.name,
                  selected: filter.equipamento == equipamento,
                  primary: primary,
                  isDark: isDark,
                  onTap:
                      () => onChanged(
                        filter.equipamento == equipamento
                            ? filter.copyWith(clearEquipamento: true)
                            : filter.copyWith(equipamento: equipamento),
                      ),
                ),
                const SizedBox(width: 8),
              ],
              if (filter.isActive)
                TextButton.icon(
                  onPressed: () => onChanged(const ExercisePickerFilter()),
                  icon: Icon(Icons.filter_alt_off_rounded, color: mute, size: 16),
                  label: Text(
                    'Limpar',
                    style: AppTypography.inter(
                      color: mute,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
    return FilterChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 16),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
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
    );
  }
}
