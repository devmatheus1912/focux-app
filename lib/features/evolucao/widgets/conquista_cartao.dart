import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../data/meta_corporal.dart';
import 'conquista_selo.dart';

/// Marca de quem compartilha: logo do personal, ou o nome, ou a do Focux.
typedef MarcaDoCartao = ({String? logoUrl, String? nome});

/// Cartão de story (9:16). Desenhado em 360 × 640 e exportado ×3 = 1080 × 1920.
/// Sem [mostrarValor], sai sem número e sem detalhe (peso é dado de saúde).
class ConquistaCartao extends StatelessWidget {
  const ConquistaCartao({
    super.key,
    required this.conquista,
    required this.mostrarValor,
    this.marca,
    this.animar = false,
  });

  /// Celebração: o anel se desenha uma vez.
  final bool animar;

  static const largura = 360.0;
  static const altura = 640.0;
  static const escala = 3.0;

  final Conquista conquista;
  final bool mostrarValor;
  final MarcaDoCartao? marca;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tinta = scheme.onSurface;
    final apagada = scheme.onSurfaceVariant;
    final c = conquista;
    final logo = marca?.logoUrl;
    final nome = marca?.nome?.trim();
    return SizedBox(
      width: largura,
      height: altura,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Véu da marca só no topo, já misturado ao fundo: cor translúcida
          // deixava vazar o que estivesse atrás da imagem.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Color.alphaBlend(scheme.primary.withValues(alpha: 0.06), scheme.surface),
              scheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 56, 32, 40),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child:
                    logo != null && logo.isNotEmpty
                        ? FocuxOfficialLogo(height: 40, logoUrl: logo)
                        : nome != null && nome.isNotEmpty
                        ? Center(
                          child: Text(
                            nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.cardTitle(color: tinta),
                          ),
                        )
                        : const FocuxOfficialLogo(height: 32),
              ),
              const Spacer(),
              if (animar && mostrarValor)
                ConquistaSeloAnimado(
                  tipo: c.tipo,
                  tamanho: 187,
                  miolo: _Numero(texto: c.valor, cor: tinta),
                )
              else
                ConquistaSelo(
                  tipo: c.tipo,
                  tamanho: 187,
                  miolo: mostrarValor ? _Numero(texto: c.valor, cor: tinta) : null,
                ),
              const SizedBox(height: TokensStrip.s5),
              Text(
                c.tipoRotulo,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.cardTitle(color: tinta).copyWith(fontSize: 22),
              ),
              if (mostrarValor) ...[
                const SizedBox(height: TokensStrip.s2),
                Text(
                  c.detalhe,
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.bodyMuted(color: apagada),
                ),
              ],
              const Spacer(),
              Text(
                dataPorExtenso(c.data),
                style: FocuxHubTypography.chip(apagada),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Número no centro do anel; encolhe para caber numa linha.
class _Numero extends StatelessWidget {
  const _Numero({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      texto,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: FocuxHubTypography.metric(color: cor, fontSize: 34),
    ),
  );
}

/// Número do selo da folha (fora do cartão).
Widget conquistaNumero(String texto, Color cor) => _Numero(texto: texto, cor: cor);

/// Exporta o [RepaintBoundary] do cartão em PNG 1080 × 1920 e abre o
/// compartilhamento do sistema.
Future<void> compartilharCartao(GlobalKey chave) async {
  final limite = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final imagem = await limite.toImage(pixelRatio: ConquistaCartao.escala);
  final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
  final pasta = await getTemporaryDirectory();
  final arquivo = File('${pasta.path}/conquista.png');
  await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
  await SharePlus.instance.share(ShareParams(files: [XFile(arquivo.path)]));
}
