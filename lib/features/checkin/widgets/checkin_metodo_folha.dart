import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_bottom_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_tonal_button.dart';

typedef PassoDoMetodo = ({String titulo, String apoio, int? pausaS});

/// Quedas do drop-set e mini-séries do rest-pause, uma por vez, sem descanso
/// cheio entre elas. "Pular" encerra os passos; o descanso normal vem depois.
Future<void> mostrarPassosDoMetodo(BuildContext context, List<PassoDoMetodo> passos) {
  if (passos.isEmpty) return Future.value();
  return showFxBottomSheet<void>(
    context: context,
    builder: (_) => _PassosDoMetodo(passos: passos),
  );
}

class _PassosDoMetodo extends StatefulWidget {
  const _PassosDoMetodo({required this.passos});

  final List<PassoDoMetodo> passos;

  @override
  State<_PassosDoMetodo> createState() => _PassosDoMetodoState();
}

class _PassosDoMetodoState extends State<_PassosDoMetodo> {
  var _indice = 0;
  var _restante = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _comecarPasso();
  }

  void _comecarPasso() {
    _timer?.cancel();
    _restante = widget.passos[_indice].pausaS ?? 0;
    if (_restante <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _restante--);
      if (_restante <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _feito() {
    HapticFeedback.selectionClick();
    if (_indice + 1 >= widget.passos.length) {
      Navigator.pop(context);
      return;
    }
    setState(() => _indice++);
    _comecarPasso();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final passo = widget.passos[_indice];
    final pausando = _restante > 0;
    return FxSheetFrame(
      title: passo.titulo,
      subtitle: '${_indice + 1} de ${widget.passos.length}',
      footer: Padding(
        padding: const EdgeInsets.all(TokensStrip.s3),
        child: Row(
          children: [
            FxTonalButton(
              label: 'Pular',
              compact: true,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: FxLiquidPrimaryButton(
                label: pausando ? 'Pausa · $_restante s' : 'Feito',
                onPressed: pausando ? null : _feito,
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
        child: Text(
          pausando ? 'Respire. A mini-série começa quando a pausa acabar.' : passo.apoio,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
      ),
    );
  }
}
