import 'package:flutter/material.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/ficha_vigencia.dart';

/// Texto e tom do selo da vigência: "Até 30/11", "Vence em 7 dias", "Vencida há 3 dias".
({String texto, FxPillTone tom}) rotuloDaVigencia(
  S s,
  VigenciaFicha vigencia,
  DateTime hoje,
) {
  final dias = vigencia.diasRestantes(hoje) ?? 0;
  return switch (vigencia.estado(hoje)) {
    EstadoVigencia.semPrazo => (texto: s.vigenciaSemPrazo, tom: FxPillTone.neutral),
    EstadoVigencia.emDia => (
      texto: s.vigenciaAte(dataCurta(vigencia.fim!)),
      tom: FxPillTone.accent,
    ),
    EstadoVigencia.venceEmBreve => (
      texto: s.vigenciaVenceEmDias(dias),
      tom: FxPillTone.warning,
    ),
    EstadoVigencia.venceHoje => (texto: s.vigenciaVenceHoje, tom: FxPillTone.warning),
    EstadoVigencia.vencida => (
      texto: s.vigenciaVencidaHa(-dias),
      tom: FxPillTone.danger,
    ),
  };
}

enum AcaoDaVigencia { renovar4, renovar8, renovar12, escolherData, semPrazo }

/// Linha "Vigência" da ficha: o selo de estado e, ao tocar, o menu de renovar.
class FichaVigenciaLinha extends StatelessWidget {
  const FichaVigenciaLinha({
    super.key,
    required this.vigencia,
    required this.hoje,
    required this.ocupado,
    required this.onAcao,
  });

  final VigenciaFicha vigencia;
  final DateTime hoje;
  final bool ocupado;
  final ValueChanged<AcaoDaVigencia> onAcao;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final rotulo = rotuloDaVigencia(s, vigencia, hoje);
    return FxTapRow(
      title: s.vigenciaTitulo,
      semanticsLabel: '${s.vigenciaTitulo}, ${rotulo.texto}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxStatusPill(label: rotulo.texto, tone: rotulo.tom),
          Icon(Icons.chevron_right_rounded, color: chrome.mute),
        ],
      ),
      onTap: ocupado
          ? null
          : () async {
              final acao = await mostrarMenuDaVigencia(context);
              if (acao != null) onAcao(acao);
            },
    );
  }
}

Future<AcaoDaVigencia?> mostrarMenuDaVigencia(BuildContext context) {
  final s = S.of(context);
  return showFxActionSheet<AcaoDaVigencia>(
    context,
    title: s.vigenciaMenuTitulo,
    itens: [
      FxActionSheetItem(
        value: AcaoDaVigencia.renovar4,
        label: s.vigenciaRenovarSemanas(4),
        icon: Icons.event_repeat_rounded,
      ),
      FxActionSheetItem(
        value: AcaoDaVigencia.renovar8,
        label: s.vigenciaRenovarSemanas(8),
        icon: Icons.event_repeat_rounded,
      ),
      FxActionSheetItem(
        value: AcaoDaVigencia.renovar12,
        label: s.vigenciaRenovarSemanas(12),
        icon: Icons.event_repeat_rounded,
      ),
      FxActionSheetItem(
        value: AcaoDaVigencia.escolherData,
        label: s.vigenciaEscolherData,
        icon: Icons.calendar_month_rounded,
      ),
      FxActionSheetItem(
        value: AcaoDaVigencia.semPrazo,
        label: s.vigenciaSemPrazo,
        icon: Icons.all_inclusive_rounded,
        destructive: true,
      ),
    ],
  );
}
