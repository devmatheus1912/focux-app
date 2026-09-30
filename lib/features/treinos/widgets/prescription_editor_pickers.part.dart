part of 'prescription_editor_sheet.dart';

extension on _PrescriptionEditorSheetState {
  Future<void> _openRepsSheet() async {
    if (!widget.enabled) return;
    final draft = TextEditingController(text: widget.repCtrl.text);
    final shortcuts = workoutBuilderRepShortcuts(_presetId);
    final brand = BrandPalette.softened(widget.primary);
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line =
        widget.isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    final applied = await showFxHomeSheet<bool>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: widget.isDark,
          padding: EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            8,
            FxSettingsLayout.pageInset,
            12,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              final current = draft.text.trim();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxHomeSheetHandle(isDark: widget.isDark),
                  const SizedBox(height: 6),
                  FxHomeSheetHeader(
                    isDark: widget.isDark,
                    title: prescriptionRepsLabel,
                    subtitle: prescriptionRepsSubtitle,
                    leading: Icon(
                      Icons.fitness_center_rounded,
                      color: brand,
                      size: FxSettingsLayout.iconSize,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  FxSettingsGroup(
                    accent: widget.primary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextFormField(
                          controller: draft,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setLocal(() {}),
                          onFieldSubmitted: (_) => Navigator.pop(ctx, true),
                          style: FxSettingsLayout.rowLabel(
                            color: fxScreenInk(context),
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            hintText: _selectedPreset.repeticoes,
                            hintStyle: FxSettingsLayout.rowValue(color: mute),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in shortcuts)
                        _RepShortcutChip(
                          label: option,
                          selected: current == option,
                          brand: brand,
                          line: line,
                          mute: mute,
                          onTap: () {
                            draft.text = option;
                            HapticFeedback.selectionClick();
                            setLocal(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(prescriptionAplicar),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (applied == true && mounted) {
      widget.repCtrl.text = draft.text.trim();
      setState(() {});
    }
    draft.dispose();
  }
}
