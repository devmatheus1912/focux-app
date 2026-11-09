import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../utils/grupos_de_serie.dart';

/// Grupos de séries do exercício (aquecimento, ajuste e back-off) em volta das
/// válidas, que ficam nos controles da folha. Um grupo por linha; tocar abre o
/// grupo no mesmo lugar. Os botões dizem o que adicionam; "bloco" nunca aparece
/// (bloco é a parte da sessão).
class GruposDeSerieEditor extends StatefulWidget {
  const GruposDeSerieEditor({
    super.key,
    required this.antes,
    required this.depois,
    required this.resumoValidas,
    required this.sugerir,
    required this.onChanged,
    this.enabled = true,
    this.onVerValidas,
  });

  /// Toque em "Válidas": leva aos controles das válidas, no topo da folha.
  final VoidCallback? onVerValidas;

  final List<GrupoDeSeries> antes;
  final List<GrupoDeSeries> depois;

  /// "3 × 8-12 · 75 s": a linha das válidas, só para orientar a ordem.
  final String resumoValidas;
  final GrupoDeSeries Function(String papel) sugerir;
  final void Function(List<GrupoDeSeries> antes, List<GrupoDeSeries> depois) onChanged;
  final bool enabled;

  @override
  State<GruposDeSerieEditor> createState() => _GruposDeSerieEditorState();
}

class _GruposDeSerieEditorState extends State<GruposDeSerieEditor> {
  /// (lado, índice) do grupo aberto; null = todos fechados.
  (bool, int)? _aberto;

  void _adicionar(String papel) {
    HapticFeedback.selectionClick();
    final novo = widget.sugerir(papel);
    final antes = [...widget.antes];
    final depois = [...widget.depois];
    if (papel == PapelDaSerie.backoff) {
      depois.add(novo);
      _aberto = (false, depois.length - 1);
    } else {
      // Aquecimento antes do ajuste; ajuste logo antes das válidas.
      final pos = papel == PapelDaSerie.aquecimento
          ? antes.lastIndexWhere((g) => g.papel == PapelDaSerie.aquecimento) + 1
          : antes.length;
      antes.insert(pos, novo);
      _aberto = (true, pos);
    }
    widget.onChanged(antes, depois);
  }

  void _mudar(bool doLadoAntes, int i, GrupoDeSeries novo) {
    final antes = [...widget.antes];
    final depois = [...widget.depois];
    (doLadoAntes ? antes : depois)[i] = novo;
    widget.onChanged(antes, depois);
  }

  /// Troca o grupo com o vizinho do mesmo papel (dois ajustes, por exemplo).
  /// A ordem entre papéis é fixa: aquecimento, ajuste, válidas, back-off.
  void _mover(bool doLadoAntes, int i, int passo) {
    final antes = [...widget.antes];
    final depois = [...widget.depois];
    final lista = doLadoAntes ? antes : depois;
    final j = i + passo;
    if (j < 0 || j >= lista.length || lista[j].papel != lista[i].papel) return;
    HapticFeedback.selectionClick();
    final g = lista.removeAt(i);
    lista.insert(j, g);
    setState(() => _aberto = (doLadoAntes, j));
    widget.onChanged(antes, depois);
  }

  bool _temVizinho(bool lado, int i, int passo) {
    final lista = lado ? widget.antes : widget.depois;
    final j = i + passo;
    return j >= 0 && j < lista.length && lista[j].papel == lista[i].papel;
  }

