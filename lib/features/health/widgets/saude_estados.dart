import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_sticky_actions.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../utils/health_plausibilidade.dart';
import '../utils/saude_meta_passos.dart';

/// Estado desconectado: o que lemos, o que não fazemos e a ação de conectar.
class SaudeDesconectadoView extends StatelessWidget {
  const SaudeDesconectadoView({
    super.key,
    required this.onConectar,
    required this.onAtualizar,
  });

  final VoidCallback onConectar;
  final Future<void> Function() onAtualizar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final fonte = rotuloPlataformaSaude();
    Widget linha(IconData icone, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.14),
            ),
            child: Icon(icone, size: 20, color: chrome.ink),
          ),
          const SizedBox(width: TokensStrip.s3),
          Expanded(
            child: Text(
              texto,
              style: FocuxHubTypography.body(
                color: chrome.ink,
              ).copyWith(fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );

    // O botão fica preso embaixo, na zona do polegar (antes ficava no meio).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onAtualizar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TokensStrip.s5),
              children: [
                const SizedBox(height: TokensStrip.s5),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 40,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s4),
                Text(
                  'Conecte para ver sua prontidão',
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.body(color: chrome.ink).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: TokensStrip.s5),
                linha(
                  Icons.bedtime_outlined,
                  'Lemos seu sono, batimentos e passos',
                ),
                linha(
                  Icons.lock_outline_rounded,
                  'Não escrevemos nada no $fonte',
                ),
                linha(
                  Icons.visibility_outlined,
                  'Você escolhe se seu personal vê seus dados',
                ),
              ],
            ),
          ),
        ),
        FxStickyActions(primaryLabel: 'Conectar $fonte', onPrimary: onConectar),
      ],
    );
  }
}

/// Esqueleto no molde da tela (card grande, quatro cartões e a tendência).
class SaudeSkeleton extends StatelessWidget {
  const SaudeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bloco(double altura) =>
        FxLoading.sectionShimmer(context, height: altura, showHeader: false);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        bloco(232),
        const SizedBox(height: TokensStrip.s3),
        Row(
          children: [
            Expanded(child: bloco(132)),
            const SizedBox(width: TokensStrip.s2),
            Expanded(child: bloco(132)),
          ],
        ),
        const SizedBox(height: TokensStrip.s2),
        Row(
          children: [
            Expanded(child: bloco(132)),
            const SizedBox(width: TokensStrip.s2),
            Expanded(child: bloco(132)),
          ],
        ),
        const SizedBox(height: TokensStrip.s3),
        bloco(170),
      ],
    );
  }
}

/// Folha "Meta diária" de passos (4.000 a 20.000, de 500 em 500).
Future<int?> showSaudeMetaPassosSheet(
  BuildContext context, {
  required int atual,
}) {
  return showFxHomeSheet<int>(
    context,
    builder: (_) => _MetaPassosSheet(atual: atual),
  );
}

class _MetaPassosSheet extends StatefulWidget {
  const _MetaPassosSheet({required this.atual});

  final int atual;

  @override
  State<_MetaPassosSheet> createState() => _MetaPassosSheetState();
}

class _MetaPassosSheetState extends State<_MetaPassosSheet> {
  late int _valor = SaudeMetaPassos.ajustar(widget.atual);

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return FxSheetFrame(
      title: 'Meta diária',
      subtitle: 'Quantos passos por dia você quer buscar.',
      leading: Icon(Icons.directions_walk_rounded, color: primary, size: 20),
      footer: FxLiquidPrimaryButton(
        label: 'Salvar meta',
        onPressed: () => FxHomeSheetChrome.dismissAndPop(context, _valor),
      ),
      child: Column(
        children: [
          Text(
            milhar(_valor),
            style: TextStyle(
              color: chrome.ink,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Slider(
            value: _valor.toDouble(),
            min: SaudeMetaPassos.minimo.toDouble(),
            max: SaudeMetaPassos.maximo.toDouble(),
            divisions:
                (SaudeMetaPassos.maximo - SaudeMetaPassos.minimo) ~/
                SaudeMetaPassos.passo,
            label: milhar(_valor),
            onChanged:
                (v) =>
                    setState(() => _valor = SaudeMetaPassos.ajustar(v.round())),
          ),
        ],
      ),
    );
  }
}
