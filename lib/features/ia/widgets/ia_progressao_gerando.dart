import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../models/progressao_sugestao.dart';
import '../utils/progressao_copy.dart';

/// Enquanto a IA gera: o pedido em uma linha, o progresso com uma frase que
/// muda com o tempo (sempre verdadeira) e a saída. Com [prontas], o ✓.
class IaProgressaoGerando extends StatefulWidget {
  const IaProgressaoGerando({
    super.key,
    required this.pedido,
    required this.contexto,
    this.prontas,
  });

  /// "Hipertrofia · Semana leve · “joelho”".
  final String pedido;
  final ProgressaoContextoResumo? contexto;

  /// Sugestões registradas: troca o círculo pelo ✓ antes da revisão abrir.
  final int? prontas;

  @override
  State<IaProgressaoGerando> createState() => _IaProgressaoGerandoState();
}

class _IaProgressaoGerandoState extends State<IaProgressaoGerando> {
  final _inicio = DateTime.now();
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final prontas = widget.prontas;
    final frase =
        prontas == null
            ? progressaoGerandoFrase(
              DateTime.now().difference(_inicio),
              widget.contexto,
            )
            : progressaoProntas(prontas);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.pedido,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
        const SizedBox(height: TokensStrip.s6),
        Center(
          child: SizedBox.square(
            dimension: 48,
            child:
                prontas == null
                    ? const FxLoading(size: 40)
                    : Icon(FxIcons.concluido, color: primary, size: 44),
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        Semantics(
          liveRegion: true,
          label: 'Gerando sugestões. $frase',
          excludeSemantics: true,
          child: Text(
            frase,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
        ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          progressaoPodeSair,
          textAlign: TextAlign.center,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
      ],
    );
  }
}
