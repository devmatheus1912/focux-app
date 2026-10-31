import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/engajamento_display.dart';
import '../widgets/engajamento_atividade.dart';

/// Toda a atividade do período, de 20 em 20. A Aderência só mostra o recente.
class EngajamentoHistoricoScreen extends StatefulWidget {
  const EngajamentoHistoricoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    required this.eventos,
  });

  final int alunoId;
  final String alunoNome;
  final List<EventoEngajamento> eventos;

  @override
  State<EngajamentoHistoricoScreen> createState() =>
      _EngajamentoHistoricoScreenState();
}

class _EngajamentoHistoricoScreenState
    extends State<EngajamentoHistoricoScreen> {
  static const _pagina = 20;
  var _visiveis = _pagina;

  void _abrir(EventoEngajamento evento) {
    final rota = engajamentoEventoRota(evento.tipo, widget.alunoId);
    if (rota != null) context.push(rota, extra: widget.alunoNome);
  }

  @override
  Widget build(BuildContext context) {
    final dias = engajamentoPorDia(widget.eventos.take(_visiveis).toList());
    final temMais = _visiveis < widget.eventos.length;
    return fxScreenA11yScope(
      label: ptS.engajamentoHistoricoTitulo,
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: ptS.engajamentoHistoricoTitulo,
          subtitle: widget.alunoNome,
          onBack:
              () => safePopOrGo(context, '/alunos/${widget.alunoId}/engajamento'),
        ),
        body: FxContentWidthLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              0,
              FxSettingsLayout.pageInset,
              TokensStrip.s5,
            ),
            itemCount: dias.length + (temMais ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == dias.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: TokensStrip.s3),
                  child: FxTonalButton(
                    label: ptS.engajamentoVerMais,
                    expanded: true,
                    onPressed: () => setState(() => _visiveis += _pagina),
                  ),
                );
              }
              final (dia, eventos) = dias[i];
              return EngajamentoAtividadeDia(
                dia: dia,
                eventos: eventos,
                onEvento: _abrir,
                podeAbrir:
                    (e) =>
                        engajamentoEventoRota(e.tipo, widget.alunoId) != null,
              );
            },
          ),
        ),
      ),
    );
  }
}
