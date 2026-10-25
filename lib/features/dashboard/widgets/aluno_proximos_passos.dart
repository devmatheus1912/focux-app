import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/fx_on_visible.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_home_texts.dart';
import '../utils/aluno_pendencias.dart';
import 'dashboard_section_header.dart';

/// Até [alunoPendenciasMax] passos, cada um com um verbo. O que passa disso
/// vira "Ver mais (N)". Lista vazia → nada.
class AlunoProximosPassos extends StatefulWidget {
  const AlunoProximosPassos({
    super.key,
    required this.pendencias,
    required this.hoje,
    required this.onTap,
    this.resto = 0,
    this.onVerMais,
    this.onShown,
  });

  final List<AlunoPendencia> pendencias;

  /// Quantas ainda estão abertas além das visíveis.
  final int resto;
  final VoidCallback? onVerMais;

  /// Mesmo relógio do build da Home (textos "hoje", "amanhã").
  final DateTime hoje;
  final ValueChanged<AlunoPendencia> onTap;

  /// Chamado para cada passo quando o bloco aparece e a cada lista nova
  /// enquanto ele está visível (quem ouve deduplica).
  final ValueChanged<AlunoPendencia>? onShown;

  @override
  State<AlunoProximosPassos> createState() => _AlunoProximosPassosState();
}

class _AlunoProximosPassosState extends State<AlunoProximosPassos> {
  var _visto = false;

  @override
  void didUpdateWidget(covariant AlunoProximosPassos oldWidget) {
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
    final verMais = widget.resto > 0 && widget.onVerMais != null;

    return FxOnVisible(
      onVisible: _onVisible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: s.alunoProximosPassosTitulo,
            actionLabel: verMais
                ? s.alunoProximosPassosVerMais(widget.resto)
                : null,
            onAction: verMais ? widget.onVerMais : null,
          ),
          const SizedBox(height: TokensStrip.s2),
          for (final (i, p) in widget.pendencias.indexed) ...[
            if (i > 0) const SizedBox(height: TokensStrip.s2),
            AlunoPassoRow(
              pendencia: p,
              hoje: widget.hoje,
              onTap: () => widget.onTap(p),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma linha de passo: ícone, título, motivo e verbo.
class AlunoPassoRow extends StatelessWidget {
  const AlunoPassoRow({
    super.key,
    required this.pendencia,
    required this.hoje,
    required this.onTap,
  });

  final AlunoPendencia pendencia;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final texto = alunoPendenciaTexto(s, pendencia, hoje: hoje);
    return FxActionRow(
      leading: _icone(pendencia.tipo),
      titulo: texto.titulo,
      motivo: texto.detalhe,
      verbo: alunoPendenciaVerbo(s, pendencia),
      onTap: onTap,
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
