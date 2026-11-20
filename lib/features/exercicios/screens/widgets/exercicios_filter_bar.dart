import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/theme/shell_chrome.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_input_deco.dart';
import '../../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../treinos/screens/widgets/exercise_picker_chip.dart';
import '../../../treinos/widgets/exercise_group_chips.dart';
import '../../data/enums.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../models/exercicios_ui_filter.dart';
import '../../utils/exercicios_filter_display.dart';
import '../../../../core/theme/fx_icons.dart';

export '../../models/exercicios_ui_filter.dart';

/// Busca e, abaixo, a mesma fileira de chips do "Adicionar exercício":
/// grupos musculares, "Equipamento" e "Limpar" quando há filtro (20/11).
class ExerciciosFilterBar extends StatefulWidget {
  const ExerciciosFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.onClear,
  });

  final ExerciciosUiFilter filter;
  final ValueChanged<ExerciciosUiFilter> onChanged;
  final VoidCallback onClear;

  @override
  State<ExerciciosFilterBar> createState() => _ExerciciosFilterBarState();
}

class _ExerciciosFilterBarState extends State<ExerciciosFilterBar> {
  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.filter.query);
    _ctrl.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(covariant ExerciciosFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.query != oldWidget.filter.query &&
        _ctrl.text != widget.filter.query) {
      _ctrl.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onQueryChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: exerciciosFilterDebounceMs),
      () {
        if (!mounted) return;
        if (_ctrl.text == widget.filter.query) return;
        widget.onChanged(widget.filter.copyWith(query: _ctrl.text));
      },
    );
  }

  void _toggleGrupo(GrupoMuscular grupo) {
    widget.onChanged(
      widget.filter.grupo == grupo
          ? widget.filter.copyWith(clearGrupo: true)
          : widget.filter.copyWith(grupo: grupo),
    );
  }

  Future<void> _escolherEquipamento() async {
    HapticFeedback.selectionClick();
    final atual = widget.filter.equipamento;
    final escolhido = await showFxInsetPickerSheet<_Equip>(
      context,
      title: exerciciosEquipamentoTitulo,
      headerIcon: FxIcons.treino,
      selected: _Equip(atual),
      items: [
        FxInsetPickerSheetItem(
          value: const _Equip(null),
          label: exerciciosEquipamentoTodos(),
        ),
        for (final e in Equipamento.values)
          if (TaxonomyLabels.equipamento[e] != null)
            FxInsetPickerSheetItem(
              value: _Equip(e),
              label: TaxonomyLabels.equipamento[e]!,
            ),
      ],
    );
    if (escolhido == null || !mounted) return;
    widget.onChanged(
      escolhido.valor == null
          ? widget.filter.copyWith(clearEquipamento: true)
          : widget.filter.copyWith(equipamento: escolhido.valor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;
    final equip = widget.filter.equipamento;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: exerciciosSearchHint(),
              hintStyle: TextStyle(
                color: mute,
                fontSize: TokensStrip.fontBodySm,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(FxIcons.buscar, size: 18, color: mute),
              ),
              filled: true,
              fillColor: chrome.cardFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: chrome.line),
              ),
              enabledBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: chrome.line),
              ),
              focusedBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primary, width: 1.6),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
          ExerciseGroupChips(
            selecionados:
                widget.filter.grupo == null ? const {} : {widget.filter.grupo!},
            noTreino: const {},
            onToggle: _toggleGrupo,
            primary: primary,
            isDark: chrome.isDark,
            antes: [
              if (widget.filter.hasActive)
                ExercisePickerChip(
                  label: exerciciosLimparFiltros(),
                  icon: FxIcons.fechar,
                  selected: false,
                  primary: primary,
                  isDark: chrome.isDark,
                  onTap: () {
                    _debounce?.cancel();
                    _ctrl.clear();
                    widget.onClear();
                  },
                ),
            ],
            extras: [
              ExercisePickerChip(
                label:
                    equip == null
                        ? exerciciosEquipamentoTitulo
                        : TaxonomyLabels.equipamento[equip] ?? equip.name,
                selected: equip != null,
                primary: primary,
                isDark: chrome.isDark,
                onTap: _escolherEquipamento,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opção da folha de equipamento: nulo = qualquer um.
class _Equip {
  const _Equip(this.valor);
  final Equipamento? valor;

  @override
  bool operator ==(Object other) => other is _Equip && other.valor == valor;

  @override
  int get hashCode => valor.hashCode;
}
