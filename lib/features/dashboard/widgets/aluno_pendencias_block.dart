import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_on_visible.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_home_texts.dart';
import '../utils/aluno_pendencias.dart';
import 'dashboard_section_header.dart';

/// Até 3 próximos passos; lista vazia → nada.
class AlunoPendenciasBlock extends StatefulWidget {
  const AlunoPendenciasBlock({
    super.key,
    required this.pendencias,
    required this.hoje,
    required this.onTap,
    this.onShown,
  });

  final List<AlunoPendencia> pendencias;

  /// Mesmo relógio do build da Home (textos "hoje", "amanhã").
  final DateTime hoje;
  final ValueChanged<AlunoPendencia> onTap;

  /// Chamado para cada item quando o bloco aparece na tela e a cada lista nova
  /// enquanto ele está visível (quem ouve deduplica).
  final ValueChanged<AlunoPendencia>? onShown;

  @override
  State<AlunoPendenciasBlock> createState() => _AlunoPendenciasBlockState();
}

class _AlunoPendenciasBlockState extends State<AlunoPendenciasBlock> {
  var _visto = false;

  @override
  void didUpdateWidget(covariant AlunoPendenciasBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visto) _notifyShown();
  }

  void _onVisible() {
    _visto = true;
    _notifyShown();
  }

  void _notifyShown() {
    final onShown = widget.onShown;
    if (onShown == null) return;
    widget.pendencias.forEach(onShown);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendencias.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return FxOnVisible(
      onVisible: _onVisible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: s.alunoPendenciasTitulo),
          const SizedBox(height: TokensStrip.s2),
          Container(
            padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
            decoration: fxListCardDecoration(context, accent: primary),
            child: Column(
              children: [
                for (final p in widget.pendencias)
                  _PendenciaRow(
                    pendencia: p,
                    hoje: widget.hoje,
                    onTap: () => widget.onTap(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendenciaRow extends StatelessWidget {
  const _PendenciaRow({
    required this.pendencia,
    required this.hoje,
    required this.onTap,
  });

  final AlunoPendencia pendencia;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = alunoPendenciaTexto(S.of(context), pendencia, hoje: hoje);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '${texto.titulo}. ${texto.detalhe}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s3,
              vertical: TokensStrip.s2,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(primary, dark: isDark),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icone(pendencia.tipo), size: 18, color: primary),
                ),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        texto.titulo,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        texto.detalhe,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: chrome.mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _icone(AlunoPendenciaTipo tipo) => switch (tipo) {
  AlunoPendenciaTipo.perfil => Icons.person_outline,
  AlunoPendenciaTipo.foto => Icons.add_a_photo_outlined,
  AlunoPendenciaTipo.medida => Icons.straighten_outlined,
  AlunoPendenciaTipo.chat => Icons.chat_bubble_outline,
  AlunoPendenciaTipo.agenda => Icons.calendar_month_outlined,
};
