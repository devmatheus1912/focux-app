import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../l10n/pt.dart';
import '../data/meta_corporal.dart';
import 'conquista_selo.dart';

/// Marca de quem compartilha: logo do personal, ou o nome, ou a do Focux.
typedef MarcaDoCartao = ({String? logoUrl, String? nome});

/// Cartão de story (9:16), um pôster de resultado: o número enorme, o que foi,
/// o salto ("+10 kg desde 11 out"), quem fez e com quem treina. Desenhado em
/// 360 × 640 e exportado ×3 = 1080 × 1920. Fundo na cor da marca ou numa foto
/// do aluno ([foto], que não sai do aparelho). Sem [mostrarValor], sai sem
/// número nem contexto (peso é dado de saúde).
class ConquistaCartao extends StatelessWidget {
  const ConquistaCartao({
    super.key,
    required this.conquista,
    required this.mostrarValor,
    this.marca,
    this.animar = false,
    this.aluno,
    this.instagram,
    this.foto,
  });

  /// Celebração: o anel se desenha uma vez.
  final bool animar;

  static const largura = 360.0;
  static const altura = 640.0;
  static const escala = 3.0;

  final Conquista conquista;
  final bool mostrarValor;
  final MarcaDoCartao? marca;

  /// Primeiro nome do aluno ("Julio treina com").
  final String? aluno;

  /// @ do Instagram do personal, quando houver.
  final String? instagram;

  /// Fundo com a foto do aluno; nulo = cor da marca.
  final Uint8List? foto;

  /// Áreas que o Instagram cobre no story (na imagem de 1080 × 1920):
  /// 250 px em cima (perfil e progresso) e 340 px embaixo (resposta).
  static const livreTopo = 250 / escala;
  static const livreBase = 340 / escala;

