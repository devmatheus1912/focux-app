import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
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
          prescricacaoHint: checkinSeriePrescricaoHint(
            S.of(context),
            ee.repeticoes,
          ),
          initialFeedback: ee.feedback,
          initialRpe: ee.rpe,
          rpeAlvo: ee.rpeAlvo,
          initialDor: ee.dor,
        ),
  );
}

class _CheckinSerieDetailSheetState extends State<CheckinSerieDetailSheet> {
  late String? _feedback;
  late int _rpe;
  late bool _useRpe;
  late bool _dor;
  bool _rpeHintLoaded = false;
  bool _showRpeHint = false;

  @override
  void initState() {
    super.initState();
    _dor = widget.initialDor;
    _feedback = widget.initialFeedback ?? (_dor ? 'DOR' : null);
    _rpe = widget.initialRpe ?? widget.rpeAlvo ?? 7;
    // O esforço é um detalhe opcional: a régua só aparece quando o aluno pede.
    _useRpe = widget.initialRpe != null;
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

  String _rpeHintBody(S s) =>
      widget.rpeAlvo == null
          ? s.checkinRpeHint
          : checkinRpeAlvoHint(s, widget.rpeAlvo!);

  void _openRpeHelp() {
    final s = S.of(context);
    showFxHelpSheet(
      context,
      title: s.checkinRpeTitulo,
      subtitle: s.checkinRpeAjudaSub,
      tips: [
        FxHelpTip(s.checkinRpeEsforco, _rpeHintBody(s), icon: 'dumbbell'),
      ],
    );
  }

  /// "40 kg × 10": o que está na tela de execução, só para conferir.
  String? _resumo() {
    final carga = widget.initialCargaKg;
    final reps = widget.initialRepeticoes?.trim();
    final partes = [
      if (carga != null) '${_formatInitialKg(carga)} kg',
      if (reps != null && reps.isNotEmpty) '$reps reps',
    ];
    return partes.isEmpty ? null : partes.join(' × ');
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
    final resumo = _resumo();
    final dica = widget.prescricacaoHint;

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
              if (resumo != null || dica != null) ...[
                const SizedBox(height: TokensStrip.s2),
                Text(
                  [if (resumo != null) resumo, if (dica != null) dica].join(' · '),
                  style: TextStyle(
                    color: mute,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: TokensStrip.s4),
              Text(
                s.checkinComoFoi,
                style: TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: TokensStrip.s2),
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
              if (_useRpe)
                _cartaoEsforco(s, brand: brand, ink: ink, mute: mute)
              else
                FxTonalButton(
                  label: s.checkinDetalharEsforco,
                  icon: Icons.speed_rounded,
                  onPressed: () => setState(() => _useRpe = true),
                ),
              const SizedBox(height: TokensStrip.s4),
              SizedBox(
                width: double.infinity,
                child: FxLiquidPrimaryButton(
                  label: s.checkinSalvarSerie,
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

  Widget _cartaoEsforco(
    S s, {
    required Color brand,
    required Color ink,
    required Color mute,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
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
                            s.checkinRpeTitulo,
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (_rpeHintLoaded && !_showRpeHint)
                          FxHelpIconButton(
                            tooltip: s.checkinRpeEsforco,
                            size: 28,
                            onTap: _openRpeHelp,
                          ),
                      ],
                    ),
                    Text(
                      checkinRpeValueLine(s, _rpe),
                      style: TextStyle(
                        color: brand,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.rpeAlvo != null)
                Text(
                  s.checkinRpeAlvo(widget.rpeAlvo!),
                  style: TextStyle(
                    color: brand,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              IconButton(
                tooltip: s.checkinRemoverEsforco,
                onPressed: () => setState(() => _useRpe = false),
                icon: Icon(Icons.close_rounded, color: mute),
              ),
            ],
          ),
          if (_showRpeHint)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _rpeHintBody(s),
                style: TextStyle(color: mute, fontSize: 12, height: 1.35),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Slider(
              value: _rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: brand,
              label: checkinRpeValueLine(s, _rpe),
              onChanged: (value) => setState(() => _rpe = value.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.checkinRpeEscalaMin,
                  style: TextStyle(color: mute, fontSize: 11),
                ),
                Text(
                  s.checkinRpeEscalaMax,
                  style: TextStyle(color: mute, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFeedback(String value) {
    setState(() {
      _feedback = _feedback == value ? null : value;
      _dor = _feedback == 'DOR';
      if (_dor) {
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
        cargaKg: widget.initialCargaKg,
        repeticoes: _blankToNull(widget.initialRepeticoes ?? ''),
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

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
