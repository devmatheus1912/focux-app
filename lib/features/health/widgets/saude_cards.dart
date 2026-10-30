import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../data/health_repository.dart';
import '../utils/health_plausibilidade.dart';

/// Cartão de métrica do dia: ícone em círculo tonal, valor grande, unidade
/// menor e, quando há meta, uma barra fina de progresso. Sem cores de alarme.
class SaudeMetricTile extends StatelessWidget {
  const SaudeMetricTile({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.unidade,
    this.apoio,
    this.progresso,
    this.onTap,
    this.acao = false,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final String? unidade;
  final String? apoio;

  /// 0 a 1; null = sem barra.
  final double? progresso;
  final VoidCallback? onTap;

  /// Cartão vazio que vira chamada ("Registrar sono").
  final bool acao;

  /// Sem dado ("--" ou cartão de chamada): texto pequeno e apagado, nunca em
  /// tamanho de número (antes "Registrar sono" grande parecia botão).
  bool get _vazio => acao || valor.trim().isEmpty || valor.trim() == '--';

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final texto = _vazio ? 'Sem registro' : valor;
    return Semantics(
      container: true,
      button: onTap != null,
      label: [
        rotulo,
        texto + (unidade == null || _vazio ? '' : ' $unidade'),
        if (apoio != null) apoio!,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: chrome.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: chrome.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.14),
                      ),
                      child: Icon(icone, size: 18, color: chrome.ink),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rotulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chrome.mute,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: chrome.mute,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: texto,
                      style: TextStyle(
                        color: _vazio ? chrome.mute : chrome.ink,
                        fontSize: _vazio ? 16 : 28,
                        fontWeight: _vazio ? FontWeight.w600 : FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      children: [
                        if (unidade != null && !_vazio)
                          TextSpan(
                            text: ' $unidade',
                            style: TextStyle(
                              color: chrome.mute,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
                if (progresso != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progresso!.clamp(0.0, 1.0),
                      minHeight: 5,
                      color: primary,
                      backgroundColor: primary.withValues(alpha: 0.14),
                    ),
                  ),
                ],
                if (apoio != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    apoio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chrome.mute,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Últimos 7 dias de nota, em barras. Tocar numa barra descreve o dia.
class ProntidaoTendencia extends StatefulWidget {
  const ProntidaoTendencia({super.key, required this.dias});

  final List<RecoveryDia> dias;

  /// Com menos de 3 dias de nota o gráfico não faz sentido.
  static const minimoDeDias = 3;

  static int diasComNota(List<RecoveryDia> dias) =>
      dias.where((d) => d.score != null).length;

  @override
  State<ProntidaoTendencia> createState() => _ProntidaoTendenciaState();
}

class _ProntidaoTendenciaState extends State<ProntidaoTendencia> {
  int? _selecionado;

  static const _letras = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  static const _nomes = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final dias = widget.dias;
    final comNota = ProntidaoTendencia.diasComNota(dias);

    // Sem nota nenhuma, a seção não aparece; com 1 ou 2, uma linha sem cartão.
    if (comNota == 0) return const SizedBox.shrink();
    if (comNota < ProntidaoTendencia.minimoDeDias) {
      return Text(
        'Sua tendência aparece com 3 dias de nota.',
        style: TextStyle(color: chrome.mute, fontSize: 14),
      );
    }
    Widget corpo;
    {
      final sel = _selecionado;
      corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < dias.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: _descricao(dias[i]),
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _selecionado = i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration:
                                  TokensStrip.prefersReducedMotion(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 300),
                              width: 22,
                              height: dias[i].score == null
                                  ? 6
                                  : 8 + dias[i].score! * 0.66,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color:
                                    dias[i].score == null
                                        ? chrome.line
                                        : (i == dias.length - 1 || i == sel)
                                        ? primary
                                        : primary.withValues(alpha: 0.42),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _letras[(dias[i].data.weekday - 1) % 7],
                              style: TextStyle(
                                color:
                                    i == dias.length - 1
                                        ? chrome.ink
                                        : chrome.mute,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (sel != null) ...[
            const SizedBox(height: 8),
            Text(
              _descricao(dias[sel]),
              style: TextStyle(
                color: chrome.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      );
    }

    return _CartaoDeSecao(titulo: 'Últimos 7 dias', filho: corpo);
  }

  String _descricao(RecoveryDia d) {
    final dia = _nomes[(d.data.weekday - 1) % 7];
    if (d.score == null) return '$dia · sem nota';
    return '$dia · ${d.score}${d.rotulo == null ? '' : ' · ${d.rotulo}'}';
  }
}

/// Casca dos cartões de seção (tendência, conexão).
class _CartaoDeSecao extends StatelessWidget {
  const _CartaoDeSecao({required this.titulo, required this.filho});

  final String titulo;
  final Widget filho;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chrome.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chrome.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          filho,
        ],
      ),
    );
  }
}

/// Conexão com o app Saúde / Health Connect e o interruptor de compartilhamento.
class SaudeConexaoCard extends StatelessWidget {
  const SaudeConexaoCard({
    super.key,
    required this.rotuloFonte,
    required this.sincronizado,
    required this.compartilhando,
    required this.onCompartilhar,
    required this.onGerenciar,
  });

  /// "Apple Saúde" ou "Health Connect".
  final String rotuloFonte;

  /// "Sincronizado às 13:50 · Apple Watch".
  final String sincronizado;
  final bool? compartilhando;
  final ValueChanged<bool> onCompartilhar;
  final VoidCallback onGerenciar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return _CartaoDeSecao(
      titulo: 'Conexão',
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.14),
                ),
                child: Icon(Icons.favorite_rounded, size: 20, color: chrome.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rotuloFonte,
                      style: TextStyle(
                        color: chrome.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Selo abaixo do nome: não quebra a linha do título.
                    const FxStatusPill(label: 'Conectada', tone: FxPillTone.success),
                    const SizedBox(height: 4),
                    Text(
                      sincronizado,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: chrome.mute, fontSize: 13),
                    ),
                  ],
                ),
              ),
              FxTonalButton(
                label: 'Gerenciar',
                compact: true,
                onPressed: onGerenciar,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: chrome.line),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartilhar com meu personal',
                      style: TextStyle(
                        color: chrome.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      compartilhando == true
                          ? 'Seu personal vê sua nota de prontidão e os dados do dia.'
                          : 'Só você vê seus dados de saúde.',
                      style: TextStyle(
                        color: chrome.mute,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Compartilhar saúde com meu personal',
                child: Switch.adaptive(
                  // Na cor da marca, não no verde do sistema.
                  activeTrackColor: primary,
                  value: compartilhando ?? false,
                  onChanged: compartilhando == null ? null : onCompartilhar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Folha "Como chegamos nessa nota".
Future<void> showProntidaoInsumosSheet(
  BuildContext context, {
  required RecoverySnapshot recovery,
}) {
  return showFxHelpSheet(
    context,
    title: 'Como chegamos nessa nota',
    subtitle:
        'Sono, FC em repouso e HRV, sempre comparados com a sua média.',
    tips: [
      for (final i in insumosDaNota(recovery)) FxHelpTip(i.titulo, i.detalhe),
    ],
  );
}
