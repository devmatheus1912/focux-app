import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';
import 'fx_input_deco.dart';
import 'fx_motion.dart';
import 'fx_tonal_button.dart';

/// Atalho da folha: um chip que preenche o campo com [valor].
typedef FxNumberPadAtalho = ({String label, double valor});

/// Resposta da folha: um número digitado, ou o toque na alternativa
/// ("Sem carga"), quando a folha oferece uma.
class FxNumberPadResultado {
  const FxNumberPadResultado.valor(double this.valor) : alternativa = false;
  const FxNumberPadResultado.alternativa() : valor = null, alternativa = true;

  final double? valor;
  final bool alternativa;
}

/// Pede um número com teclado numérico, no lugar de um diálogo. Devolve nulo
/// quando a folha é fechada sem confirmar.
Future<FxNumberPadResultado?> showFxNumberPadSheet(
  BuildContext context, {
  required String titulo,
  required String confirmarLabel,
  String? subtitulo,
  String? sufixo,
  double? inicial,
  bool decimal = true,
  double maximo = 999,
  List<FxNumberPadAtalho> atalhos = const [],
  String? alternativaLabel,
}) {
  return showFxHomeSheet<FxNumberPadResultado>(
    context,
    builder:
        (ctx) => _FxNumberPadSheet(
          titulo: titulo,
          subtitulo: subtitulo,
          confirmarLabel: confirmarLabel,
          sufixo: sufixo,
          inicial: inicial,
          decimal: decimal,
          maximo: maximo,
          atalhos: atalhos,
          alternativaLabel: alternativaLabel,
        ),
  );
}

/// Texto do campo: vírgula decimal, sem ".0" quando o número é inteiro.
String fxNumberPadTexto(double? v) {
  if (v == null) return '';
  if (v.roundToDouble() == v) return v.toStringAsFixed(0);
  return v.toString().replaceAll('.', ',');
}

/// Lê o que foi digitado (vírgula ou ponto); nulo se vazio ou inválido.
double? fxNumberPadLer(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

class _FxNumberPadSheet extends StatefulWidget {
  const _FxNumberPadSheet({
    required this.titulo,
    required this.confirmarLabel,
    required this.decimal,
    required this.maximo,
    required this.atalhos,
    this.subtitulo,
    this.sufixo,
    this.inicial,
    this.alternativaLabel,
  });

  final String titulo;
  final String? subtitulo;
  final String confirmarLabel;
  final String? sufixo;
  final double? inicial;
  final bool decimal;
  final double maximo;
  final List<FxNumberPadAtalho> atalhos;
  final String? alternativaLabel;

  @override
  State<_FxNumberPadSheet> createState() => _FxNumberPadSheetState();
}

class _FxNumberPadSheetState extends State<_FxNumberPadSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: fxNumberPadTexto(widget.inicial),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    _ctrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _ctrl.text.length,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _valor {
    final v = fxNumberPadLer(_ctrl.text);
    if (v == null || v < 0 || v > widget.maximo) return null;
    return v;
  }

  void _confirmar() {
    final v = _valor;
    if (v == null) return;
    FxHomeSheetChrome.dismissAndPop(context, FxNumberPadResultado.valor(v));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.of(context);
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            const SizedBox(height: TokensStrip.s3),
            FxHomeSheetHeader(
              isDark: isDark,
              title: widget.titulo,
              subtitle: widget.subtitulo,
            ),
            const SizedBox(height: TokensStrip.s3),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(
                decimal: widget.decimal,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(widget.decimal ? r'[\d.,]' : r'\d'),
                ),
              ],
              onSubmitted: (_) => _confirmar(),
              style: FocuxHubTypography.metric(
                color: chrome.ink,
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
              decoration: FxInputDeco.build(
                context,
                widget.sufixo ?? widget.titulo,
                suffix:
                    widget.sufixo == null
                        ? null
                        : Text(
                          widget.sufixo!,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                          ),
                        ),
              ),
            ),
            if (widget.atalhos.isNotEmpty) ...[
              const SizedBox(height: TokensStrip.s3),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final a in widget.atalhos)
                    FxTonalButton(
                      label: a.label,
                      compact: true,
                      onPressed: () => _ctrl.text = fxNumberPadTexto(a.valor),
                    ),
                ],
              ),
            ],
            const SizedBox(height: TokensStrip.s4),
            FxLiquidPrimaryButton(
              label: widget.confirmarLabel,
              onPressed: _valor == null ? null : _confirmar,
            ),
            if (widget.alternativaLabel != null) ...[
              const SizedBox(height: TokensStrip.s2),
              FxTonalButton(
                label: widget.alternativaLabel!,
                expanded: true,
                onPressed:
                    () => FxHomeSheetChrome.dismissAndPop(
                      context,
                      const FxNumberPadResultado.alternativa(),
                    ),
              ),
            ],
            const SizedBox(height: TokensStrip.s2),
          ],
        ),
      ),
    );
  }
}
