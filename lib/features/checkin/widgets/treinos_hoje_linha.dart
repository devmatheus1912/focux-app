import 'package:flutter/material.dart';

import '../../../core/widgets/fx_action_row.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/treinos_hub_texts.dart';
import '../utils/treinos_hub_view.dart';

/// A linha do treino de hoje na aba Treinos: nome, estado e um verbo.
/// Substitui o card grande, que repetia o foco da Hoje.
class TreinosHojeLinha extends StatelessWidget {
  const TreinosHojeLinha({
    super.key,
    required this.destaque,
    required this.hoje,
    required this.onAction,
    this.onOpen,
    this.proximoNome,
    this.ordem,
    this.ordemTotal,
  });

  final TreinosDestaque destaque;
  final DateTime hoje;

  /// Inicia, continua ou faz mais um (o verbo da linha).
  final VoidCallback onAction;

  /// Abre a prévia ou o detalhe; é o toque quando o estado não tem verbo.
  final VoidCallback? onOpen;
  final String? proximoNome;
  final int? ordem;
  final int? ordemTotal;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final texto = treinosDestaqueTexto(
      s,
      destaque,
      hoje: hoje,
      proximoNome: proximoNome,
      ordem: ordem,
      ordemTotal: ordemTotal,
      proximoEhDescanso: destaque.proximoEhDescanso,
    );
    final cta = texto.cta;
    final concluido = destaque.tipo == TreinosDestaqueTipo.concluidoHoje;
    return FxActionRow(
      leading: concluido
          ? Icons.check_circle_outline_rounded
          : Icons.fitness_center,
      titulo: texto.titulo,
      motivo: [
        texto.eyebrow,
        texto.detalhe,
        if (texto.prazo != null) texto.prazo!,
      ].join(' · '),
      verbo: cta ?? s.treinosHojeVerboVer,
      onTap: cta != null ? onAction : (onOpen ?? () {}),
    );
  }
}
