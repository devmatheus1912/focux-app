import 'package:flutter/material.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/historico_fichas.dart';

/// Loading do histórico: cabeçalho de semana e quatro linhas.
class HistoricoSkeleton extends StatelessWidget {
  const HistoricoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: S.of(context).historicoCarregando,
      excludeSemantics: true,
      child: const FxContentWidthLimiter(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonLoader(width: 160, height: 16),
              SizedBox(height: TokensStrip.s2),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Todos" + uma chip por ficha; `null` = todas.
class HistoricoFiltroFichas extends StatelessWidget {
  const HistoricoFiltroFichas({
    super.key,
    required this.fichas,
    required this.selecionado,
    required this.onSelect,
  });

  final List<HistoricoFicha> fichas;
  final int? selecionado;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = ShellChrome.of(context).isDark;
    Widget chip(String label, int? id) => Padding(
      padding: const EdgeInsets.only(right: TokensStrip.s2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: FxToggleChip(
          label: label,
          selected: selecionado == id,
          isDark: isDark,
          filledWhenSelected: true,
          onTap: () => onSelect(id),
        ),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        0,
      ),
      child: Row(
        children: [
          chip(s.historicoFiltroTodos, null),
          for (final f in fichas) chip(f.nome, f.treinoId),
        ],
      ),
    );
  }
}

/// Fim da lista com página seguinte. Ao aparecer, pede a página. Em erro,
/// oferece "Tentar de novo" sem perder o que já carregou.
class HistoricoMaisRodape extends StatefulWidget {
  const HistoricoMaisRodape({
    super.key,
    required this.erro,
    required this.onCarregar,
  });

  final bool erro;
  final VoidCallback onCarregar;

  @override
  State<HistoricoMaisRodape> createState() => _HistoricoMaisRodapeState();
}

class _HistoricoMaisRodapeState extends State<HistoricoMaisRodape> {
  @override
  void initState() {
    super.initState();
    if (!widget.erro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCarregar();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!widget.erro) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: s.historicoCarregandoMais,
        excludeSemantics: true,
        child: const SkeletonLoader(
          height: 56,
          borderRadius: TokensStrip.rCard,
        ),
      );
    }
    final chrome = ShellChrome.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            s.historicoMaisErro,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ),
        const SizedBox(width: TokensStrip.s2),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: widget.onCarregar,
          child: Text(s.historicoTentarDeNovo),
        ),
      ],
    );
  }
}