  @override
  Widget build(BuildContext context) {
    final marcaCor = Theme.of(context).colorScheme.primary;
    final cores = conquistaSeloCores(marcaCor);
    // Fundo da cor da marca: marca clara pede texto escuro.
    final clara = foto == null && marcaCor.computeLuminance() > 0.5;
    final tinta = clara ? Colors.black.withValues(alpha: 0.87) : Colors.white;
    final apagada = tinta.withValues(alpha: 0.78);
    final destaque =
        clara ? Color.lerp(marcaCor, Colors.black, 0.55)! : cores.glifo;
    final c = conquista;
    return SizedBox(
      width: largura,
      height: altura,
      child: Stack(
        children: [
          Positioned.fill(child: _Fundo(cor: marcaCor, foto: foto)),
          // Positioned.fill: a coluna ocupa a largura toda e centraliza. Antes
          // ela ficava da largura do selo, encostada à esquerda (bug de 13/11).
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, livreTopo, 28, livreBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (animar)
                        ConquistaSeloAnimado(
                          tipo: c.tipo,
                          glifo: conquistaGlifo(c),
                          tamanho: 44,
                        )
                      else
                        ConquistaSelo(
                          tipo: c.tipo,
                          glifo: conquistaGlifo(c),
                          tamanho: 44,
                        ),
                      const SizedBox(width: TokensStrip.s2),
                      Text(
                        c.tipoRotulo.toUpperCase(),
                        style: FocuxHubTypography.chip(
                          apagada,
                        ).copyWith(letterSpacing: 2),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (mostrarValor) ...[
                    _Poster(texto: c.valor, cor: tinta),
                    const SizedBox(height: TokensStrip.s2),
                    Text(
                      c.item,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.sectionTitle(context, color: tinta),
                    ),
                    if (c.contexto case final contexto?) ...[
                      const SizedBox(height: TokensStrip.s3),
                      // Selo do salto: contraste da tinta sobre um fundo leve,
                      // legível na cor da marca e na foto.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TokensStrip.s3,
                          vertical: TokensStrip.s1 + 2,
                        ),
                        decoration: BoxDecoration(
                          color: destaque.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          contexto,
                          textAlign: TextAlign.center,
                          style: FocuxHubTypography.cardTitle(color: tinta),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Sem o número: o tipo em destaque e o item embaixo, em
                    // duas linhas (sem "no"/"na", que errava o gênero).
                    Text(
                      c.tipoRotulo,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: FocuxHubTypography.destaque(color: tinta),
                    ),
                    // Sem exercício nem medida, o item seria o próprio tipo.
                    if (c.item != c.tipoRotulo) ...[
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        c.item,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.sectionTitle(context, color: tinta),
                      ),
                    ],
                  ],
                  const Spacer(),
                  _Assinatura(
                    marca: marca,
                    aluno: aluno,
                    instagram: instagram,
                    tinta: tinta,
                    apagada: apagada,
                  ),
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    dataDiaMesAno(c.data),
                    style: FocuxHubTypography.chip(apagada),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cor da marca em degradê com o hexágono do selo enorme e vazado ao fundo,
/// ou a foto do aluno com um véu escuro para o texto ler.
class _Fundo extends StatelessWidget {
  const _Fundo({required this.cor, this.foto});

  final Color cor;
  final Uint8List? foto;

  @override
  Widget build(BuildContext context) {
    if (foto case final foto?) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(foto, fit: BoxFit.cover, gaplessPlayback: true),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.3, 0.55, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final escuro = Color.lerp(cor, Colors.black, 0.55)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cor, escuro],
        ),
      ),
      child: CustomPaint(painter: _HexagonoVazado(Colors.white.withValues(alpha: 0.07))),
    );
  }
}

/// Hexágono do selo, grande e vazado, cortado pela borda direita.
class _HexagonoVazado extends CustomPainter {
  _HexagonoVazado(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final raio = size.width * 0.62;
    final centro = Offset(size.width * 0.82, size.height * 0.52);
    final caminho = Path();
    for (var i = 0; i < 6; i++) {
      final ang = (60 * i - 90) * math.pi / 180;
      final p = centro + Offset(raio * math.cos(ang), raio * math.sin(ang));
      if (i == 0) {
        caminho.moveTo(p.dx, p.dy);
      } else {
        caminho.lineTo(p.dx, p.dy);
      }
    }
    caminho.close();
    canvas.drawPath(
      caminho,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeJoin = StrokeJoin.round
        ..color = cor,
    );
  }

  @override
  bool shouldRepaint(_HexagonoVazado old) => old.cor != cor;
}

/// O número em tamanho de pôster: "20,0" grande e a unidade menor, na mesma
/// linha de base. Escala com FittedBox até ~80% da largura (sem tamanho de
/// fonte fora da escala do app).
class _Poster extends StatelessWidget {
  const _Poster({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final partes = texto.trim().split(RegExp(r'\s+'));
    final numero = partes.first;
    final unidade = partes.length > 1 ? partes.sublist(1).join(' ') : null;
    return SizedBox(
      width: ConquistaCartao.largura * 0.8,
      height: 150,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              numero,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: FocuxHubTypography.numeroTela(color: cor, height: 1),
            ),
            if (unidade != null) ...[
              const SizedBox(width: 3),
              Text(
                unidade,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: FocuxHubTypography.cardTitle(color: cor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Julio treina com" + logo em círculo + nome e @ do personal. Sem marca
/// própria, a do Focux.
class _Assinatura extends StatelessWidget {
  const _Assinatura({
    required this.marca,
    required this.aluno,
    required this.instagram,
    required this.tinta,
    required this.apagada,
  });

  final MarcaDoCartao? marca;
  final String? aluno;
  final String? instagram;
  final Color tinta;
  final Color apagada;

  @override
  Widget build(BuildContext context) {
    final logo = marca?.logoUrl;
    final nome = marca?.nome?.trim();
    final temLogo = logo != null && logo.isNotEmpty;
    final temNome = nome != null && nome.isNotEmpty;
    final arroba = instagram?.trim().replaceFirst('@', '');
    return Column(
      children: [
        if (aluno case final aluno? when aluno.trim().isNotEmpty)
          Text(
            ptS.conquistaTreinaCom(aluno.trim()),
            style: FocuxHubTypography.chip(apagada),
          ),
        const SizedBox(height: TokensStrip.s1),
        if (!temLogo && !temNome)
          const FocuxOfficialLogo(height: 24)
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (temLogo) ...[
                // Círculo branco: logo com fundo próprio não vira quadrado.
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(child: FocuxOfficialLogo(height: 30, logoUrl: logo)),
                ),
                const SizedBox(width: TokensStrip.s2),
              ],
              Flexible(
                child: Column(
                  // Sem logo, nome e @ centralizados com o resto.
                  crossAxisAlignment:
                      temLogo ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (temNome)
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.cardTitle(color: tinta),
                      ),
                    if (arroba != null && arroba.isNotEmpty)
                      Text(
                        '@$arroba',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.chip(apagada),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Número da folha de celebração, embaixo do selo; encolhe para caber.
Widget conquistaNumero(String texto, Color cor) => FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    texto,
    maxLines: 1,
    textScaler: TextScaler.noScaling,
    style: FocuxHubTypography.metric(color: cor, fontSize: TokensStrip.fontDestaque),
  ),
);

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
