import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';

/// Dia do mês (1 a [maximo]) em grade de 7 colunas: um toque escolhe.
Future<int?> showDiaVencimentoSheet(
  BuildContext context, {
  required String titulo,
  required int selecionado,
  required int maximo,
  DateTime? hoje,
}) {
  return showFxHomeSheet<int>(
    context,
    builder:
        (sheetContext) => FxSheetFrame(
          title: titulo,
          subtitle: 'Toque no dia em que a cobrança vence todo mês.',
          leading: Icon(
            Icons.event_repeat_rounded,
            color: ShellChrome.of(sheetContext).brand,
            size: 20,
          ),
          child: DiaVencimentoGrade(
            selecionado: selecionado,
            maximo: maximo,
            hoje: hoje ?? DateTime.now(),
            onPick: (d) => FxHomeSheetChrome.dismissAndPop(sheetContext, d),
          ),
        ),
  );
}

class DiaVencimentoGrade extends StatelessWidget {
  const DiaVencimentoGrade({
    super.key,
    required this.selecionado,
    required this.maximo,
    required this.onPick,
    required this.hoje,
  });

  final int selecionado;
  final int maximo;
  final DateTime hoje;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var d = 1; d <= maximo; d++)
          Semantics(
            button: true,
            selected: d == selecionado,
            label: 'Dia $d',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onPick(d),
              customBorder: const CircleBorder(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      d == selecionado
                          ? chrome.brand
                          : chrome.line.withValues(alpha: 0.35),
                  border:
                      d == hoje.day && d != selecionado
                          ? Border.all(color: chrome.brand)
                          : null,
                ),
                child: Center(
                  child: Text(
                    '$d',
                    style: FocuxHubTypography.bodyMuted(
                      color: d == selecionado ? Colors.white : chrome.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
