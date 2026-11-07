import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../utils/financeiro_hub_display.dart';
import '../utils/vencimento_atalhos.dart';

/// Mês e dia do vencimento numa escolha só: o mês da cobrança é o mês do
/// vencimento. Mês que o aluno já tem aparece marcado e não pode ser
/// escolhido ([ocupados]). Devolve a data.
Future<DateTime?> showVencimentoSheet(
  BuildContext context, {
  required DateTime atual,
  Map<String, MesOcupado> ocupados = const {},
  DateTime? hoje,
}) {
  return showFxHomeSheet<DateTime>(
    context,
    builder:
        (_) => _VencimentoSheet(
          atual: atual,
          ocupados: ocupados,
          hoje: hoje ?? DateTime.now(),
        ),
  );
}

class _VencimentoSheet extends StatefulWidget {
  const _VencimentoSheet({
    required this.atual,
    required this.ocupados,
    required this.hoje,
  });

  final DateTime atual;
  final Map<String, MesOcupado> ocupados;
  final DateTime hoje;

  @override
  State<_VencimentoSheet> createState() => _VencimentoSheetState();
}

class _VencimentoSheetState extends State<_VencimentoSheet> {
  late DateTime _data = DateTime(widget.atual.year, widget.atual.month, widget.atual.day);
  var _maisMeses = false;
  var _calendario = false;

  DateTime get _mes => DateTime(_data.year, _data.month, 1);

  List<DateTime> get _meses {
    final base = vencimentoMeses(widget.hoje, anteriores: _maisMeses ? 15 : 3);
    // O mês já escolhido (edição de cobrança antiga) sempre aparece.
    if (!base.any((m) => m.year == _mes.year && m.month == _mes.month)) {
      return [_mes, ...base];
    }
    return base;
  }

  void _escolherMes(DateTime mes) => setState(() {
    _data = vencimentoNoDia(mes, _data.day);
    _calendario = false;
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final atalhos = vencimentoAtalhos(mesReferencia: _mes, hoje: widget.hoje);
    final atraso = vencimentoEntraAtrasado(_data, widget.hoje);
    final atalhoAtual = atalhos.where((a) => a.data == _data).firstOrNull;

    return FxSheetFrame(
      title: 'Vencimento',
      subtitle: 'O mês da cobrança é o mês do vencimento.',
      leading: Icon(FxIcons.calendario, color: chrome.brand, size: 20),
      footer: FxLiquidPrimaryButton(
        label: 'Vence ${dataCurta(_data)}',
        onPressed: () => FxHomeSheetChrome.dismissAndPop(context, _data),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mês', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: TokensStrip.s1),
          for (final mes in _meses)
            _MesLinha(
              mes: mes,
              ocupado: widget.ocupados[vencimentoChaveMes(mes)],
              selecionado: mes.year == _mes.year && mes.month == _mes.month,
              onTap: () => _escolherMes(mes),
            ),
          if (!_maisMeses)
            Align(
              alignment: Alignment.centerLeft,
              child: FxActionLink(
                label: 'Mais meses',
                onTap: () => setState(() => _maisMeses = true),
              ),
            ),
          const SizedBox(height: TokensStrip.s3),
          Text('Dia', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: TokensStrip.s1),
          FxQuickChips<DateTime>(
            itens: [for (final a in atalhos) a.data],
            selecionado: _calendario ? null : atalhoAtual?.data,
            rotuloDe: (d) => atalhos.firstWhere((a) => a.data == d).rotulo,
            onSelecionar: (d) => setState(() {
              _data = d;
              _calendario = false;
            }),
            // Dia fora dos atalhos aparece no próprio chip ("Dia 12").
            outroRotulo: atalhoAtual == null ? 'Dia ${_data.day}' : 'Outro dia',
            outroSelecionado: _calendario || atalhoAtual == null,
            onOutro: () => setState(() => _calendario = true),
          ),
          if (_calendario)
            CalendarDatePicker(
              key: ValueKey('vencimento-calendario-${vencimentoChaveMes(_mes)}'),
              initialDate: _data,
              // Só o mês escolhido: trocar de mês é na lista acima.
              firstDate: _mes,
              lastDate: vencimentoNoDia(_mes, 31),
              onDateChanged: (d) => setState(() => _data = d),
            ),
          if (atraso)
            Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Text(
                vencimentoAvisoAtraso(_data, widget.hoje),
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MesLinha extends StatelessWidget {
  const _MesLinha({
    required this.mes,
    required this.ocupado,
    required this.selecionado,
    required this.onTap,
  });

  final DateTime mes;
  final MesOcupado? ocupado;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final bloqueado = ocupado?.bloqueia ?? false;
    final titulo = financeiroMesTitulo(mes.month, mes.year);
    return Semantics(
      button: !bloqueado,
      selected: selecionado,
      enabled: !bloqueado,
      label: [titulo, if (ocupado != null) ocupado!.rotulo].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: bloqueado ? null : onTap,
        borderRadius: BorderRadius.circular(TokensStrip.s2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s2,
              vertical: TokensStrip.s1,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: FocuxHubTypography.body(
                          color: bloqueado ? chrome.mute : (selecionado ? primary : chrome.ink),
                        ).copyWith(fontWeight: selecionado ? FontWeight.w700 : null),
                      ),
                      if (ocupado != null)
                        Text(ocupado!.rotulo, style: FocuxHubTypography.chip(chrome.mute)),
                    ],
                  ),
                ),
                if (selecionado) Icon(FxIcons.check, color: primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
