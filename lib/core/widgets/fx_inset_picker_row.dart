import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import 'fx_input_deco.dart';
import 'fx_shell_scaffold.dart';

/// Picker inset dentro de [FxSettingsGroup] — paridade pixel-perfect com
/// [AlunoInsetFormField] via [FxInputDeco.insetGrouped].
class FxInsetPickerRow extends StatefulWidget {
  const FxInsetPickerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor,
    this.showDivider = true,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showDivider;
  final String? semanticsLabel;

  @override
  State<FxInsetPickerRow> createState() => _FxInsetPickerRowState();
}

class _FxInsetPickerRowState extends State<FxInsetPickerRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant FxInsetPickerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    final soft = widget.iconColor ?? BrandPalette.softened(primary);
    final ink = fxScreenInk(context);
    final spoken = widget.semanticsLabel ?? '${widget.label}. ${widget.value}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: spoken,
          child: TextFormField(
            readOnly: true,
            showCursor: false,
            enableInteractiveSelection: false,
            controller: _controller,
            onTap: () {
              HapticFeedback.selectionClick();
              FocusScope.of(context).unfocus();
              widget.onTap();
            },
            style: FxSettingsLayout.rowLabel(color: ink),
            decoration: FxInputDeco.insetGrouped(
              context,
              icon: widget.icon,
              hint: widget.label,
              iconColor: soft,
              suffix: Icon(
                Icons.unfold_more,
                size: FxSettingsLayout.chevronSize,
                color: mute,
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Divider(
            height: 1,
            thickness: FxSettingsLayout.dividerThickness,
            color: chrome.line,
          ),
      ],
    );
  }
}
