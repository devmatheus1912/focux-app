import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../../alunos/widgets/aluno_inset_form_field.dart';
import '../../models/exercicios_ui_filter.dart';
import '../../utils/exercicios_filter_display.dart';
import 'exercicios_filter_sheet.dart';

export '../../models/exercicios_ui_filter.dart';

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

  Future<void> _openFilters() async {
    HapticFeedback.selectionClick();
    await showExerciciosLibraryFiltersSheet(
      context,
      filter: widget.filter,
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        FxSettingsLayout.groupGap,
      ),
      child: Column(
        children: [
          FxSettingsGroup(
            children: [
              AlunoInsetFormField(
                controller: _ctrl,
                label: exerciciosSearchLabel(),
                hint: exerciciosSearchHint(),
                icon: Icons.search,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          FxSettingsGroup(
            children: [
              FxSettingsTile(
                fxIcon: 'target',
                label: exerciciosFiltrosHeader(),
                value: exerciciosFilterSummary(widget.filter),
                highlight: widget.filter.hasFacet,
                showDivider: widget.filter.hasActive,
                onTap: _openFilters,
              ),
              if (widget.filter.hasActive)
                FxSettingsTile(
                  fxIcon: 'x',
                  label: exerciciosLimparFiltros(),
                  value: '',
                  showDivider: false,
                  onTap: () {
                    _debounce?.cancel();
                    _ctrl.clear();
                    widget.onClear();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