  void _remover(bool doLadoAntes, int i) {
    HapticFeedback.selectionClick();
    final antes = [...widget.antes];
    final depois = [...widget.depois];
    (doLadoAntes ? antes : depois).removeAt(i);
    setState(() => _aberto = null);
    widget.onChanged(antes, depois);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    Widget linha(bool lado, int i, GrupoDeSeries g) => _LinhaDoGrupo(
      grupo: g,
      aberto: _aberto == (lado, i),
      enabled: widget.enabled,
      onAbrir: () => setState(
        () => _aberto = _aberto == (lado, i) ? null : (lado, i),
      ),
      onMudar: (novo) => _mudar(lado, i, novo),
      onRemover: () => _remover(lado, i),
      onSubir: _temVizinho(lado, i, -1) ? () => _mover(lado, i, -1) : null,
      onDescer: _temVizinho(lado, i, 1) ? () => _mover(lado, i, 1) : null,
    );
    final temGrupos = widget.antes.isNotEmpty || widget.depois.isNotEmpty;
    return FxSettingsGroup(
      header: 'Séries do exercício',
      children: [
        Padding(
          padding: const EdgeInsets.all(FxSettingsLayout.groupPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (temGrupos) ...[
                for (final (i, g) in widget.antes.indexed) linha(true, i, g),
                // As válidas são os controles de cima: tocar leva até eles.
                Semantics(
                  button: widget.onVerValidas != null,
                  label: 'Válidas, ${widget.resumoValidas}. Editar no topo',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: widget.onVerValidas,
                    borderRadius: BorderRadius.circular(TokensStrip.rSm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Válidas · ${widget.resumoValidas}',
                              style: FocuxHubTypography.cardTitle(
                                color: chrome.ink,
                              ),
                            ),
                          ),
                          if (widget.onVerValidas != null)
                            Icon(
                              FxIcons.chevronCima,
                              size: 20,
                              color: chrome.mute,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                for (final (i, g) in widget.depois.indexed) linha(false, i, g),
                const SizedBox(height: TokensStrip.s2),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                  child: Text(
                    'Aquecimento, ajuste e back-off no mesmo exercício.',
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final papel in const [
                    PapelDaSerie.aquecimento,
                    PapelDaSerie.ajuste,
                    PapelDaSerie.backoff,
                  ])
                    FxTonalButton(
                      label: '+ ${PapelDaSerie.rotulo(papel)}',
                      compact: true,
                      onPressed: widget.enabled ? () => _adicionar(papel) : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinhaDoGrupo extends StatelessWidget {
  const _LinhaDoGrupo({
    required this.grupo,
    required this.aberto,
    required this.enabled,
    required this.onAbrir,
    required this.onMudar,
    required this.onRemover,
    this.onSubir,
    this.onDescer,
  });

  /// Setas só quando há outro grupo do mesmo papel ao lado.
  final VoidCallback? onSubir;
  final VoidCallback? onDescer;

  final GrupoDeSeries grupo;
  final bool aberto;
  final bool enabled;
  final VoidCallback onAbrir;
  final ValueChanged<GrupoDeSeries> onMudar;
  final VoidCallback onRemover;

  static const _reps = ['15-20', '10-15', '8-12', '6-10', '4-6', '1-3'];
  static const _descansos = [30, 45, 60, 90, 120, 150];

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final g = grupo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: aberto,
          label: grupoLinha(g),
          excludeSemantics: true,
          child: InkWell(
            onTap: enabled ? onAbrir : null,
            borderRadius: BorderRadius.circular(TokensStrip.rSm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      grupoLinha(g),
                      style: FocuxHubTypography.body(color: chrome.ink),
                    ),
                  ),
                  Icon(
                    aberto ? FxIcons.chevronCima : FxIcons.chevronBaixo,
                    size: 20,
                    color: chrome.mute,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (aberto)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Séries',
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Uma série a menos',
                      onPressed: enabled && g.series > 1
                          ? () => onMudar(g.copyWith(series: g.series - 1))
                          : null,
                      icon: const Icon(FxIcons.remover),
                    ),
                    Text('${g.series}', style: FocuxHubTypography.cardTitle(color: chrome.ink)),
                    IconButton(
                      tooltip: 'Uma série a mais',
                      onPressed: enabled && g.series < 10
                          ? () => onMudar(g.copyWith(series: g.series + 1))
                          : null,
                      icon: const Icon(FxIcons.adicionar),
                    ),
                  ],
                ),
                Text('Repetições', style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
                const SizedBox(height: TokensStrip.s1),
                FxQuickChips<String>(
                  itens: {..._reps, g.repeticoes}.toList(),
                  selecionado: g.repeticoes,
                  onSelecionar: (v) {
                    if (enabled) onMudar(g.copyWith(repeticoes: v));
                  },
                ),
                const SizedBox(height: TokensStrip.s2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        g.cargaKg == null ? 'Carga · sem carga' : 'Carga',
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Menos 2,5 kg',
                      onPressed: enabled && (g.cargaKg ?? 0) > 0
                          ? () {
                              final v = (g.cargaKg ?? 0) - 2.5;
                              onMudar(v <= 0
                                  ? g.copyWith(limparCarga: true)
                                  : g.copyWith(cargaKg: v));
                            }
                          : null,
                      icon: const Icon(FxIcons.remover),
                    ),
                    Text(
                      g.cargaKg == null ? '—' : '${_kg(g.cargaKg!)} kg',
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                    IconButton(
                      tooltip: 'Mais 2,5 kg',
                      onPressed: enabled
                          ? () => onMudar(g.copyWith(cargaKg: (g.cargaKg ?? 0) + 2.5))
                          : null,
                      icon: const Icon(FxIcons.adicionar),
                    ),
                  ],
                ),
                Text('Descanso', style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
                const SizedBox(height: TokensStrip.s1),
                FxQuickChips<int>(
                  itens: {
                    ..._descansos,
                    if (g.descansoSegundos != null) g.descansoSegundos!,
                  }.toList()..sort(),
                  selecionado: g.descansoSegundos,
                  rotuloDe: (v) => '$v s',
                  onSelecionar: (v) {
                    if (enabled) onMudar(g.copyWith(descansoSegundos: v));
                  },
                ),
                const SizedBox(height: TokensStrip.s1),
                if (onSubir != null || onDescer != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ordem',
                          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Subir',
                        onPressed: enabled ? onSubir : null,
                        icon: const Icon(FxIcons.chevronCima),
                      ),
                      IconButton(
                        tooltip: 'Descer',
                        onPressed: enabled ? onDescer : null,
                        icon: const Icon(FxIcons.chevronBaixo),
                      ),
                    ],
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FxActionLink(
                    label: 'Remover ${PapelDaSerie.rotulo(g.papel).toLowerCase()}',
                    destructive: true,
                    icon: FxIcons.excluir,
                    onTap: enabled ? onRemover : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _kg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.', ',');
}
