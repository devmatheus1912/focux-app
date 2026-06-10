import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

class CheckinSeriePayload {
  final double? cargaKg;
  final String? repeticoes;
  final String? feedback;
  final int? rpe;
  final bool dor;

  const CheckinSeriePayload({
    required this.cargaKg,
    required this.repeticoes,
    required this.feedback,
    required this.rpe,
    required this.dor,
  });
}

class CheckinSerieDetailSheet extends StatefulWidget {
  final String title;
  final double? initialCargaKg;
  final String? initialRepeticoes;
  final String? initialFeedback;
  final int? initialRpe;
  final bool initialDor;

  const CheckinSerieDetailSheet({
    super.key,
    required this.title,
    required this.initialCargaKg,
    required this.initialRepeticoes,
    required this.initialFeedback,
    required this.initialRpe,
    required this.initialDor,
  });

  @override
  State<CheckinSerieDetailSheet> createState() =>
      _CheckinSerieDetailSheetState();
}

class _CheckinSerieDetailSheetState extends State<CheckinSerieDetailSheet> {
  late final TextEditingController _cargaController;
  late final TextEditingController _repsController;
  late String? _feedback;
  late int _rpe;
  late bool _useRpe;
  late bool _dor;

  @override
  void initState() {
    super.initState();
    _cargaController = TextEditingController(
      text: _formatInitialKg(widget.initialCargaKg),
    );
    _repsController = TextEditingController(
      text: widget.initialRepeticoes ?? '',
    );
    _feedback = widget.initialFeedback;
    _rpe = widget.initialRpe ?? 7;
    _useRpe = widget.initialRpe != null;
    _dor = widget.initialDor;
  }

  @override
  void dispose() {
    _cargaController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = theme.colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 16),
        child: ShellSurface(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      icon: Icon(Icons.close_rounded, color: mute),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CheckinSerieField(
                        controller: _cargaController,
                        label: 'Carga',
                        suffix: 'kg',
                        icon: Icons.scale_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        ink: ink,
                        mute: mute,
                        line: line,
                        dark: dark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CheckinSerieField(
                        controller: _repsController,
                        label: 'Reps',
                        suffix: 'x',
                        icon: Icons.repeat_rounded,
                        keyboardType: TextInputType.text,
                        ink: ink,
                        mute: mute,
                        line: line,
                        dark: dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                Text(
                  'Sensacao',
                  style: TextStyle(
                    color: mute,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CheckinFeedbackChip(
                      label: 'Facil',
                      selected: _feedback == 'FACIL',
                      color: brand,
                      onTap: () => _toggleFeedback('FACIL'),
                    ),
                    CheckinFeedbackChip(
                      label: 'Ok',
                      selected: _feedback == 'OK',
                      color: brand,
                      onTap: () => _toggleFeedback('OK'),
                    ),
                    CheckinFeedbackChip(
                      label: 'Dificil',
                      selected: _feedback == 'DIFICIL',
                      color: brand,
                      onTap: () => _toggleFeedback('DIFICIL'),
                    ),
                    CheckinFeedbackChip(
                      label: 'Dor',
                      selected: _feedback == 'DOR',
                      color: EagleTokens.bad,
                      onTap: () => _toggleFeedback('DOR'),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: fxListCardDecoration(context),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'RPE ${_useRpe ? _rpe : "-"}',
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _useRpe,
                            activeTrackColor: brand,
                            onChanged:
                                (value) => setState(() => _useRpe = value),
                          ),
                        ],
                      ),
                      Slider(
                        value: _rpe.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: brand,
                        label: 'RPE $_rpe',
                        onChanged:
                            _useRpe
                                ? (value) =>
                                    setState(() => _rpe = value.round())
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: EagleTokens.bad,
                  value: _dor,
                  onChanged:
                      (value) => setState(() {
                        _dor = value;
                        if (value) {
                          _feedback = 'DOR';
                          _useRpe = true;
                          _rpe = _rpe < 8 ? 8 : _rpe;
                        }
                      }),
                  title: Text(
                    'Senti dor nesta serie',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Marca alerta para o personal acompanhar.',
                    style: TextStyle(color: mute, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FxLiquidPrimaryButton(
                    label: 'Salvar serie',
                    icon: Icons.check_rounded,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFeedback(String value) {
    setState(() {
      _feedback = _feedback == value ? null : value;
      if (_feedback == 'DOR') {
        _dor = true;
        _useRpe = true;
        _rpe = _rpe < 8 ? 8 : _rpe;
      }
    });
  }

  void _submit() {
    Navigator.pop(
      context,
      CheckinSeriePayload(
        cargaKg: _parseKg(_cargaController.text),
        repeticoes: _blankToNull(_repsController.text),
        feedback: _feedback,
        rpe: _useRpe ? _rpe : null,
        dor: _dor,
      ),
    );
  }

  String _formatInitialKg(double? value) {
    if (value == null) return '';
    return value.roundToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  double? _parseKg(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class CheckinSerieField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const CheckinSerieField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.keyboardType,
    this.inputFormatters,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: ink, fontWeight: FontWeight.w900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: mute, fontWeight: FontWeight.w700),
        suffixText: suffix,
        suffixStyle: TextStyle(color: mute, fontWeight: FontWeight.w800),
        prefixIcon: Icon(icon, color: mute, size: 18),
        filled: true,
        fillColor:
            dark
                ? Colors.white.withValues(alpha: 0.05)
                : TokensStrip.borderDefault,
        enabledBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class CheckinTinyMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const CheckinTinyMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: fxListCardDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: mute),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: mute,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckinFeedbackChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const CheckinFeedbackChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.0 : 0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
