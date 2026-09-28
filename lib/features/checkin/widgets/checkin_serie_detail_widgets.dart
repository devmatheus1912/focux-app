import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_serie_input.dart';
import 'checkin_serie_campos_widgets.dart';

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

/// Série [numero] com carga/reps do stepper; `null` se o aluno fechar.
Future<CheckinSeriePayload?> showCheckinSerieDetalhe(
  BuildContext context, {
  required ExecucaoExercicio ee,
  required int numero,
  required CheckinCurrentSetSeed draft,
}) {
  return showFxHomeSheet<CheckinSeriePayload>(
    context,
    builder:
        (context) => CheckinSerieDetailSheet(
          title: S.of(context).checkinSerieTitulo(numero),
          initialCargaKg: draft.cargaKg ?? ee.cargaKg,
          initialRepeticoes:
              draft.reps?.toString() ??
              checkinSerieRepsSeed(
                serieRepeticoes: null,
                prescricacao: ee.repeticoes,
              ),
          prescricacaoHint: checkinSeriePrescricaoHint(ee.repeticoes),
          initialFeedback: ee.feedback,
          initialRpe: ee.rpe,
          rpeAlvo: ee.rpeAlvo,
          initialDor: ee.dor,
        ),
  );
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
    final s = S.of(context);
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
                  label: s.checkinSensacaoFacil,
                  selected: _feedback == 'FACIL',
                  color: brand,
                  onTap: () => _toggleFeedback('FACIL'),
                ),
                CheckinFeedbackChip(
                  label: s.checkinSensacaoOk,
                  selected: _feedback == 'OK',
                  color: brand,
                  onTap: () => _toggleFeedback('OK'),
                ),
                CheckinFeedbackChip(
                  label: s.checkinSensacaoDificil,
                  selected: _feedback == 'DIFICIL',
                  color: brand,
                  onTap: () => _toggleFeedback('DIFICIL'),
                ),
                CheckinFeedbackChip(
                  label: s.checkinSensacaoDor,
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
        : formatBrDecimal(value);
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
