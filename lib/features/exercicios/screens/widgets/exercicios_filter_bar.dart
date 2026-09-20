import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/fx_settings_layout.dart';
import '../../../../core/theme/shell_chrome.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_icon.dart';
import '../../../../core/widgets/fx_input_deco.dart';
import '../../../../core/widgets/fx_toggle_chip.dart';
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
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
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
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: FxIcon(name: 'search', size: 18, color: mute),
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
          const SizedBox(height: TokensStrip.s2),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              FxToggleChip(
                label: exerciciosFiltrosHeader(),
                selected: widget.filter.hasFacet,
                isDark: chrome.isDark,
                onTap: _openFilters,
              ),
              if (widget.filter.hasActive)
                FxToggleChip(
                  label: exerciciosLimparFiltros(),
                  selected: false,
                  isDark: chrome.isDark,
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
