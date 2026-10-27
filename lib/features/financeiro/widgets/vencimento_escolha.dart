import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../utils/vencimento_atalhos.dart';

/// Vencimento por atalho ou calendário; data passada é permitida e avisa que
/// a cobrança entra como atrasada. Devolve a data escolhida.
Future<DateTime?> showVencimentoSheet(
  BuildContext context, {
  required DateTime mesReferencia,
  required DateTime atual,
  DateTime? hoje,
}) {
  return showFxHomeSheet<DateTime>(
    context,
    builder:
        (_) => _VencimentoSheet(
          mesReferencia: mesReferencia,
          atual: atual,
          hoje: hoje ?? DateTime.now(),
        ),
  );
}

class _VencimentoSheet extends StatefulWidget {
  const _VencimentoSheet({
    required this.mesReferencia,
    required this.atual,
    required this.hoje,
  });

  final DateTime mesReferencia;
  final DateTime atual;
  final DateTime hoje;

  @override
  State<_VencimentoSheet> createState() => _VencimentoSheetState();
}

class _VencimentoSheetState extends State<_VencimentoSheet> {
  late DateTime _data = DateTime(
    widget.atual.year,
    widget.atual.month,
    widget.atual.day,
  );

  void _concluir(DateTime d) => FxHomeSheetChrome.dismissAndPop(context, d);

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final atalhos = vencimentoAtalhos(
      mesReferencia: widget.mesReferencia,
      hoje: widget.hoje,
    );
    final atraso = vencimentoEntraAtrasado(_data, widget.hoje);
    final primeiro = DateTime(widget.hoje.year - 1, 1, 1);
    final ultimo = DateTime(widget.hoje.year + 2, 12, 31);

    return FxSheetFrame(
      title: 'Vencimento',
      subtitle: 'Escolha um atalho ou o dia no calendário.',
      leading: Icon(Icons.event_rounded, color: chrome.brand, size: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxQuickChips<DateTime>(
            itens: [for (final a in atalhos) a.data],
            selecionado: _data,
            rotuloDe: (d) => atalhos.firstWhere((a) => a.data == d).rotulo,
            onSelecionar: _concluir,
          ),
          const SizedBox(height: 8),
          CalendarDatePicker(
            key: const Key('vencimento-calendario'),
            initialDate: _data,
            firstDate: primeiro,
            lastDate: ultimo,
            onDateChanged: (d) {
              setState(() => _data = d);
              _concluir(d);
            },
          ),
          if (atraso)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                vencimentoAvisoAtraso(_data, widget.hoje),
                style: FocuxHubTypography.bodyMuted(
                  color: EagleTokens.warn,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
