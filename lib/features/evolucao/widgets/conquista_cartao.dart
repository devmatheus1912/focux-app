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

  /// Áreas que o Instagram cobre no story (na imagem de 1080 × 1920):
  /// 250 px em cima (perfil e progresso) e 340 px embaixo (resposta).
  static const livreTopo = 250 / escala;
  static const livreBase = 340 / escala;

  @override
  Widget build(BuildContext context) {
    final marcaCor = Theme.of(context).colorScheme.primary;
    final cores = conquistaSeloCores(marcaCor);
    const tinta = Colors.white;
    final apagada = Colors.white.withValues(alpha: 0.72);
    final c = conquista;
    final logo = marca?.logoUrl;
    final nome = marca?.nome?.trim();
    final temMarcaPropria =
        (logo != null && logo.isNotEmpty) || (nome != null && nome.isNotEmpty);
    return SizedBox(
      width: largura,
      height: altura,
      // Fundo fixo escuro da marca, igual em qualquer aparelho e tema.
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cores.miolo, Color.lerp(cores.miolo, Colors.black, 0.45)!],
          ),
        ),
        child: Stack(
          children: [
            // Brilho radial da cor da marca atrás do selo.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.12),
                    radius: 0.7,
                    colors: [
                      marcaCor.withValues(alpha: 0.42),
                      marcaCor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, livreTopo, 28, livreBase),
              child: Column(
                children: [
                  const Spacer(),
                  if (animar)
                    ConquistaSeloAnimado(
                      tipo: c.tipo,
                      glifo: conquistaGlifo(c),
                      tamanho: 220,
                    )
                  else
                    ConquistaSelo(
                      tipo: c.tipo,
                      glifo: conquistaGlifo(c),
                      tamanho: 220,
                    ),
                  const SizedBox(height: TokensStrip.s5),
                  Text(
                    c.tipoRotulo.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.chip(apagada).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  if (mostrarValor)
                    _Numero(texto: c.valor, cor: tinta, tamanho: TokensStrip.fontNumeroTela)
                  else
                    Text(
                      c.titulo == c.valor ? c.tipoRotulo : c.titulo,
                      textAlign: TextAlign.center,
                      style: FocuxHubTypography.sectionTitle(context, color: tinta),
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
                  // Assinatura embaixo, acima da área livre.
                  SizedBox(
                    height: 32,
                    child:
                        logo != null && logo.isNotEmpty
                            ? FocuxOfficialLogo(height: 32, logoUrl: logo)
                            : nome != null && nome.isNotEmpty
                            ? Center(
                              child: Text(
                                nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FocuxHubTypography.cardTitle(color: tinta),
                              ),
                            )
                            : const FocuxOfficialLogo(height: 24),
                  ),
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    temMarcaPropria
                        ? dataPorExtenso(c.data)
                        : '${dataPorExtenso(c.data)} · Focux',
                    style: FocuxHubTypography.chip(apagada),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Número da conquista (embaixo do selo); encolhe para caber numa linha.
class _Numero extends StatelessWidget {
  const _Numero({
    required this.texto,
    required this.cor,
    this.tamanho = TokensStrip.fontDestaque,
  });

  final String texto;
  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      texto,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: FocuxHubTypography.metric(color: cor, fontSize: tamanho),
    ),
  );
}

/// Número da folha de celebração, embaixo do selo.
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
