part of 'prescription_editor_sheet.dart';

class _RepShortcutChip extends StatelessWidget {
  const _RepShortcutChip({
    required this.label,
    required this.selected,
    required this.brand,
    required this.line,
    required this.mute,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color brand;
  final Color line;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Repetições $label',
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  selected
                      ? brand.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              border: Border.all(
                color:
                    selected
                        ? brand.withValues(alpha: 0.35)
                        : line.withValues(alpha: 0.55),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: FxSettingsLayout.rowValue(color: mute).copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? brand : mute,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionStepperRow extends StatelessWidget {
  const _PrescriptionStepperRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.line,
    required this.ink,
    required this.mute,
    required this.onDecrement,
    required this.onIncrement,
    this.showDivider = true,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color line;
  final Color ink;
  final Color mute;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _PrescriptionRowDivider(
      line: line,
      showDivider: showDivider,
      child: SizedBox(
        height: FxSettingsLayout.rowMinHeight,
        child: Row(
          children: [
            Icon(icon, size: FxSettingsLayout.iconSize, color: iconColor),
            const SizedBox(width: FxSettingsLayout.iconGap),
            Expanded(
              child: Text(label, style: FxSettingsLayout.rowLabel(color: ink)),
            ),
            SizedBox(
              width: _prescriptionTrailingWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    onTap: onDecrement,
                    mute: mute,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: FxSettingsLayout.rowLabel(color: ink).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    onTap: onIncrement,
                    mute: mute,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.mute,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: mute),
        ),
      ),
    );
  }
}

class _PrescriptionValueRow extends StatelessWidget {
  const _PrescriptionValueRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.hint,
    required this.line,
    required this.ink,
    required this.mute,
    this.keyboardType,
    this.showDivider = true,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final String hint;
  final Color line;
  final Color ink;
  final Color mute;
  final TextInputType? keyboardType;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _PrescriptionRowDivider(
      line: line,
      showDivider: showDivider,
      child: SizedBox(
        height: FxSettingsLayout.rowMinHeight,
        child: Row(
          children: [
            Icon(icon, size: FxSettingsLayout.iconSize, color: iconColor),
            const SizedBox(width: FxSettingsLayout.iconGap),
            Expanded(
              child: Text(label, style: FxSettingsLayout.rowLabel(color: ink)),
            ),
            SizedBox(
              width: _prescriptionTrailingWidth,
              child: Semantics(
                label: label,
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  style: FxSettingsLayout.rowValue(color: ink).copyWith(
                    fontSize: TokensStrip.fontBody,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    hintText: hint,
                    hintStyle: FxSettingsLayout.rowValue(color: mute),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionRowDivider extends StatelessWidget {
  const _PrescriptionRowDivider({
    required this.line,
    required this.child,
    this.showDivider = true,
  });

  final Color line;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (showDivider)
          Divider(
            height: 1,
            thickness: FxSettingsLayout.dividerThickness,
            color: line,
          ),
      ],
    );
  }
}

class _PrescriptionExpandRow extends StatelessWidget {
  const _PrescriptionExpandRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.line,
    required this.mute,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color line;
  final Color mute;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _PrescriptionRowDivider(
      line: line,
      showDivider: showDivider,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: FxSettingsLayout.rowMinHeight,
            child: Row(
              children: [
                Icon(icon, size: FxSettingsLayout.iconSize, color: iconColor),
                const SizedBox(width: FxSettingsLayout.iconGap),
                Expanded(
                  child: Text(
                    label,
                    style: FxSettingsLayout.rowLabel(
                      color: fxScreenInk(context),
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.add_rounded, size: 20, color: mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionNotesField extends StatelessWidget {
  const _PrescriptionNotesField({
    required this.controller,
    required this.iconColor,
    required this.ink,
  });

  final TextEditingController controller;
  final Color iconColor;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Semantics(
        label: 'Observações de execução',
        child: TextFormField(
          controller: controller,
          minLines: 2,
          maxLines: 3,
          style: FocuxHubTypography.body(color: ink).copyWith(
            fontWeight: FontWeight.w600,
            height: 1.35,
            fontSize: TokensStrip.fontBody,
          ),
          decoration: FxInputDeco.insetGrouped(
            context,
            icon: Icons.notes_rounded,
            hint: 'Orientações curtas para o aluno',
            iconColor: iconColor,
          ),
        ),
      ),
    );
  }
}

class _RepeatPrescriptionTile extends StatelessWidget {
  const _RepeatPrescriptionTile({
    required this.memory,
    required this.primary,
    required this.brand,
    required this.isDark,
    required this.line,
    required this.onApply,
  });

  final ExercisePrescriptionMemory memory;
  final Color primary;
  final Color brand;
  final bool isDark;
  final Color line;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        border: Border.all(color: line.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Repetir última · ${memory.summary}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onApply,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                'Aplicar',
                style: FocuxHubTypography.body(color: primary).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
