import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../utils/checkin_serie_input.dart';

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
  final String? prescricacaoHint;
  final String? initialFeedback;
  final int? initialRpe;
  final int? rpeAlvo;
  final bool initialDor;

  const CheckinSerieDetailSheet({
    super.key,
    required this.title,
    required this.initialCargaKg,
    required this.initialRepeticoes,
    this.prescricacaoHint,
    required this.initialFeedback,
    required this.initialRpe,
    this.rpeAlvo,
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
  bool _rpeHintLoaded = false;
  bool _showRpeHint = false;

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
    _rpe = widget.initialRpe ?? widget.rpeAlvo ?? 7;
    // RPE fica no Ajustar, desligado por padrão — 1 toque não pede esforço.
    _useRpe = widget.initialRpe != null;
    _dor = widget.initialDor;
    _loadRpeHint();
  }

  Future<void> _loadRpeHint() async {
    final show = await checkinConsumeRpeFirstUseHint();
    if (!mounted) return;
    setState(() {
      _showRpeHint = show;
      _rpeHintLoaded = true;
    });
  }

  String get _rpeHintBody =>
      widget.rpeAlvo == null
          ? checkinRpeSectionHint
          : checkinRpeAlvoHint(widget.rpeAlvo!);

  void _openRpeHelp() {
    showFxHelpSheet(
      context,
      title: checkinRpeSectionTitle,
      subtitle: 'Como marcar o esforço desta série.',
      tips: [FxHelpTip('Esforço sentido', _rpeHintBody, icon: 'dumbbell')],
    );
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

    return FxHomeSheetSurface(
      isDark: dark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: FxKeyboardDismissScope(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FxHomeSheetHandle(isDark: dark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: dark,
                title: widget.title,
                leading: Icon(
                  Icons.fitness_center_rounded,
                  color: brand,
                  size: 18,
                ),
              ),
              const SizedBox(height: 14),
              if (widget.prescricacaoHint != null) ...[
                Text(
                  widget.prescricacaoHint!,
                  style: TextStyle(
                    color: mute,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
              ],
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
                      label: 'Reps feitas',
                      suffix: 'x',
                      icon: Icons.repeat_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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
              'Sensação',
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
                  label: 'Fácil',
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
                  label: 'Difícil',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    checkinRpeSectionTitle,
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (_rpeHintLoaded && !_showRpeHint)
                                  FxHelpIconButton(
                                    tooltip: 'Esforço sentido',
                                    size: 28,
                                    onTap: _openRpeHelp,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _useRpe
                                  ? checkinRpeValueLine(_rpe)
                                  : 'Desligado — opcional',
                              style: TextStyle(
                                color: _useRpe ? brand : mute,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.rpeAlvo != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Alvo ${widget.rpeAlvo}',
                            style: TextStyle(
                              color: brand,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      Switch.adaptive(
                        value: _useRpe,
                        activeTrackColor: brand,
                        onChanged: (value) => setState(() => _useRpe = value),
                      ),
                    ],
                  ),
                  if (_showRpeHint) ...[
                    const SizedBox(height: 4),
                    Text(
                      _rpeHintBody,
                      style: TextStyle(
                        color: mute,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  Slider(
                    value: _rpe.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: brand,
                    secondaryActiveColor: brand.withValues(alpha: 0.28),
                    label: checkinRpeValueLine(_rpe),
                    onChanged:
                        _useRpe
                            ? (value) => setState(() => _rpe = value.round())
                            : null,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 leve',
                        style: TextStyle(color: mute, fontSize: 11),
                      ),
                      Text(
                        '10 no limite',
                        style: TextStyle(color: mute, fontSize: 11),
                      ),
                    ],
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
                'Senti dor nesta série',
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
                label: 'Salvar série',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ),
          ],
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
    FxKeyboardDismissScope.dismiss();
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
      onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
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

/// RPE rápido quando o personal definiu [rpeAlvo] na ficha.
Future<int?> showCheckinRpeAlvoPrompt(
  BuildContext context, {
  required int rpeAlvo,
}) {
  return showFxHomeSheet<int>(
    context,
    builder: (ctx) => _CheckinRpeAlvoPromptSheet(rpeAlvo: rpeAlvo),
  );
}

class _CheckinRpeAlvoPromptSheet extends StatefulWidget {
  const _CheckinRpeAlvoPromptSheet({required this.rpeAlvo});

  final int rpeAlvo;

  @override
  State<_CheckinRpeAlvoPromptSheet> createState() =>
      _CheckinRpeAlvoPromptSheetState();
}

class _CheckinRpeAlvoPromptSheetState extends State<_CheckinRpeAlvoPromptSheet> {
  late int _rpe;

  @override
  void initState() {
    super.initState();
    _rpe = widget.rpeAlvo.clamp(1, 10);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primary = theme.colorScheme.primary;
    final brand = isDark ? BrandPalette.accent(primary) : primary;

    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: checkinRpeSectionTitle,
            subtitle: checkinRpeAlvoHint(widget.rpeAlvo),
            leading: Icon(Icons.speed_rounded, color: brand, size: 18),
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(
            checkinRpeValueLine(_rpe),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: brand,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Slider(
            value: _rpe.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: brand,
            label: checkinRpeValueLine(_rpe),
            onChanged: (v) => setState(() => _rpe = v.round()),
          ),
          const SizedBox(height: TokensStrip.s2),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => FxHomeSheetChrome.dismissAndPop(context, _rpe),
              style: ElevatedButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                ),
              ),
              child: const Text('Registrar série'),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: FocuxHubTypography.bodyMuted(
                color: mute,
                fontWeight: FontWeight.w700,
              ),
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
